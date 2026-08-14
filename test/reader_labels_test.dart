import 'package:flutter_book_reader/flutter_book_reader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReaderLabels.forLanguageCode', () {
    test('命中内置 12 种语言', () {
      const List<String> codes = <String>[
        'en',
        'zh',
        'es',
        'fr',
        'ar',
        'bn',
        'pt',
        'ru',
        'hi',
        'ur',
        'ja',
        'ko',
      ];
      for (final String code in codes) {
        expect(ReaderLabels.forLanguageCode(code), isA<ReaderLabels>(),
            reason: code);
      }
      expect(ReaderLabels.forLanguageCode('zh').catalog, '目录');
      expect(ReaderLabels.forLanguageCode('ja').catalog, isNot('目录'));
    });

    test('未命中 / null 回退英文', () {
      expect(ReaderLabels.forLanguageCode('xx'), ReaderLabels.english);
      expect(ReaderLabels.forLanguageCode(null), ReaderLabels.english);
    });

    test('默认构造即英文预设', () {
      expect(const ReaderLabels().catalog, ReaderLabels.english.catalog);
      expect(ReaderLabels.fallback, ReaderLabels.english);
    });
  });

  group('章节模板', () {
    test('chapterProgress 把章号显示为从 1 起', () {
      expect(ReaderLabels.chinese.chapterProgress(0, 10), '第 1/10 章');
      expect(ReaderLabels.chinese.chapterProgress(9, 10), '第 10/10 章');
    });

    test('chapterTotal 填入总章数', () {
      expect(ReaderLabels.chinese.chapterTotal(42), '共 42 章');
    });

    test('自定义模板同样被正确替换', () {
      const ReaderLabels custom = ReaderLabels(
        chapterProgressTemplate: '[{i}/{n}]',
        chapterTotalTemplate: '<{n}>',
      );
      expect(custom.chapterProgress(2, 5), '[3/5]');
      expect(custom.chapterTotal(5), '<5>');
    });
  });

  group('relativeTime（注入固定 now，不依赖真实时间）', () {
    final DateTime now = DateTime.utc(2026, 3, 10, 12);
    int msAgo(Duration d) => now.subtract(d).millisecondsSinceEpoch;

    test('非法时间戳返回空串', () {
      expect(ReaderLabels.chinese.relativeTime(0, now: now), '');
      expect(ReaderLabels.chinese.relativeTime(-1, now: now), '');
    });

    test('不足 1 分钟显示「刚刚」', () {
      expect(
        ReaderLabels.chinese
            .relativeTime(msAgo(const Duration(seconds: 59)), now: now),
        ReaderLabels.chinese.timeJustNow,
      );
    });

    test('1 分钟到 1 小时之间显示分钟', () {
      expect(
        ReaderLabels.chinese
            .relativeTime(msAgo(const Duration(minutes: 1)), now: now),
        '1 分钟前',
      );
      expect(
        ReaderLabels.chinese
            .relativeTime(msAgo(const Duration(minutes: 59)), now: now),
        '59 分钟前',
      );
    });

    test('1 小时到 1 天之间显示小时', () {
      expect(
        ReaderLabels.chinese
            .relativeTime(msAgo(const Duration(hours: 1)), now: now),
        '1 小时前',
      );
      expect(
        ReaderLabels.chinese
            .relativeTime(msAgo(const Duration(hours: 23)), now: now),
        '23 小时前',
      );
    });

    test('1 到 7 天显示天数（边界 7 天仍为相对时间）', () {
      expect(
        ReaderLabels.chinese
            .relativeTime(msAgo(const Duration(days: 1)), now: now),
        '1 天前',
      );
      expect(
        ReaderLabels.chinese
            .relativeTime(msAgo(const Duration(days: 7)), now: now),
        '7 天前',
      );
    });

    test('超过 7 天改用绝对日期 yyyy-MM-dd（含零填充）', () {
      expect(
        ReaderLabels.chinese
            .relativeTime(msAgo(const Duration(days: 8)), now: now),
        '2026-03-02',
      );
      final DateTime early = DateTime.utc(2026, 1, 5);
      expect(
        ReaderLabels.chinese.relativeTime(
          early.millisecondsSinceEpoch,
          now: DateTime.utc(2026, 2, 1),
        ),
        '2026-01-05',
      );
    });

    test('英文预设走同一套逻辑，只是文案不同', () {
      expect(
        ReaderLabels.english
            .relativeTime(msAgo(const Duration(minutes: 5)), now: now),
        '5 min ago',
      );
    });
  });
}
