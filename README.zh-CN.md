# 📖 flutter_book_reader

[![pub package](https://img.shields.io/pub/v/flutter_book_reader.svg)](https://pub.dev/packages/flutter_book_reader)
[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

**[English](README.md) | 中文**

> 一个精致、可商用的 Flutter **小说 / 电子书阅读器** —— 把头部阅读 App 才有的阅读体验，
> 浓缩进一个组件里。

🔗 **[打开在线体验 →](https://ck-readbook-demo.ckdgdgdg.workers.dev/)**（浏览器即可试用）

把 `BookReader` 接上你自己的数据，立刻就能得到真实分页、跟随手指的仿真翻页、章节导航、
主题与阅读进度持久化。一切都由小而可替换的抽象驱动 —— 正文可以来自接口、数据库、本地文件，
或任何地方，无需改动组件内部。

## 为什么选它？

- 🪄 **翻起来像真书。** 跟随手指的仿真书页卷曲，另有覆盖、平移、上下滚动、无动画多种方式。
- 📐 **是真分页，不是滚动凑数。** 基于 `TextPainter` 的段落级排版，首行缩进与两端对齐都正确。
- 🔌 **一切自带、皆可替换。** 数据与进度存储都是纯抽象 —— 网络、数据库、云同步、离线文件皆可接入。
- 🎨 **开箱即美。** 六套纸张主题、日间 / 夜间一键切换、字号 / 行距 / 间距可调、全屏沉浸阅读。
- 🧪 **经得起用。** 不含 Widget 的纯逻辑核心，完全可单元测试，架构清晰且有注释。

## 特性

- **五种翻页方式** —— **仿真翻页**（书页折角卷曲、跟随手指，从中段滑动则竖直卷曲）、
  **覆盖翻页**（新页从上方滑入盖住当前页）、横向**平移**（跨章无缝、无跳动）、
  上下连续滚动（自动加载上 / 下一章）、无动画。
- **全屏沉浸阅读** —— 阅读时隐藏系统状态栏与底部导航栏，唤起菜单也保持隐藏（正文不再被顶下），
  退出后自动恢复；菜单内还提供**日间 / 夜间**一键切换。
- **真实分页**（基于 `TextPainter`，段落感知）：首行缩进（与两端对齐并存）、段间距、
  两端对齐均由阅读器掌控；切换字号 / 行距 / 系统字体缩放后保留阅读位置。
- **章节按需懒加载**：相邻章预取、带上限的 LRU 缓存、加载中与**失败重试**态。
- **可替换的数据源**（`BookSource`）与**进度存储**（`ReaderProgressStore`）——
  自行实现网络 / 数据库 / 云端版本即可接入。
- **进度防抖保存**，应用进入后台时立即落盘。
- **主题与排版**：六套内置纸张主题、每套可定制强调色，字号 / 行距 / 亮度可运行时调节。
- **文案可本地化**（`ReaderLabels`），并具备基础无障碍语义。

## 安装

```yaml
dependencies:
  flutter_book_reader: ^1.1.0
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

### 3. 主题、排版与翻页方式

```dart
final config = ReaderConfig()
  ..setTheme(ReaderTheme.yellow.copyWith(accentColor: const Color(0xFF3366FF)))
  ..setFlipType(FlipType.simulation) // 仿真 / 覆盖 / 平移(slideHorizontal) / 上下(scrollVertical) / 无动画(none)
  ..setFirstLineIndent(2)
  ..setParagraphSpacing(8)
  ..setJustify(true);

BookReader(source: MyBookSource(), config: config);
```

用户也可以在阅读页的设置菜单里实时切换主题、翻页方式、字号、间距与日间 / 夜间。

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
- `ReaderModeView` —— 视图基类；`HorizontalReader`、`VerticalReader`、`SimulationReader`
  **继承**它。
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
