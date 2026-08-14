import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_book_reader/flutter_book_reader.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fake_book_source.dart';

/// 加载态与错误态：失败必须呈现为「可重试的界面」，而不是抛给宿主（CLAUDE.md §5.3）。
void main() {
  setUp(() => ReaderConfig.instance.setFlipType(FlipType.slideHorizontal));

  testWidgets('正文加载中显示加载文案，就绪后消失', (WidgetTester tester) async {
    // 用 Completer 卡住正文加载，才能稳定观察到「加载中」这一帧
    // （普通 fake 会在首帧前就完成，测不到加载态）。
    final _GatedSource source = _GatedSource();
    await tester.pumpWidget(MaterialApp(
      home: BookReader(source: source, labels: ReaderLabels.chinese),
    ));
    await tester.pump();
    expect(find.text(ReaderLabels.chinese.loading), findsWidgets);

    source.release();
    await tester.pumpAndSettle();
    expect(find.text(ReaderLabels.chinese.loading), findsNothing);
    expect(find.textContaining('第 1 章第 1 段'), findsWidgets);
  });

  testWidgets('章节加载失败时显示失败文案与重试按钮，且不抛异常给宿主', (WidgetTester tester) async {
    final FakeBookSource source = FakeBookSource()..failing.add(0);
    await tester.pumpWidget(MaterialApp(
      home: BookReader(source: source, labels: ReaderLabels.chinese),
    ));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull, reason: '失败必须变成 UI 状态');
    expect(find.text(ReaderLabels.chinese.loadFailed), findsWidgets);
    expect(find.text(ReaderLabels.chinese.retry), findsWidgets);
  });

  testWidgets('点重试且数据源恢复后能正常读到正文', (WidgetTester tester) async {
    final FakeBookSource source = FakeBookSource()..failing.add(0);
    await tester.pumpWidget(MaterialApp(
      home: BookReader(source: source, labels: ReaderLabels.chinese),
    ));
    await tester.pumpAndSettle();
    expect(find.text(ReaderLabels.chinese.retry), findsWidgets);

    source.failing.remove(0);
    await tester.tap(find.text(ReaderLabels.chinese.retry).first);
    await tester.pumpAndSettle();

    expect(find.text(ReaderLabels.chinese.loadFailed), findsNothing);
    expect(find.textContaining('第 1 章第 1 段'), findsWidgets);
  });

  testWidgets('书籍清单加载失败时也呈现为可重试界面', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: BookReader(
        source: _FailingManifestSource(),
        labels: ReaderLabels.chinese,
      ),
    ));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(ReaderLabels.chinese.retry), findsWidgets);
  });

  testWidgets('相邻章加载失败不影响当前章阅读', (WidgetTester tester) async {
    final FakeBookSource source = FakeBookSource()..failing.add(1);
    await tester.pumpWidget(MaterialApp(
      home: BookReader(source: source, labels: ReaderLabels.chinese),
    ));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('第 1 章第 1 段'), findsWidgets, reason: '当前章正常显示');
  });
}

/// 清单加载即失败的数据源（验证入口 Widget 的错误态）。
class _FailingManifestSource extends BookSource {
  @override
  Future<BookManifest> loadManifest() async => throw Exception('清单加载失败');

  @override
  Future<String> loadChapterBody(int index) async => '';
}

/// 正文加载被 [Completer] 卡住的数据源：用于稳定观察「加载中」状态。
class _GatedSource extends BookSource {
  final Completer<void> _gate = Completer<void>();
  final FakeBookSource _delegate = FakeBookSource();

  void release() => _gate.complete();

  @override
  Future<BookManifest> loadManifest() => _delegate.loadManifest();

  @override
  Future<String> loadChapterBody(int index) async {
    await _gate.future;
    return _delegate.loadChapterBody(index);
  }
}
