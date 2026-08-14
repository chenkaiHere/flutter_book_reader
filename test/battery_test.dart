import 'package:flutter_book_reader/flutter_book_reader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReaderBatteryInfo 相等性', () {
    test('同电量同充电态视为相等', () {
      expect(
        const ReaderBatteryInfo(level: 80, charging: false),
        const ReaderBatteryInfo(level: 80, charging: false),
      );
    });

    test('电量不同则不相等', () {
      expect(
        const ReaderBatteryInfo(level: 80, charging: false),
        isNot(const ReaderBatteryInfo(level: 81, charging: false)),
      );
    });

    test('充电态不同则不相等', () {
      expect(
        const ReaderBatteryInfo(level: 80, charging: false),
        isNot(const ReaderBatteryInfo(level: 80, charging: true)),
      );
    });

    test('相等实例的 hashCode 一致（可安全用于 Set / Map 键）', () {
      const ReaderBatteryInfo a = ReaderBatteryInfo(level: 55, charging: true);
      // 用运行期数值构造，避免 const 规范化后两者是同一实例、测不出 hashCode 语义
      final ReaderBatteryInfo b =
          ReaderBatteryInfo(level: int.parse('55'), charging: true);
      expect(a.hashCode, b.hashCode);
      expect(<ReaderBatteryInfo>{a, b}, hasLength(1), reason: '相等实例只占一个槽位');
    });

    test('与其他类型比较返回 false', () {
      expect(
        const ReaderBatteryInfo(level: 1, charging: false) == Object(),
        isFalse,
      );
    });
  });
}
