import Foundation
import UserNotifications
import AppKit

public final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    public static let shared = NotificationManager()
    
    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }
    
    public func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification authorization error: \(error)")
            }
        }
    }
    
    /// Script to bridge Web HTML5 Notification API to native macOS Notification Center
    public var notificationBridgeScript: String {
        """
        (function() {
            function handleNotify(title, options) {
                options = options || {};
                if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.notificationHandler) {
                    window.webkit.messageHandlers.notificationHandler.postMessage({
                        title: String(title || ''),
                        body: String(options.body || ''),
                        icon: String(options.icon || ''),
                        tag: String(options.tag || '')
                    });
                }
            }

            // Override Notification constructor & permission
            try {
                var CustomNotification = function(title, options) {
                    handleNotify(title, options);
                    this.title = title;
                    this.onclick = null;
                    this.onclose = null;
                    this.close = function() {};
                };
                
                CustomNotification.permission = "granted";
                CustomNotification.requestPermission = function(callback) {
                    if (typeof callback === 'function') callback("granted");
                    return Promise.resolve("granted");
                };
                
                window.Notification = CustomNotification;
                
                // Override ServiceWorker showNotification if present
                if (window.ServiceWorkerRegistration) {
                    window.ServiceWorkerRegistration.prototype.showNotification = function(title, options) {
                        handleNotify(title, options);
                        return Promise.resolve();
                    };
                }
            } catch(e) {
                console.error("WebBar Notification bridge error", e);
            }
        })();
        """
    }
    
    /// Script to automatically detect unread message badges in real-time from Zalo, Messenger, Facebook, Telegram, WhatsApp and title tags
    public var unreadBadgeDetectorScript: String {
        """
        (function() {
            var lastCount = -1;
            function scanBadges() {
                var count = 0;
                
                // 1. Zalo Web unread message badges
                var zaloBadges = document.querySelectorAll('.nav-tab__item--badge, .badge, [data-badge], .unread-red-dot, .chat-unread-count, .conv-item__badge, .zl-badge, .tab-item--badge');
                for (var i = 0; i < zaloBadges.length; i++) {
                    var el = zaloBadges[i];
                    if (el.offsetParent !== null) { // visible
                        var txt = el.innerText.trim();
                        var n = parseInt(txt);
                        if (!isNaN(n) && n > 0) {
                            count += n;
                        } else {
                            count += 1;
                        }
                    }
                }
                
                // 2. Facebook / Messenger / Instagram unread indicators
                var metaBadges = document.querySelectorAll('[aria-label*="unread"], [aria-label*="chưa đọc"], [aria-label*="Unread"], span[role="status"]');
                for (var j = 0; j < metaBadges.length; j++) {
                    var mEl = metaBadges[j];
                    if (mEl.offsetParent !== null) {
                        var t = mEl.innerText.trim();
                        var num = parseInt(t);
                        if (!isNaN(num) && num > 0) count += num;
                        else count += 1;
                    }
                }
                
                // 3. Document Title Badge Fallback: "(2) Zalo", "(1) Facebook", "[3] Messenger"
                var titleMatch = document.title.match(/[\\(\\[\\{](\\d+|\\+[\\d]+)[\\)\\]\\}]/);
                if (titleMatch) {
                    var titleNum = parseInt(titleMatch[1]);
                    if (!isNaN(titleNum) && titleNum > 0) {
                        count = Math.max(count, titleNum);
                    } else {
                        count = Math.max(count, 1);
                    }
                }
                
                if (count !== lastCount) {
                    lastCount = count;
                    if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.badgeHandler) {
                        window.webkit.messageHandlers.badgeHandler.postMessage({ count: count });
                    }
                }
            }
            
            try {
                var observer = new MutationObserver(scanBadges);
                if (document.head) {
                    observer.observe(document.head, { subtree: true, characterData: true, childList: true });
                }
                if (document.body) {
                    observer.observe(document.body, { subtree: true, childList: true, attributes: true });
                } else {
                    document.addEventListener('DOMContentLoaded', function() {
                        if (document.body) {
                            observer.observe(document.body, { subtree: true, childList: true, attributes: true });
                        }
                    });
                }
                setInterval(scanBadges, 2000);
                setTimeout(scanBadges, 1000);
            } catch(e) {}
        })();
        """
    }
    
    public func sendWebNotification(title: String, body: String, tabTitle: String, tabId: UUID) {
        let content = UNMutableNotificationContent()
        content.title = tabTitle.isEmpty ? "WebBar" : tabTitle
        if !title.isEmpty {
            content.subtitle = title
        }
        content.body = body.isEmpty ? "Bạn có tin nhắn / thông báo mới" : body
        content.sound = .default
        content.userInfo = ["tabId": tabId.uuidString]
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // Deliver immediately
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to deliver native notification: \(error)")
            }
        }
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    // Always display notification banner with sound even if app is focused
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }
    
    // When user clicks the macOS notification banner, focus tab and open window
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        if let tabIdStr = userInfo["tabId"] as? String, let tabId = UUID(uuidString: tabIdStr) {
            DispatchQueue.main.async {
                MenuBarController.shared.appState.selectTab(id: tabId)
                MenuBarController.shared.showPanel(for: tabId)
            }
        } else {
            DispatchQueue.main.async {
                MenuBarController.shared.showPanel()
            }
        }
        completionHandler()
    }
}
