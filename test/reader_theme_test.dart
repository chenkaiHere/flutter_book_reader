import 'package:flutter/material.dart';
import 'package:flutter_book_reader/flutter_book_reader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('内置预设', () {
    test('共 6 套，alias 互不重复', () {
      expect(ReaderTheme.presets, hasLength(6));
      final Set<String> aliases =
          ReaderTheme.presets.map((ReaderTheme t) => t.alias).toSet();
      expect(aliases, hasLength(6));
    });

    test('只有「夜」是深色主题', () {
      final List<ReaderTheme> dark =
          ReaderTheme.presets.where((ReaderTheme t) => t.isDark).toList();
      expect(dark, hasLength(1));
      expect(dark.single.alias, 'night');
    });

    test('每套都提供了非空的 name 与配色', () {
      for (final ReaderTheme t in ReaderTheme.presets) {
        expect(t.name, isNotEmpty, reason: '${t.alias} 缺 name');
        expect(t.paperColor.a, 1.0, reason: '${t.alias} 纸张色必须不透明');
      }
    });
  });

  group('ReaderTheme.fromAlias', () {
    test('命中时返回对应预设', () {
      expect(ReaderTheme.fromAlias('night').alias, 'night');
      expect(ReaderTheme.fromAlias('white').alias, 'white');
    });

    test('未命中 / null 回退到「米」色', () {
      expect(ReaderTheme.fromAlias('no-such-alias').alias, 'yellow');
      expect(ReaderTheme.fromAlias(null).alias, 'yellow');
    });
  });

  group('isDark 按纸张亮度判定', () {
    test('浅纸张为 false，深纸张为 true', () {
      const ReaderTheme light = ReaderTheme(
        alias: 'l',
        name: 'l',
        paperColor: Color(0xFFFFFFFF),
        textColor: Color(0xFF000000),
      );
      const ReaderTheme dark = ReaderTheme(
        alias: 'd',
        name: 'd',
        paperColor: Color(0xFF101010),
        textColor: Color(0xFFFFFFFF),
      );
      expect(light.isDark, isFalse);
      expect(dark.isDark, isTrue);
    });
  });

  group('派生色', () {
    const ReaderTheme t = ReaderTheme(
      alias: 't',
      name: 't',
      paperColor: Color(0xFFFFFFFF),
      textColor: Color(0xFF000000),
    );

    test('都由文字色按不同透明度派生，且深浅有序', () {
      expect(t.subTextColor.a, closeTo(0.55, 0.001));
      expect(t.borderColor.a, closeTo(0.16, 0.001));
      expect(t.trackColor.a, closeTo(0.14, 0.001));
      expect(t.dividerColor.a, closeTo(0.09, 0.001));
      // 语义上：正文 > 次要文字 > 描边 > 轨道 > 分隔线
      expect(t.subTextColor.a, greaterThan(t.borderColor.a));
      expect(t.borderColor.a, greaterThan(t.trackColor.a));
      expect(t.trackColor.a, greaterThan(t.dividerColor.a));
    });

    test('未指定 panelColor 时回退纸张色', () {
      expect(t.panelColor, t.paperColor);
    });

    test('指定 panelColor 时优先用它', () {
      final ReaderTheme custom =
          t.copyWith(panelColor: const Color(0xFF123456));
      expect(custom.panelColor, const Color(0xFF123456));
    });

    test('segActiveColor / selectionColor 在两种明暗下都能派生出不透明色', () {
      for (final ReaderTheme preset in ReaderTheme.presets) {
        expect(preset.segActiveColor.a, 1.0, reason: preset.alias);
        expect(preset.selectionColor.a, 1.0, reason: preset.alias);
      }
    });

    test('未显式配色时也能派生（覆盖 fallback 分支）', () {
      const ReaderTheme bareLight = ReaderTheme(
        alias: 'bl',
        name: 'bl',
        paperColor: Color(0xFFF0EAD6),
        textColor: Color(0xFF333333),
      );
      const ReaderTheme bareDark = ReaderTheme(
        alias: 'bd',
        name: 'bd',
        paperColor: Color(0xFF121212),
        textColor: Color(0xFFEEEEEE),
      );
      expect(bareLight.segActiveColor, isA<Color>());
      expect(bareLight.selectionColor, isA<Color>());
      expect(bareDark.segActiveColor, isA<Color>());
      expect(bareDark.selectionColor, isA<Color>());
    });
  });

  group('copyWith', () {
    test('只覆盖传入字段', () {
      final ReaderTheme changed =
          ReaderTheme.yellow.copyWith(accentColor: const Color(0xFF00FF00));
      expect(changed.accentColor, const Color(0xFF00FF00));
      expect(changed.alias, ReaderTheme.yellow.alias);
      expect(changed.paperColor, ReaderTheme.yellow.paperColor);
      expect(changed.textColor, ReaderTheme.yellow.textColor);
    });

    test('不传参数时各字段与原实例一致', () {
      final ReaderTheme copy = ReaderTheme.night.copyWith();
      expect(copy.alias, ReaderTheme.night.alias);
      expect(copy.paperColor, ReaderTheme.night.paperColor);
      expect(copy.isDark, isTrue);
    });
  });
}
