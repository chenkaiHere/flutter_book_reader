import 'package:file_picker/file_picker.dart';
import 'package:flutter_book_reader/flutter_book_reader.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/book.dart';
import 'data/shared_prefs_bookmark_store.dart';
import 'import/imported_book_store.dart';
import 'widgets/book_card.dart';

/// 书架 / 书城入口页：内置书（JSON 资源）+ 用户导入的 txt（落库到内部存储）。
class BookshelfPage extends StatefulWidget {
  const BookshelfPage({super.key});

  @override
  State<BookshelfPage> createState() => _BookshelfPageState();
}

/// 书架条目：书 + 是否为导入书（决定用哪种数据源）。
class _Shelf {
  const _Shelf(this.book, this.imported);
  final Book book;
  final bool imported;
}

class _BookshelfPageState extends State<BookshelfPage> {
  /// 书架级别共享的进度存储，让各书的阅读位置在会话内被记住
  final ReaderProgressStore _progressStore = InMemoryReaderProgressStore();

  /// 书签持久化：由 App 侧自行实现（SharedPreferences），插件不含持久化。
  final ReaderBookmarkStore _bookmarkStore = SharedPrefsBookmarkStore();

  /// 导入书落库管理（内部存储）。
  final ImportedBookStore _importStore = ImportedBookStore();

  /// 首次点击「导入」按钮时展示功能介绍，用此 key 记住是否已展示过。
  static const String _kImportIntroShownKey = 'import_intro_shown';

  final List<_Shelf> _books = <_Shelf>[];
  bool _loading = true;
  Object? _error;
  bool _importing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // 先展示内置书（必成功），转圈随即消失。
    List<Book> builtin;
    try {
      builtin = await BookRepository.load();
    } catch (e) {
      if (mounted) setState(() => _error = e);
      return;
    }
    if (!mounted) return;
    setState(() {
      _books
        ..clear()
        ..addAll(builtin.map((Book b) => _Shelf(b, false)));
      _loading = false;
    });

    // 再尽力加载导入书（依赖 path_provider，失败/不可用则忽略，不影响内置书）。
    try {
      final List<Book> imported = await _importStore.listImported();
      if (!mounted) return;
      setState(() {
        _books
          ..removeWhere((_Shelf e) => e.imported)
          ..insertAll(0, imported.map((Book b) => _Shelf(b, true)));
      });
    } catch (_) {
      // 忽略：内置书已展示
    }
  }

  /// 点击「导入」按钮：首次先弹功能介绍，之后直接进入文件选择。
  Future<void> _onImportPressed() async {
    if (_importing) return;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool shown = prefs.getBool(_kImportIntroShownKey) ?? false;
    if (!shown) {
      if (!mounted) return;
      final bool proceed = await _showImportIntro();
      await prefs.setBool(_kImportIntroShownKey, true); // 只在首次展示
      if (!proceed) return; // 用户在介绍里选择「暂不导入」
    }
    await _importTxt();
  }

  /// 功能介绍弹窗。返回 true 表示用户选择继续导入。
  Future<bool> _showImportIntro() async {
    final bool? r = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Row(
          children: <Widget>[
            Icon(Icons.auto_stories_outlined, color: Colors.indigo),
            SizedBox(width: 8),
            Text('导入本地小说'),
          ],
        ),
        content: const Text(
          '把手机里的 TXT 小说加入书架，随时离线畅读。\n\n'
          '• 一键导入：选择本地 TXT 文件即可，无需联网\n'
          '• 智能排版：自动识别书名、作者与章节，并完成分段缩进\n'
          '• 编码无忧：自动检测 UTF-8 / GBK / Big5 等常见编码，中文不再乱码\n'
          '• 随存随删：导入的书保存在本机，左滑即可删除\n\n'
          '现在挑一本喜欢的小说开始吧！',
          style: TextStyle(height: 1.6),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('暂不导入'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('选择 TXT 文件'),
          ),
        ],
      ),
    );
    return r ?? false;
  }

  Future<void> _importTxt() async {
    if (_importing) return;
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final FilePickerResult? res = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: <String>['txt'],
      withData: kIsWeb, // Web 无文件路径，需取字节
    );
    if (res == null || res.files.isEmpty) return; // 用户取消
    final PlatformFile f = res.files.single;

    setState(() => _importing = true);
    try {
      final Book book;
      if (f.path != null) {
        book = await _importStore.importTxt(f.path!); // 原生：走文件路径
      } else if (f.bytes != null) {
        book = await _importStore.importBytes(
          f.bytes!,
          fileName: f.name,
        ); // Web
      } else {
        throw StateError('无法读取所选文件');
      }
      if (!mounted) return;
      setState(() {
        // 重复导入同一文件会得到相同 id，去重后置顶
        _books.removeWhere((_Shelf e) => e.book.id == book.id);
        _books.insert(0, _Shelf(book, true));
        _importing = false;
      });
      messenger.showSnackBar(
        SnackBar(content: Text('已导入《${book.title}》，共 ${book.chapterCount} 章')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _importing = false);
      messenger.showSnackBar(SnackBar(content: Text('导入失败：$e')));
    }
  }

  /// 左滑删除的处理：内置书提示无法删除；导入书确认后删除并清除内部存储。
  Future<void> _onDelete(_Shelf shelf) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    if (!shelf.imported) {
      messenger.showSnackBar(const SnackBar(content: Text('内置书籍无法删除')));
      return;
    }
    final bool confirmed =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext ctx) => AlertDialog(
            title: const Text('删除书籍'),
            content: Text('确定删除《${shelf.book.title}》吗？此操作将移除已导入的书籍数据。'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('删除', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    try {
      await _importStore.deleteImported(shelf.book.id); // 清除内部存储的 JSON
      if (!mounted) return;
      setState(
        () => _books.removeWhere((_Shelf e) => e.book.id == shelf.book.id),
      );
      messenger.showSnackBar(
        SnackBar(content: Text('已删除《${shelf.book.title}》')),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('删除失败：$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('书架'),
        centerTitle: false,
        actions: <Widget>[
          IconButton(
            tooltip: '导入 TXT',
            icon: _importing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.upload_file),
            onPressed: _importing ? null : _onImportPressed,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(child: Text('书籍加载失败：$_error'));
    }
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_books.isEmpty) {
      return const Center(child: Text('暂无书籍，点击右上角导入 TXT'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _books.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (_, int i) {
        final _Shelf shelf = _books[i];
        return Slidable(
          key: ValueKey<int>(shelf.book.id),
          endActionPane: ActionPane(
            motion: const DrawerMotion(),
            extentRatio: 0.28,
            children: <Widget>[
              SlidableAction(
                onPressed: (_) => _onDelete(shelf),
                // 内置书用灰色锁形（不可删），导入书用红色删除。
                backgroundColor: shelf.imported
                    ? Colors.red
                    : Colors.grey.shade500,
                foregroundColor: Colors.white,
                icon: shelf.imported ? Icons.delete : Icons.lock_outline,
                label: shelf.imported ? '删除' : '内置',
                borderRadius: BorderRadius.circular(12),
              ),
            ],
          ),
          child: BookCard(
            book: shelf.book,
            imported: shelf.imported,
            progressStore: _progressStore,
            bookmarkStore: _bookmarkStore,
          ),
        );
      },
    );
  }
}
