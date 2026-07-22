/// book_reader —— 可商用的 Flutter 小说阅读器组件。
///
/// 只依赖抽象 [BookSource] 与 [ReaderProgressStore]，业务方实现自己的数据源 /
/// 进度存储即可接入（网络、数据库、云同步…），无需改动组件内部。
///
/// ```dart
/// BookReader(
///   source: MyHttpBookSource(bookId),
///   progressStore: MyProgressStore(),
///   onChapterChanged: (i) => track(i),
/// )
/// ```
library;

export 'src/book_reader_controller.dart';
export 'src/book_reader_widget.dart';
export 'src/bookmark/reader_bookmark_store.dart';
export 'src/comment/reader_comment_store.dart';
export 'src/paginator.dart' show Paginator;
export 'src/progress/reader_progress_store.dart';
export 'src/reader_config.dart' show ReaderConfig, FlipType;
export 'src/reader_labels.dart' show ReaderLabels;
export 'src/reader_theme.dart';
export 'src/source/book_source.dart';
// 只导出业务方需要的公开类型；InheritedWidget 作用域是插件内部管道，不对外。
export 'src/text_actions.dart'
    show
        ReaderTextAction,
        ReaderSelection,
        ReaderTextActionCallback,
        ReaderSegmentTap,
        ReaderSegmentTapCallback;
export 'src/underline/reader_underline_store.dart';
