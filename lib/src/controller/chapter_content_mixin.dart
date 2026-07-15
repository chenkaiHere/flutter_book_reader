import '../paginator.dart';
import 'reader_controller_base.dart';

/// 章节正文的按需加载、缓存与错误处理能力。
///
/// 正文通过 [ReaderControllerBase.source] 异步拉取并缓存；分页结果按
/// 「区域+章节」缓存。缓存有上限，会淘汰离当前章最远的章节以控制内存。
mixin ChapterContentMixin on ReaderControllerBase {
  /// 正文 / 分页缓存保留的最大章节数（超出后按距当前章的远近淘汰）。
  static const int maxCachedChapters = 12;

  final Map<int, String> _bodies = <int, String>{};
  final Set<int> _loading = <int>{};
  final Set<int> _errors = <int>{};
  final Map<String, List<ReaderPage>> _pageCache = <String, List<ReaderPage>>{};

  /// 已加载的正文（未加载返回 null）。
  String? bodyOf(int index) => _bodies[index];

  bool isLoaded(int index) => _bodies.containsKey(index);
  bool isLoading(int index) => _loading.contains(index);

  /// 该章上次加载是否失败（可据此显示错误态并提供重试）。
  bool hasError(int index) => _errors.contains(index);

  Map<String, List<ReaderPage>> get pageCache => _pageCache;

  void clearPageCache() => _pageCache.clear();

  /// 确保某章正文已加载；完成或失败后通知刷新。
  Future<void> ensureLoaded(int index) async {
    if (index < 0 ||
        index >= chapterCount ||
        _bodies.containsKey(index) ||
        _loading.contains(index)) {
      return;
    }
    _loading.add(index);
    _errors.remove(index);
    try {
      _bodies[index] = await source.loadChapterBody(index);
      _evictIfNeeded();
      notifyListeners();
    } catch (_) {
      _errors.add(index);
      notifyListeners();
    } finally {
      _loading.remove(index);
    }
  }

  /// 重试加载失败的章节。
  Future<void> retry(int index) {
    _errors.remove(index);
    return ensureLoaded(index);
  }

  /// 预取当前章及其相邻章，保证翻页/边界页顺滑。
  void prefetchAround(int index) {
    ensureLoaded(index);
    ensureLoaded(index - 1);
    ensureLoaded(index + 1);
  }

  /// 淘汰离当前章最远、且不在保护集内的缓存。
  void _evictIfNeeded() {
    if (_bodies.length <= maxCachedChapters) return;
    final Set<int> protectedIdx = <int>{
      chapterIndex - 1,
      chapterIndex,
      chapterIndex + 1,
      ...flowChapters,
    };
    final List<int> candidates =
        _bodies.keys.where((int k) => !protectedIdx.contains(k)).toList()..sort(
          (int a, int b) =>
              (b - chapterIndex).abs().compareTo((a - chapterIndex).abs()),
        );
    for (final int k in candidates) {
      if (_bodies.length <= maxCachedChapters) break;
      _bodies.remove(k);
      _pageCache.removeWhere((String key, _) => key.endsWith('|$k'));
    }
  }
}
