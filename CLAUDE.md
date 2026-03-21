# ChatAI Plasmoid

KDE Plasma 6 widget that embeds AI chat services (ChatGPT, Claude, Gemini, DuckDuckGo, DeepSeek, etc.) in a panel popup using QtWebEngine.

## Architecture

Pure QML plasmoid — no C++, no build system. Installed via KDE package manager.

```
contents/
  config/
    main.xml          # KDE configuration schema (all settings)
    config.qml        # Config tab definitions (General + Appearance)
  ui/
    main.qml          # PlasmoidItem root, popup layout, header auto-hide, WebView loader
    WebView.qml       # WebEngineView, permissions, downloads, context menu, JS injection
    Header.qml        # Navigation bar, URL selector, control buttons (Item wrapping RowLayout)
    CompactRepresentation.qml  # Panel icon with dynamic icon modes
    ConfigGeneral.qml          # Settings: sites, permissions, web features, downloads, cache
    ConfigAppearance.qml       # Settings: icon, effects, transparency, focus mode, header options
    FindBar.qml        # Ctrl+F find-in-page bar
    DownloadBar.qml    # Download progress/cancel/open UI
```

## Key patterns

- **Configuration**: all settings in `main.xml`, accessed via `plasmoid.configuration.propertyName`
- **Signals**: Header communicates with main.qml via signals (goBackToHomePage, navigateBackRequested, etc.)
- **JS injection**: WebView injects CSS/JS into pages for: browser spoofing, transparency, focus mode, keyboard shortcuts
- **Heuristic DOM analysis**: transparency and focus mode analyze page structure to find sidebars, headers, input areas
- **WebEngine lifecycle**: configurable keep-alive (instant reopen) or 5-min idle unload (memory saving)

## Important constraints

- `PlasmaExtras.Menu`/`MenuItem` do NOT exist in Plasma 6 — use `PlasmaComponents3.Menu`/`MenuItem`
- `PlasmaComponents3.Menu` cannot be a root type in a separate QML file (causes "Type cannot be created in QML")
- `import org.kde.notification` MUST keep version `1.0` (unversioned fails at runtime)
- `MultiEffect` blur cannot affect WebEngineView content (native surface) — use CSS injection instead
- `backgroundHints` is set via `Plasmoid.backgroundHints` (attached property), not directly on PlasmoidItem
- Header.qml root is `Item` (not `RowLayout`) — signals, properties, and functions must be on the Item, not inside the RowLayout

## Configuration properties

Settings are split across two tabs:

**General** (ConfigGeneral.qml): site toggles (showChatGPT, showClaude, etc.), custom sites, permissions (mic/webcam/screenshare/notifications/geolocation), web features (JS clipboard, spatial nav), download path, cache management, profile name, keepWebEngineAlive, spoofChromeBrowser

**Appearance** (ConfigAppearance.qml): iconMode, animations, header gradient, accent glow, focus mode, transparency + opacity slider, header visibility toggles

## JS injection layers (WebView.qml)

Applied on every page load via `onLoadingChanged`:

1. **Browser spoof** (`injectBrowserSpoof`): Chrome 130 UA, navigator.vendor/platform/plugins, window.chrome object
2. **Transparency** (`injectTransparencyCSS`): heuristic DOM walk, classifies elements as chrome/background/chat, applies layered rgba + backdrop-blur
3. **Focus mode** (`injectFocusMode`): per-site CSS rules + heuristic fallback hiding nav/aside/header/sidebar
4. **Keyboard shortcuts**: Enter-to-send for compatible services (DuckDuckGo, ChatGPT, Gemini, Claude, You)

## Testing

No automated tests. Test by:
1. Installing: `plasmashell --replace &` or remove/re-add widget
2. Check logs: `journalctl --user -u plasma-plasmashell -b | grep -i "chatai\|webview\|error"`
3. Lint: `qmllint contents/ui/*.qml` (ignore "Library import requires a version" warnings)
