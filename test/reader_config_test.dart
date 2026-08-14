import 'package:flutter/material.dart';
import 'package:flutter_book_reader/flutter_book_reader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('字号', () {
    test('increase / decrease 各变动 1', () {
      final ReaderConfig c = ReaderConfig();
      final double base = c.fontSize;
      c.increaseFont();
      expect(c.fontSize, base + 1);
      c.decreaseFont();
      expect(c.fontSize, base);
    });

    test('到上限后不再增大，且不通知监听者', () {
      final ReaderConfig c = ReaderConfig();
      int notified = 0;
      c.addListener(() => notified++);
      while (c.fontSize < ReaderConfig.maxFontSize) {
        c.increaseFont();
      }
      final int atMax = notified;
      c.increaseFont();
      expect(c.fontSize, ReaderConfig.maxFontSize);
      expect(notified, atMax, reason: '已在上限，不应再发通知');
    });

    test('到下限后不再减小', () {
      final ReaderConfig c = ReaderConfig();
      while (c.fontSize > ReaderConfig.minFontSize) {
        c.decreaseFont();
      }
      c.decreaseFont();
      expect(c.fontSize, ReaderConfig.minFontSize);
    });
  });

  group('行距 / 段距 / 亮度：越界值被钳制', () {
    test('行距钳到 [min, max]', () {
      final ReaderConfig c = ReaderConfig()..setLineHeight(999);
      expect(c.lineHeight, ReaderConfig.maxLineHeight);
      c.setLineHeight(-1);
      expect(c.lineHeight, ReaderConfig.minLineHeight);
    });

    test('段距钳到 [0, 32]', () {
      final ReaderConfig c = ReaderConfig()..setParagraphSpacing(999);
      expect(c.paragraphSpacing, 32);
      c.setParagraphSpacing(-5);
      expect(c.paragraphSpacing, 0);
    });

    test('亮度蒙层钳到 [0, 0.7]', () {
      final ReaderConfig c = ReaderConfig()..setDimLevel(1);
      expect(c.dimLevel, 0.7);
      c.setDimLevel(-1);
      expect(c.dimLevel, 0);
    });
  });

  group('首行缩进', () {
    test('缩进串长度随字符数变化', () {
      final ReaderConfig c = ReaderConfig()..setFirstLineIndent(2);
      expect(c.indent.length, 2);
      c.setFirstLineIndent(0);
      expect(c.indent, isEmpty);
    });

    test('钳到 [0, 4]', () {
      final ReaderConfig c = ReaderConfig()..setFirstLineIndent(99);
      expect(c.firstLineIndent, 4);
      c.setFirstLineIndent(-3);
      expect(c.firstLineIndent, 0);
    });

    test('设为相同值不发通知', () {
      final ReaderConfig c = ReaderConfig()..setFirstLineIndent(2);
      int notified = 0;
      c.addListener(() => notified++);
      c.setFirstLineIndent(2);
      expect(notified, 0);
    });
  });

  group('两端对齐', () {
    test('切换后 textAlign 随之变化', () {
      final ReaderConfig c = ReaderConfig()..setJustify(true);
      expect(c.textAlign, TextAlign.justify);
      c.setJustify(false);
      expect(c.textAlign, TextAlign.start);
    });

    test('设为相同值不发通知', () {
      final ReaderConfig c = ReaderConfig()..setJustify(true);
      int notified = 0;
      c.addListener(() => notified++);
      c.setJustify(true);
      expect(notified, 0);
    });
  });

  group('主题 / 翻页方式 / 字体', () {
    test('切主题生效，重复设同一主题不发通知', () {
      final ReaderConfig c = ReaderConfig()..setTheme(ReaderTheme.night);
      expect(c.theme.alias, 'night');
      int notified = 0;
      c.addListener(() => notified++);
      c.setTheme(ReaderTheme.night);
      expect(notified, 0);
    });

    test('切翻页方式生效，重复设不发通知', () {
      final ReaderConfig c = ReaderConfig()..setFlipType(FlipType.cover);
      expect(c.flipType, FlipType.cover);
      int notified = 0;
      c.addListener(() => notified++);
      c.setFlipType(FlipType.cover);
      expect(notified, 0);
    });

    test('设字体族生效，设为 null 恢复系统默认', () {
      final ReaderConfig c = ReaderConfig()..setFontFamily('Songti SC');
      expect(c.fontFamily, 'Songti SC');
      expect(c.textStyle.fontFamily, 'Songti SC');
      c.setFontFamily(null);
      expect(c.fontFamily, isNull);
    });
  });

  group('样式缓存（性能优化不得改变语义）', () {
    test('设置未变时重复取到同一实例', () {
      final ReaderConfig c = ReaderConfig();
      expect(c.textStyle, same(c.textStyle));
      expect(c.strut, same(c.strut));
      expect(c.headingStyle, same(c.headingStyle));
      expect(c.indent, same(c.indent));
    });

    test('改字号后各样式都跟着更新', () {
      final ReaderConfig c = ReaderConfig();
      final TextStyle before = c.textStyle;
      final TextStyle headingBefore = c.headingStyle;
      c.increaseFont();
      expect(c.textStyle, isNot(same(before)));
      expect(c.textStyle.fontSize, c.fontSize);
      expect(c.headingStyle, isNot(same(headingBefore)));
      expect(c.headingStyle.fontSize, c.fontSize + 6);
    });

    test('改行距后正文样式与 strut 同步', () {
      final ReaderConfig c = ReaderConfig()..setLineHeight(1.5);
      expect(c.textStyle.height, 1.5);
      expect(c.strut.height, 1.5);
      c.setLineHeight(2.0);
      expect(c.textStyle.height, 2.0);
      expect(c.strut.height, 2.0);
    });

    test('改主题后正文色跟着更新', () {
      final ReaderConfig c = ReaderConfig()..setTheme(ReaderTheme.white);
      final Color before = c.textStyle.color!;
      c.setTheme(ReaderTheme.night);
      expect(c.textStyle.color, isNot(before));
      expect(c.textStyle.color, ReaderTheme.night.textColor);
    });

    test('改缩进字符数后缩进串同步', () {
      final ReaderConfig c = ReaderConfig()..setFirstLineIndent(2);
      expect(c.indent.length, 2);
      c.setFirstLineIndent(4);
      expect(c.indent.length, 4);
    });

    test('改字体族后 strut 同步', () {
      final ReaderConfig c = ReaderConfig()..setFontFamily('A');
      expect(c.strut.fontFamily, 'A');
      c.setFontFamily('B');
      expect(c.strut.fontFamily, 'B');
    });
  });

  group('FlipType', () {
    test('isHorizontalPaged 只对平移 / 覆盖 / 仿真为真', () {
      expect(FlipType.slideHorizontal.isHorizontalPaged, isTrue);
      expect(FlipType.cover.isHorizontalPaged, isTrue);
      expect(FlipType.simulation.isHorizontalPaged, isTrue);
      expect(FlipType.scrollVertical.isHorizontalPaged, isFalse);
      expect(FlipType.none.isHorizontalPaged, isFalse);
    });

    test('共 5 种，每种都有标签与图标', () {
      expect(FlipType.values, hasLength(5));
      for (final FlipType f in FlipType.values) {
        expect(f.label, isNotEmpty);
        expect(f.icon, isA<IconData>());
      }
    });
  });

  test('每个实例独立，互不影响（禁止共享可变状态）', () {
    final ReaderConfig a = ReaderConfig()..setLineHeight(1.3);
    final ReaderConfig b = ReaderConfig()..setLineHeight(2.1);
    expect(a.lineHeight, 1.3);
    expect(b.lineHeight, 2.1);
  });
}
