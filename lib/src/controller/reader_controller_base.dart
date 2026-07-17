import 'package:flutter/widgets.dart';

import '../paginator.dart';
import '../reader_config.dart';
import '../source/book_source.dart';

/// 阅读控制器基类：集中承载可变状态与依赖，供各能力混入读写。
///
/// 具体行为（内容加载、分页、翻页、纵向流）以混入形式附加，见 controller/ 下各文件。
abstract class ReaderControllerBase extends ChangeNotifier {
  /// 数据源（由具体控制器提供）
  BookSource get source;

  /// 书籍清单（元信息 + 目录）
  BookManifest get manifest;

  /// 阅读设置
  ReaderConfig get config;

  // —— 共享可变状态 ——
  int chapterIndex = 0;
  int pageIndex = 0;

  /// 当前页在整章正文中的起始字符偏移（换字号后据此恢复位置）
  int charOffset = 0;

  /// 由上一章向前翻入时需定位到最后一页
  bool pendingAtEnd = false;

  /// 当前章分页结果（每页为若干文本块）
  List<ReaderPage> pages = <ReaderPage>[];

  /// 纵向连续滚动流中已装入的章节序号（升序、连续）
  List<int> flowChapters = <int>[];

  Size contentSize = Size.zero;
  TextScaler textScaler = TextScaler.noScaling;

  /// 实际渲染时解析出的正文 / 标题样式（含主题字体、字体回退）与地区。
  /// 分页度量必须与之完全一致，否则换行行数不同会导致末行被裁切。
  /// 为空时回退到 [config] 的样式（例如纯逻辑测试直接调用分页器时）。
  TextStyle? paintTextStyle;
  TextStyle? paintHeadingStyle;
  Locale? locale;

  /// 上次分页的签名（区域+字号+行距+章节），变化时才重排
  String signature = '';

  // —— 目录派生 ——
  int get chapterCount => manifest.chapterCount;
  String chapterTitleAt(int index) => manifest.chapterTitles[index];
  String get currentChapterTitle => chapterTitleAt(chapterIndex);

  bool get hasPrev => chapterIndex > 0;
  bool get hasNext => chapterIndex < chapterCount - 1;

  /// 横向翻页时本章正文页之前的边界页数量（有上一章则为 1）
  int get leading => hasPrev ? 1 : 0;
}
