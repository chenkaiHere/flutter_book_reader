# Changelog

## 1.1.0

- New page-turn modes: `simulation` and `cover`, for five in total.
- Full-screen immersive reading (hides status & navigation bars); nav bar
  restored on exit.
- First-line indent now works with justified text.
- Reworked settings menu with a one-tap day/night toggle.

## 1.0.0

Initial release.

- Three page modes: horizontal paging (seamless, flicker-free chapter crossing),
  continuous vertical scroll (auto chapter loading), and no-animation.
- Paragraph-aware pagination via `TextPainter`; reader-owned first-line indent,
  paragraph spacing, and justification. Reading position preserved across
  font-size / line-height / system-text-scale changes.
- Lazy chapter loading with neighbor prefetch, bounded LRU cache, and
  loading / error-retry states.
- Pluggable `BookSource` (data) and `ReaderProgressStore` (progress) abstractions.
- Debounced progress saving with flush on app background.
- Six built-in themes with per-theme accent color; font size / line height /
  brightness overlay.
- Localizable UI strings via `ReaderLabels`; basic accessibility semantics.
- Callbacks: `onChapterChanged`, `onPositionChanged`, `onClose`.
