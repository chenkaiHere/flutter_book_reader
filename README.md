# 📖 flutter_book_reader

[![pub package](https://img.shields.io/pub/v/flutter_book_reader.svg)](https://pub.dev/packages/flutter_book_reader)
[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

**English | [中文](README.zh-CN.md)**

> A polished, production-ready **novel & ebook reader** for Flutter — the kind of
> reading experience your users expect from a top-tier reading app, in a single
> widget.

🔗 **[Try the live demo →](https://ck-readbook-demo.ckdgdgdg.workers.dev/)** (runs in your browser)

<p align="center">
  <img src="https://ck-readbook-demo.ckdgdgdg.workers.dev/example/1.gif" width="270" alt="flutter_book_reader demo — reading & page-curl">
  &nbsp;&nbsp;
  <img src="https://ck-readbook-demo.ckdgdgdg.workers.dev/example/2.gif" width="270" alt="flutter_book_reader demo — themes & settings">
</p>

<p align="center">
  <img src="https://ck-readbook-demo.ckdgdgdg.workers.dev/example/en_1.jpeg" width="270" alt="flutter_book_reader — bookshelf">
  &nbsp;&nbsp;
  <img src="https://ck-readbook-demo.ckdgdgdg.workers.dev/example/en_2.jpeg" width="270" alt="flutter_book_reader — reader">
</p>

Point `BookReader` at your own data and you instantly get real pagination,
finger-following page-curl animations, chapter navigation, themes, and
reading-progress persistence. Everything is driven by small, replaceable
abstractions, so your content can come from an API, a database, local files, or
anywhere else — without touching the reader's internals.

## Why flutter_book_reader?

- 🪄 **It feels like a real book.** A realistic simulation page-curl that follows
  your finger, plus cover, slide, vertical-scroll, and no-animation modes.
- 📐 **Real pagination, not a scroll hack.** Paragraph-aware layout measured with
  `TextPainter`, with proper first-line indent and justification.
- 🔌 **Bring your own everything.** Data and progress storage are plain
  abstractions — network, DB, cloud sync, offline files all just work.
- 🎨 **Beautiful out of the box.** Six paper themes, one-tap day/night, adjustable
  font size / line height / spacing, and full-screen immersive reading.
- 🧪 **Built to last.** A widget-free logic core that's fully unit-tested, with a
  clean, documented architecture.

## Features

- **Five page modes** — a realistic **simulation** page-curl that follows your
  finger (corner dog-ear, or a vertical curl when you swipe from the middle),
  **cover** (incoming page slides over the current one), smooth **horizontal**
  paging (seamless, flicker-free chapter crossing), continuous **vertical**
  scroll (auto-loads the next / previous chapter), and **no-animation**.
- **Full-screen immersive reading** — hides the status & system navigation bars
  while reading (no content shift when the menu opens), restored on exit; plus a
  one-tap **day / night** toggle.
- **Real pagination** via `TextPainter`, paragraph-aware: reader-owned first-line
  indent (works together with justification), paragraph spacing, and
  justification. Reading position is preserved across font-size / line-height /
  system-text-scale changes.
- **Lazy chapter loading** with neighbor prefetch, a bounded LRU cache, and
  loading & **error / retry** states.
- **Pluggable data source** (`BookSource`) and **progress storage**
  (`ReaderProgressStore`) — bring your own network / DB / cloud implementation.
- **Debounced progress saving** with a flush when the app goes to background.
- **Theming & typography** — six built-in paper themes, per-theme accent color,
  and runtime controls for font size / line height / brightness.
- **Localization built in** — `ReaderLabels` ships **12 languages** (en, zh, es,
  fr, ar, bn, pt, ru, hi, ur, ja, ko) via `ReaderLabels.forLanguageCode(code)`
  (English fallback); every string is still overridable. Basic accessibility
  semantics.

## Install

```yaml
dependencies:
  flutter_book_reader: ^1.2.0
```

```dart
import 'package:flutter_book_reader/flutter_book_reader.dart';
```

## Quick start

```dart
BookReader(
  source: MyBookSource(),               // your data
  progressStore: MyProgressStore(),     // optional, defaults to no-op
  onChapterChanged: (int index) => debugPrint('chapter $index'),
  onPositionChanged: (ReadingPosition pos) => save(pos),
)
```

### 1. Provide a data source

`BookSource` is the only thing you must implement. It returns book metadata +
a chapter list once, and chapter bodies on demand.

```dart
class MyBookSource extends BookSource {
  @override
  Future<BookManifest> loadManifest() async => BookManifest(
        id: 42,
        title: 'The Long Journey',
        author: 'Jane Doe',
        intro: '…',
        coverColor: Colors.blueGrey,
        chapterTitles: <String>['Chapter 1', 'Chapter 2', 'Chapter 3'],
      );

  @override
  Future<String> loadChapterBody(int index) async {
    // Fetch from your API / DB / assets. Paragraphs separated by '\n'.
    return api.fetchChapter(index);
  }
}
```

### 2. (Optional) Persist reading progress

```dart
class PrefsProgressStore extends ReaderProgressStore {
  @override
  Future<ReadingPosition?> load(Object bookId) async { /* … */ }

  @override
  Future<void> save(Object bookId, ReadingPosition position) async { /* … */ }
}
```

Built-ins: `NoopReaderProgressStore` (default) and `InMemoryReaderProgressStore`.

### 3. Theming, typography & page mode

```dart
final config = ReaderConfig()
  ..setTheme(ReaderTheme.yellow.copyWith(accentColor: const Color(0xFF3366FF)))
  ..setFlipType(FlipType.simulation) // simulation / cover / slideHorizontal / scrollVertical / none
  ..setFirstLineIndent(2)
  ..setParagraphSpacing(8)
  ..setJustify(true);

BookReader(source: MyBookSource(), config: config);
```

Users can also switch theme, page mode, font size, spacing, and day / night from
the in-reader settings menu at runtime.

### 4. Localize the UI

Twelve languages are built in — just pass the current language code (anything
outside the 12 falls back to English):

```dart
BookReader(
  source: MyBookSource(),
  labels: ReaderLabels.forLanguageCode(
    Localizations.localeOf(context).languageCode, // 'zh', 'en', 'ja', …
  ),
)
```

Or supply your own strings for full control / white-labeling:

```dart
BookReader(
  source: MyBookSource(),
  labels: const ReaderLabels(prevChapter: 'Previous', catalog: 'Contents'),
)
```

## Architecture

- `BookSource` / `ReaderProgressStore` — public extension points (abstractions).
- `ReadingController` — pure, widget-free logic core, composed from four
  **mixins** (content loading / pagination / navigation / vertical flow); fully
  unit-testable.
- `ReaderModeView` — view base class; `HorizontalReader`, `VerticalReader`, and
  `SimulationReader` **extend** it.
- `BookReader` — the single entry-point widget.

## Example

Try the **[live demo](https://ck-readbook-demo.ckdgdgdg.workers.dev/)** in your
browser, or run it locally. A full example app (bookshelf + reader, data from
`assets/books.json`) lives in [`example/`](example) and depends on this package
via `path: ../`:

```bash
cd example
flutter run
```

## License

MIT — see [LICENSE](LICENSE).
