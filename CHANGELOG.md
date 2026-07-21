# Changelog

## 1.4.0

- Paragraph comments: a tappable comment-count badge at each paragraph's end via
  `onSegmentCommentTap`; the host renders the comment list. `commentsRefresh`
  lets the host refresh badges / notes after adding a comment.
- Fix: the reader no longer re-paginates (the background page no longer jumps)
  when a comment input keyboard opens over it.

## 1.3.0

- Text selection with draggable handles, plus highlights (`ReaderUnderlineStore`)
  and comments (`ReaderCommentStore`), all collected in a **Notes** panel.
- Bubble toolbar actions (copy / comment / look-up / share) are now callbacks via
  `onTextAction`; only highlight stays internal.
  - ⚠️ Breaking: `ReaderTextActionCallback` now passes `ReaderSelection` instead of
    `String`, and `ReaderTextAction` adds `comment`.
- While the menu or selection bubble is open, a swipe only closes it (no
  accidental page turn).

## 1.2.0

- Built-in 12-language labels via `ReaderLabels.forLanguageCode(code)` (English
  fallback, still overridable).
- Redesigned menu and a draggable catalog with swipeable detail / contents /
  bookmarks tabs.
- Refined the six paper themes.

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
