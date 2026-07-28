# Changelog

## 1.5.5

- Paid / locked chapters: mark chapters as locked via `isChapterLocked`. A locked
  chapter shows only its first page

## 1.5.4

- Performance: smoother text selection dragging and page turns — per-page layout
  invariants (comment-badge counts, indent width, block offsets) are now cached
  instead of recomputed each frame, most noticeable in heavily annotated books.

## 1.5.3

- Fix: opening the menu no longer shifts the page (system bars now overlay via
  edge-to-edge instead of resizing the reader), and tapping while the menu is
  open only closes it — never turns a page.
- Fix: a paragraph's comment badge now sits at the paragraph's true end — even
  when the paragraph spans pages — instead of at the bottom of the page.

## 1.5.2

- System status / navigation bars now show with the menu and hide when it closes;
  toggle via `showSystemBarsWithMenu` (default `true`).
- Optional footer **battery indicator**, host-fed via
  `battery: ValueListenable<ReaderBatteryInfo?>`; `null` hides it.

## 1.5.1

- Optional host-styled **title page** before chapter 1 via `titlePageBuilder`
  (a real, flippable page); `null` for none.

## 1.5.0

- New public `BookReaderController` for imperative control (paging, chapter jumps,
  `currentPageText`, read-along highlight, programmatic bookmarks).
- Paragraph comments via `onSegmentCommentTap` + `commentsRefresh`.
- Fix: no re-pagination when a bottom sheet / keyboard opens over the reader.

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
