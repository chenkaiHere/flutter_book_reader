import 'package:flutter_book_reader/flutter_book_reader.dart';
import 'package:flutter_book_reader/src/controller/chapter_content_mixin.dart';
import 'package:flutter_book_reader/src/controller/reading_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_book_source.dart';

void main() {
  const Size viewport = Size(300, 500);

  test('分页 / 翻页 / 切章 全流程（无 Widget，仅控制器）', () async {
    final FakeBookSource source = FakeBookSource(chapters: 5);
    final BookManifest manifest = await source.loadManifest();
    final ReadingController c = ReadingController(
      source: source,
      manifest: manifest,
    );
    addTearDown(c.dispose);

    await c.ensureLoaded(0);
    c.updateViewport(viewport, TextScaler.noScaling);
    expect(c.pages.length, greaterThan(1), reason: '整章应分成多页');

    c.goToPage(1);
    expect(c.pageIndex, 1);

    // 本章末页再 nextPage 应切到下一章
    c.goToPage(c.pages.length - 1);
    c.nextPage();
    expect(c.chapterIndex, 1);

    await c.ensureLoaded(1);
    c.updateViewport(viewport, TextScaler.noScaling);
    expect(c.globalProgress, greaterThan(0));
  });

  test('向前翻入上一章定位到最后一页', () async {
    final FakeBookSource source = FakeBookSource(chapters: 3);
    final BookManifest manifest = await source.loadManifest();
    final ReadingController c = ReadingController(
      source: source,
      manifest: manifest,
      startChapter: 2,
    );
    addTearDown(c.dispose);

    await c.ensureLoaded(1);
    await c.ensureLoaded(2);
    c.updateViewport(viewport, TextScaler.noScaling);

    c.loadChapter(1, atEnd: true);
    c.updateViewport(viewport, TextScaler.noScaling);
    expect(c.chapterIndex, 1);
    expect(c.pageIndex, c.pages.length - 1, reason: '应定位到上一章末页');
  });

  test('章节加载失败进入错误态，重试后恢复', () async {
    final FakeBookSource source = FakeBookSource(chapters: 5)..failing.add(0);
    final BookManifest manifest = await source.loadManifest();
    final ReadingController c = ReadingController(
      source: source,
      manifest: manifest,
    );
    addTearDown(c.dispose);

    await c.ensureLoaded(0);
    expect(c.hasError(0), isTrue);
    expect(c.bodyOf(0), isNull);

    source.failing.remove(0);
    await c.retry(0);
    expect(c.hasError(0), isFalse);
    expect(c.isLoaded(0), isTrue);
  });

  test('缓存有上限，远处章节被淘汰', () async {
    final FakeBookSource source = FakeBookSource(chapters: 40);
    final BookManifest manifest = await source.loadManifest();
    final ReadingController c = ReadingController(
      source: source,
      manifest: manifest,
    );
    addTearDown(c.dispose);

    for (int i = 0; i < 30; i++) {
      await c.ensureLoaded(i);
    }
    final int loaded = List<int>.generate(
      30,
      (int i) => i,
    ).where(c.isLoaded).length;
    expect(loaded, lessThanOrEqualTo(ChapterContentMixin.maxCachedChapters));
  });

  test('系统字体缩放变化会触发重新分页', () async {
    final FakeBookSource source = FakeBookSource(chapters: 2);
    final BookManifest manifest = await source.loadManifest();
    final ReadingController c = ReadingController(
      source: source,
      manifest: manifest,
    );
    addTearDown(c.dispose);

    await c.ensureLoaded(0);
    c.updateViewport(viewport, TextScaler.noScaling);
    final int base = c.pages.length;

    c.updateViewport(viewport, const TextScaler.linear(1.6));
    expect(c.pages.length, greaterThan(base), reason: '放大字体后页数应增加');
  });
}
