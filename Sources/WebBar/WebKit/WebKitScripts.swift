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
}
