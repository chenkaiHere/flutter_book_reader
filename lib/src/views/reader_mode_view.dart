import 'package:flutter/material.dart';

import '../controller/reading_controller.dart';
import '../reader_config.dart';
import '../reader_theme.dart';

/// 阅读模式视图基类：横向翻页、纵向滚动等具体模式继承它，
/// 共享对控制器 / 设置 / 主题 / 内边距的访问。
abstract class ReaderModeView extends StatefulWidget {
  const ReaderModeView({super.key, required this.controller});

  final ReadingController controller;
}

/// 各模式视图 State 的基类，收敛公共访问器，减少样板。
abstract class ReaderModeViewState<W extends ReaderModeView> extends State<W> {
  ReadingController get controller => widget.controller;
  ReaderConfig get config => controller.config;
  ReaderTheme get theme => controller.config.theme;
  EdgeInsets get pagePadding => kReaderPagePadding;
}
