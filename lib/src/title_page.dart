import 'package:flutter/widgets.dart';

import 'reader_theme.dart';

/// 扉页构建器：小说第一章正文之前那一页「宣传页」的样式**完全由业务方定义**。
///
/// 传给 `BookReader(titlePageBuilder: ...)`；传 `null`（默认）则不加扉页。
///
/// 阅读器只负责把扉页作为翻页流里的真实一页接入（位置、来回翻、可唤起菜单），
/// 具体长什么样由这里返回的 Widget 决定。回调会带上当前 [ReaderTheme]，便于业务方
/// 贴合日/夜主题（纸张色、字色、强调色）。书籍信息可由业务方自行闭包传入。
typedef ReaderTitlePageBuilder = Widget Function(
  BuildContext context,
  ReaderTheme theme,
);
