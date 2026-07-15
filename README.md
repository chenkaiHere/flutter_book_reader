# flutter_book_reader

[![pub package](https://img.shields.io/pub/v/flutter_book_reader.svg)](https://pub.dev/packages/flutter_book_reader)
[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

English | [中文](README.zh-CN.md)

🔗 **[Live demo](https://ck-readbook-demo.ckdgdgdg.workers.dev/)** — try it in your browser.

A customizable, production-ready **novel / ebook reader widget** for Flutter.

Drop in `BookReader`, point it at your own data source, and you get paginated
and continuous-scroll reading, chapter navigation, themes, and reading-progress
persistence — all driven by replaceable abstractions, so your content can come
from the network, a database, local files, or anywhere else.

> 一个可商用、可定制的 Flutter 小说 / 电子书阅读器组件。数据源与进度存储均为可替换的抽象，
> 业务方无需改动组件内部即可接入网络 / 数据库 / 本地文件。

## Features

- **Three page modes** — smooth horizontal paging (seamless chapter crossing, no
  flicker), continuous vertical scroll (auto-loads the next/previous chapter),
  and no-animation.
- **Real pagination** via `TextPainter`, paragraph-aware: reader-owned first-line
  indent, paragraph spacing, and justification. Reading position is preserved
  across font-size / line-height / system-text-scale changes.
- **Lazy chapter loading** with neighbor prefetch, bounded LRU cache, loading &
  **error/retry** states.
- **Pluggable data source** (`BookSource`) and **progress storage**
  (`ReaderProgressStore`) — bring your own network/DB/cloud implementation.
- **Debounced progress saving** with flush on app background.
- **Theming & typography**: six built-in paper themes, per-theme accent color,
  font size / line height / brightness overlay.
- **Localizable** UI strings (`ReaderLabels`) and basic accessibility semantics.

## Install

```yaml
dependencies:
  flutter_book_reader: ^1.0.0
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

### 3. Theming & typography

```dart
final config = ReaderConfig()
  ..setTheme(ReaderTheme.yellow.copyWith(accentColor: const Color(0xFF3366FF)))
  ..setFirstLineIndent(2)
  ..setParagraphSpacing(8)
  ..setJustify(true);

BookReader(source: MyBookSource(), config: config);
```

### 4. Localize the UI

```dart
BookReader(
  source: MyBookSource(),
  labels: const ReaderLabels(
    prevChapter: 'Previous',
    nextChapter: 'Next',
    catalog: 'Contents',
    // …
  ),
)
```

## Architecture

- `BookSource` / `ReaderProgressStore` — public extension points (abstractions).
- `ReadingController` — pure, widget-free logic core, composed from four
  **mixins** (content loading / pagination / navigation / vertical flow); fully
  unit-testable.
- `ReaderModeView` — view base class; `HorizontalReader` and `VerticalReader`
  **extend** it.
- `BookReader` — the single entry-point widget.

## Example

Try the **[live demo](https://ck-readbook-demo.ckdgdgdg.workers.dev/)** in your browser,
or run it locally. A full example app (bookshelf + reader, data from
`assets/books.json`) lives in [`example/`](example) and depends on this package
via `path: ../`:

```bash
cd example
flutter run
```

## License

MIT — see [LICENSE](LICENSE).
