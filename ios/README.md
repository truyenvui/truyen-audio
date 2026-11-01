# Góc Nghe Truyện — iOS browser rebuild

This folder is the native iOS starting point for replacing the old audio-player interface with a story-importing app.

## Current prototype
- Native in-app browser built with Apple's WKWebView.
- Address field, open, back, forward, and reload controls.
- A first-pass article/chapter text extractor that reads the page already loaded in the web view.
- Extracted text preview.

## Important limits
- This is Swift source code, not an installable iPhone app or an update to the GitHub Pages website.
- It must be built and signed as an iOS app with Xcode on a Mac before it can be installed on an iPhone.
- The extractor does not bypass CAPTCHA, login, paywalls, anti-bot checks, or other site restrictions. Some sites may still block or prevent extraction.
- The old GitHub Pages app and its local library are not changed by this branch.

## Next development steps
1. Test extraction against pages the user is allowed to access.
2. Improve chapter-body selectors and remove navigation/advertising noise.
3. Add chapter discovery and duplicate detection for accessible story indexes.
4. Add EPUB generation and library import/export.
5. Plan a safe migration path for any existing library backup.
