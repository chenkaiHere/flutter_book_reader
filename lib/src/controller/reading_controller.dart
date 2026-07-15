import '../progress/reader_progress_store.dart';
import '../reader_config.dart';
import '../source/book_source.dart';
import 'chapter_content_mixin.dart';
import 'chapter_navigation_mixin.dart';
import 'pagination_mixin.dart';
import 'reader_controller_base.dart';
import 'vertical_flow_mixin.dart';

/// 阅读控制器：组合内容加载、分页、翻页、纵向流四项能力（混入），
/// 是阅读器的单一逻辑核心，不含任何 Widget，便于独立单测。
class ReadingController extends ReaderControllerBase
    with
        ChapterContentMixin,
        PaginationMixin,
        ChapterNavigationMixin,
        VerticalFlowMixin {
  ReadingController({
    required BookSource source,
    required BookManifest manifest,
    ReaderConfig? config,
    int startChapter = 0,
    int startCharOffset = 0,
  }) : _source = source,
       _manifest = manifest,
       _config = config ?? ReaderConfig.instance {
    chapterIndex = startChapter.clamp(0, manifest.chapterCount - 1);
    charOffset = startCharOffset;
    flowChapters = <int>[chapterIndex];
    _config.addListener(_onConfigChanged);
    prefetchAround(chapterIndex);
  }

  final BookSource _source;
  final BookManifest _manifest;
  final ReaderConfig _config;

  @override
  BookSource get source => _source;

  @override
  BookManifest get manifest => _manifest;

  @override
  ReaderConfig get config => _config;

  /// 当前阅读位置快照，供进度存储保存。
  ReadingPosition get position =>
      ReadingPosition(chapterIndex: chapterIndex, charOffset: charOffset);

  void _onConfigChanged() {
    clearPageCache();
    signature = '';
    notifyListeners();
  }

  @override
  void dispose() {
    _config.removeListener(_onConfigChanged);
    super.dispose();
  }
}
