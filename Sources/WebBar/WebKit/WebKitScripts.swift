import Foundation

public struct WebKitScripts {
    /// JavaScript snippet to pause all HTML5 audio/video playback and embedded iframe players
    public static let pauseAllMedia: String = """
    (function() {
        try {
            var media = document.querySelectorAll('video, audio');
            for (var i = 0; i < media.length; i++) {
                media[i].pause();
            }
            var iframes = document.querySelectorAll('iframe');
            for (var j = 0; j < iframes.length; j++) {
                if (iframes[j].contentWindow) {
                    iframes[j].contentWindow.postMessage('{"event":"command","func":"pauseVideo","args":""}', '*');
                }
            }
        } catch (e) {}
    })();
    """
    
    /// JavaScript snippet to extract page favicon URL from document DOM head
    public static let extractFavicon: String = """
    (function() {
        var el = document.querySelector("link[rel*='icon'], link[rel='apple-touch-icon'], link[rel='shortcut icon']");
        return el ? el.href : (window.location.origin + '/favicon.ico');
    })();
    """
    
    /// JavaScript security shim for Google OAuth compatibility
    public static let googleOAuthSecurityShim: String = """
    (function() {
        try {
            if (!window.chrome) {
                window.chrome = { runtime: {}, app: {}, csi: function(){}, loadTimes: function(){} };
            }
            Object.defineProperty(navigator, 'webdriver', { get: () => undefined });
        } catch(e) {}
    })();
    """
    
    /// JavaScript snippet to automatically activate single-tab session on Zalo Web
    public static let zaloAutoActivateScript: String = """
    (function() {
        function autoClickActivate() {
            try {
                // 1. Search for buttons containing text 'Kích hoạt' or 'Activate'
                var elements = document.querySelectorAll('button, div[role="button"], a, .btn, .btn-primary, [class*="btn"], [class*="Button"], [data-translate-inner]');
                for (var i = 0; i < elements.length; i++) {
                    var el = elements[i];
                    var text = (el.innerText || el.textContent || '').trim().toLowerCase();
                    if (text === 'kích hoạt' || text === 'kich hoat' || text === 'activate' || (text.indexOf('kích hoạt') !== -1 && text.length < 25)) {
                        el.click();
                        return true;
                    }
                }
                
                // 2. Search inside modal containers for Tab session conflict dialogs
                var modals = document.querySelectorAll('.modal, .popup, [class*="modal"], [class*="popup"], [class*="dialog"], [class*="layer"]');
                for (var m = 0; m < modals.length; m++) {
                    var modalText = (modals[m].innerText || '').toLowerCase();
                    if (modalText.indexOf('tab khác') !== -1 || modalText.indexOf('kích hoạt') !== -1 || modalText.indexOf('another tab') !== -1) {
                        var btns = modals[m].querySelectorAll('button, div[role="button"], [class*="btn"], [class*="primary"]');
                        for (var b = 0; b < btns.length; b++) {
                            var bText = (btns[b].innerText || '').trim().toLowerCase();
                            if (bText.indexOf('kích hoạt') !== -1 || bText.indexOf('activate') !== -1 || btns.length === 1) {
                                btns[b].click();
                                return true;
                            }
                        }
                    }
                }
            } catch(e) {}
            return false;
        }

        // Run immediately
        autoClickActivate();

        // Run at intervals to catch dynamic modals
        var attempts = 0;
        var interval = setInterval(function() {
            attempts++;
            if (autoClickActivate() || attempts > 25) {
                if (attempts > 25) clearInterval(interval);
            }
        }, 300);

        // MutationObserver to instantly dismiss the prompt the millisecond it gets rendered
        if (window.MutationObserver) {
            var observer = new MutationObserver(function() {
                autoClickActivate();
            });
            if (document.body) {
                observer.observe(document.body, { childList: true, subtree: true });
            } else {
                document.addEventListener('DOMContentLoaded', function() {
                    if (document.body) {
                        observer.observe(document.body, { childList: true, subtree: true });
                    }
                });
            }
        }
    })();
    """
}
