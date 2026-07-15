# flutter_book_reader

[![pub package](https://img.shields.io/pub/v/flutter_book_reader.svg)](https://pub.dev/packages/flutter_book_reader)
[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

[English](README.md) | 中文

🔗 **[在线体验](https://ck-readbook-demo.ckdgdgdg.workers.dev/)** —— 打开浏览器即可试用。

一个可商用、可定制的 Flutter **小说 / 电子书阅读器组件**。

放入 `BookReader`、接上你自己的数据源，即可获得分页阅读与上下连续滚动、章节导航、
主题、阅读进度持久化 —— 全部由可替换的抽象驱动，正文可来自网络、数据库、本地文件或任何来源。

## 特性

- **三种翻页方式** —— 横向平滑翻页（跨章无缝、无跳动）、上下连续滚动（自动加载上/下一章）、无动画。
- **真实分页**（基于 `TextPainter`，段落感知）：首行缩进、段间距、两端对齐均由阅读器掌控；
  切换字号 / 行距 / 系统字体缩放后保留阅读位置。
- **章节按需懒加载**：相邻章预取、带上限的 LRU 缓存、加载中与**失败重试**态。
- **可替换的数据源**（`BookSource`）与**进度存储**（`ReaderProgressStore`）——
  自行实现网络 / 数据库 / 云端版本即可接入。
- **进度防抖保存**，应用进入后台时立即落盘。
- **主题与排版**：六套内置纸张主题、每套可定制强调色、字号 / 行距 / 亮度蒙层。
- **文案可本地化**（`ReaderLabels`），并具备基础无障碍语义。

## 安装

```yaml
dependencies:
  flutter_book_reader: ^1.0.0
```

```dart
import 'package:flutter_book_reader/flutter_book_reader.dart';
```

## 快速开始

```dart
BookReader(
  source: MyBookSource(),               // 你的数据
  progressStore: MyProgressStore(),     // 可选，默认不持久化
  onChapterChanged: (int index) => debugPrint('第 $index 章'),
  onPositionChanged: (ReadingPosition pos) => save(pos),
)
```

### 1. 提供数据源

`BookSource` 是唯一必须实现的接口：一次性返回书籍信息 + 目录，正文按需返回。

```dart
class MyBookSource extends BookSource {
  @override
  Future<BookManifest> loadManifest() async => BookManifest(
        id: 42,
        title: '山海行记',
        author: '云中鹤',
        intro: '……',
        coverColor: Colors.blueGrey,
        chapterTitles: <String>['第一章', '第二章', '第三章'],
      );

  @override
  Future<String> loadChapterBody(int index) async {
    // 从接口 / 数据库 / 资源读取，段落之间用 '\n' 分隔。
    return api.fetchChapter(index);
  }
}
```

### 2.（可选）持久化阅读进度

```dart
class PrefsProgressStore extends ReaderProgressStore {
  @override
  Future<ReadingPosition?> load(Object bookId) async { /* … */ }

  @override
  Future<void> save(Object bookId, ReadingPosition position) async { /* … */ }
}
```

内置实现：`NoopReaderProgressStore`（默认，不持久化）与 `InMemoryReaderProgressStore`（内存）。

### 3. 主题与排版

```dart
final config = ReaderConfig()
  ..setTheme(ReaderTheme.yellow.copyWith(accentColor: const Color(0xFF3366FF)))
  ..setFirstLineIndent(2)
  ..setParagraphSpacing(8)
  ..setJustify(true);

BookReader(source: MyBookSource(), config: config);
```

### 4. 本地化界面文案

```dart
BookReader(
  source: MyBookSource(),
  labels: const ReaderLabels(
    prevChapter: '上一章',
    nextChapter: '下一章',
    catalog: '目录',
    // …
  ),
)
```

## 架构

- `BookSource` / `ReaderProgressStore` —— 对外扩展点（抽象）。
- `ReadingController` —— 纯逻辑核心（不含 Widget），由内容加载 / 分页 / 翻页 / 纵向流
  四个 **mixin** 组合，完全可单元测试。
- `ReaderModeView` —— 视图基类；`HorizontalReader`、`VerticalReader` **继承**它。
- `BookReader` —— 对外统一入口组件。

## 示例

可以直接[**在线体验**](https://ck-readbook-demo.ckdgdgdg.workers.dev/)，或在本地运行。
`example/` 是一个完整示例 app（书架 + 阅读器，数据来自 `assets/books.json`），
通过 `path: ../` 依赖本包：

```bash
cd example
flutter run
```

## 许可证

MIT，详见 [LICENSE](LICENSE)。
