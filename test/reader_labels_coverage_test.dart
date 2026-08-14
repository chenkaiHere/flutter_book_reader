import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 内置语言预设的「文案覆盖度」守卫。
///
/// [ReaderLabels] 未提供的字段会静默回退英文默认值——这会导致某种语言的界面出现
/// 大段英文而不报任何错。本测试直接解析源码，比对构造器字段与每个预设实际设置的
/// 字段：新增文案若只改了 en/zh，这里会立刻失败并列出缺失项。
void main() {
  /// 内置的非英文预设（english 即默认值，天然全覆盖）。
  const List<String> presets = <String>[
    'chinese',
    'spanish',
    'french',
    'arabic',
    'bengali',
    'portuguese',
    'russian',
    'hindi',
    'urdu',
    'japanese',
    'korean',
  ];

  test('每个内置语言预设都覆盖全部文案（新增 key 不能只改 en/zh）', () {
    final String src = File('lib/src/reader_labels.dart').readAsStringSync();

    // 构造器里声明的全部文案字段：`    this.xxx = ...`
    final Set<String> allKeys =
        RegExp(r'^ {4}this\.([a-zA-Z]+)', multiLine: true)
            .allMatches(src)
            .map((RegExpMatch m) => m.group(1)!)
            .toSet();
    expect(allKeys.length, greaterThan(50), reason: '未能解析出文案字段，测试的解析规则可能已失效');

    for (final String preset in presets) {
      final String block = _presetBlock(src, preset);
      final Set<String> keys = RegExp(r'^ {4}([a-zA-Z]+):', multiLine: true)
          .allMatches(block)
          .map((RegExpMatch m) => m.group(1)!)
          .toSet();
      final Set<String> missing = allKeys.difference(keys);
      expect(missing, isEmpty,
          reason: '$preset 预设缺少 ${missing.length} 个文案，会回退英文：$missing');
    }
  });
}

/// 截取某个预设的定义块（`static const ReaderLabels <name> = ReaderLabels(` 到 `);`）。
String _presetBlock(String src, String name) {
  final int start =
      src.indexOf('static const ReaderLabels $name = ReaderLabels(');
  expect(start, isNot(-1), reason: '找不到 $name 预设');
  final int end = src.indexOf('\n  );', start);
  expect(end, isNot(-1), reason: '$name 预设未正常结束');
  return src.substring(start, end);
}
