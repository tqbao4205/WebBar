import Foundation
import WebKit

public final class AdBlockManager {
    public static let shared = AdBlockManager()
    
    private init() {}
    
    /// Basic CSS rules to hide prominent floating ads, video overlays, and giant cookie banners
    public var adBlockCSS: String {
        """
        /* Hide common ads, banner frames and trackers */
        iframe[src*="doubleclick.net"],
        iframe[src*="googlesyndication.com"],
        iframe[src*="adservice.google"],
        div[class*="ad-container"],
        div[class*="ad_wrapper"],
        div[id*="google_ads"],
        div[class*="sponsored-post"],
        div[id*="taboola-"],
        div[class*="outbrain"],
        .adsbygoogle,
        #carbonads {
            display: none !important;
            visibility: hidden !important;
            height: 0 !important;
            pointer-events: none !important;
        }
        """
    }
    
    /// Dark mode CSS rule injector for websites that don't have native dark mode
    public var forceDarkModeCSS: String {
        """
        @media (prefers-color-scheme: light) {
            html {
                filter: invert(90%) hue-rotate(180deg) !important;
                background-color: #121212 !important;
            }
            img, video, canvas, svg, picture, [style*="background-image"] {
                filter: invert(100%) hue-rotate(180deg) !important;
            }
        }
        """
    }
    
    /// Script to clean up mobile zoom locks and viewport metatags for smooth responsive resizing
    public var mobileViewportFixScript: String {
        """
        (function() {
            var meta = document.querySelector('meta[name="viewport"]');
            if (!meta) {
                meta = document.createElement('meta');
                meta.name = 'viewport';
                document.head.appendChild(meta);
            }
            meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=5.0, user-scalable=yes';
        })();
        """
    }
    
    public func createAdBlockUserScript() -> WKUserScript {
        let scriptSource = """
        (function() {
            var style = document.createElement('style');
            style.type = 'text/css';
            style.innerHTML = `\(adBlockCSS)`;
            (document.head || document.documentElement).appendChild(style);
        })();
        """
        return WKUserScript(
            source: scriptSource,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: false
        )
    }
    
    public func createDarkModeUserScript() -> WKUserScript {
        let scriptSource = """
        (function() {
            var style = document.createElement('style');
            style.id = 'webbar-dark-mode';
            style.type = 'text/css';
            style.innerHTML = `\(forceDarkModeCSS)`;
            (document.head || document.documentElement).appendChild(style);
        })();
        """
        return WKUserScript(
            source: scriptSource,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )
    }
    
    /// Optimized Mobile TikTok Script & CSS to provide pure iPhone native short video UI without auto-skipping
    public func createTikTokOptimizerUserScript() -> WKUserScript {
        let scriptSource = """
        (function() {
            // 1. Inject CSS to transform TikTok into a clean, immersive full-screen vertical app
            var style = document.createElement('style');
            style.id = 'tiktok-immersive-iphone-ui';
            style.type = 'text/css';
            style.innerHTML = `
                /* Hide Desktop Header, Sidebar, and App promotion bars */
                header,
                [data-e2e="tiktok-header"],
                [data-e2e="header"],
                #header-wrapper,
                aside,
                [data-e2e="sidebar-container"],
                [data-e2e="nav-bar"],
                [class*="DivSideNavContainer"],
                [class*="DivNavWrapper"],
                [class*="DivHeaderContainer"],
                [class*="DivBannerContainer"],
                [class*="DivDownload"],
                [class*="download-bar"],
                [class*="floating-app"],
                [class*="open-app"],
                [class*="DivFloatingAppDownload"],
                [data-e2e="download-app"],
                [data-e2e="bottom-banner"],
                .tiktok-app-banner,
                [class*="DivModalMask"],
                [class*="ModalMask"] {
                    display: none !important;
                    visibility: hidden !important;
                    height: 0 !important;
                    width: 0 !important;
                    opacity: 0 !important;
                    pointer-events: none !important;
                }

                /* Expand Main Feed to 100% width & height (Clean iPhone UI) */
                html, body {
                    overflow-x: hidden !important;
                    background-color: #000000 !important;
                    margin: 0 !important;
                    padding: 0 !important;
                    width: 100vw !important;
                    height: 100vh !important;
                }

                [class*="DivBodyContainer"],
                [class*="DivMainContainer"],
                [class*="DivContentContainer"],
                [class*="DivFeedContainer"],
                [class*="DivThreeColumnContainer"],
                [class*="DivTwoColumnContainer"] {
                    width: 100% !important;
                    max-width: 100% !important;
                    margin: 0 !important;
                    padding: 0 !important;
                    justify-content: center !important;
                }

                /* Center and format video player card */
                [class*="DivItemContainer"],
                [class*="DivVideoFeed"],
                [class*="DivFeedList"],
                [data-e2e="feed-item"],
                [data-e2e="recommend-list-item-container"] {
                    width: 100vw !important;
                    max-width: 100% !important;
                    height: 100vh !important;
                    margin: 0 auto !important;
                    padding: 0 !important;
                    display: flex !important;
                    justify-content: center !important;
                    align-items: center !important;
                    scroll-snap-align: start !important;
                }

                /* Video element fills player cleanly */
                video {
                    object-fit: cover !important;
                    border-radius: 0 !important;
                }
            `;
            (document.head || document.documentElement).appendChild(style);
        })();
        """
        return WKUserScript(
            source: scriptSource,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: false
        )
    }
}
