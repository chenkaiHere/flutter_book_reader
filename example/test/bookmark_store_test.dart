import 'package:flutter_book_reader/flutter_book_reader.dart';
import 'package:flutter_book_reader_example/data/shared_prefs_bookmark_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('SharedPrefsBookmarkStore：保存后可读回，且跨实例持久', () async {
    final SharedPrefsBookmarkStore store = SharedPrefsBookmarkStore();

    expect(await store.load(7), isEmpty);

    final List<Bookmark> bms = <Bookmark>[
      const Bookmark(
        chapterIndex: 0,
        charOffset: 1836,
        chapterTitle: '第一回 宴桃园…',
        createdAt: 1752800000000,
      ),
      const Bookmark(
        chapterIndex: 3,
        charOffset: 200,
        chapterTitle: '第四回 …',
        createdAt: 1752800100000,
      ),
    ];
    await store.save(7, bms);

    // 新建一个 store 实例（模拟重启后重新读取），仍能读回
    final List<Bookmark> loaded = await SharedPrefsBookmarkStore().load(7);
    expect(loaded.length, 2);
    expect(loaded.first.chapterIndex, 0);
    expect(loaded.first.charOffset, 1836);
    expect(loaded.first.chapterTitle, '第一回 宴桃园…');
    expect(loaded.first.createdAt, 1752800000000);

    // 不同 bookId 互不影响
    expect(await store.load(8), isEmpty);

    // 覆盖保存（移除一条）
    await store.save(7, <Bookmark>[bms.first]);
    expect((await store.load(7)).length, 1);
  });
}
