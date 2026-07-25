import 'package:flutter/material.dart';
import 'package:flutter_book_reader/flutter_book_reader.dart';

import '../theme/warm_theme.dart';
import 'book_cover.dart';

/// 一条书评（示例数据）。真实 App 里应来自你的后端。
class TitlePageReview {
  const TitlePageReview({
    required this.name,
    required this.text,
    required this.meta,
    this.stars = 5,
  });
  final String name;
  final String text;
  final String meta;
  final int stars;
}

/// 示例：「书籍详情扉页」——第一章正文之前的宣传页。
///
/// 样式完全在 App 侧定义，通过 `BookReader(titlePageBuilder: ...)` 传入。插件回调带当前
/// [ReaderTheme]，据此适配阅读器日/夜主题；评分 / 在读 / 书评等为示例占位数据。
class ReaderTitlePage extends StatelessWidget {
  const ReaderTitlePage({
    super.key,
    required this.theme,
    required this.title,
    required this.coverColor,
    this.author,
    this.description,
    this.tags = const <String>[],
    this.rating = '9.0',
    this.ratingCount = '2万人点评',
    this.readers = '3万人',
    this.words = '74.1万字',
    this.status = '已完结',
    this.reviews = _demoReviews,
  });

  final ReaderTheme theme;
  final String title;
  final Color coverColor;
  final String? author;
  final String? description;
  final List<String> tags;
  final String rating;
  final String ratingCount;
  final String readers;
  final String words;
  final String status;
  final List<TitlePageReview> reviews;

  static const List<TitlePageReview> _demoReviews = <TitlePageReview>[
    TitlePageReview(
      name: '书友一号',
      text: '很好看，只是书名拉胯，让人误以为是网游文……但实质上是诡秘、极道、肉身、玄幻的结合。',
      meta: '阅读10小时后点评',
    ),
    TitlePageReview(
      name: '书友二号',
      text: '作者刻画人物的功底很深厚，每个角色都有血有肉，尤其是主角杀伐果断不拖泥带水。',
      meta: '阅读10小时后点评',
    ),
    TitlePageReview(
      name: '书友三号',
      text: '好看，已看完。不圣母，没有搞什么人人平等，要为了普通人拼命。',
      meta: '阅读25小时后点评',
    ),
  ];

  Color get _ink => theme.textColor;
  Color get _sub => theme.subTextColor;
  Color get _accent => theme.accentColor;

  @override
  Widget build(BuildContext context) {
    // 扉页固定一屏、不允许滚动：整体为 Column，书评区用 Expanded 吸收剩余空间，
    // 超出部分裁剪（NeverScrollableScrollPhysics 既不滚动也不报溢出）。
    return ColoredBox(
      color: theme.paperColor,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Center(
                child: BookCover(
                  title: title,
                  color: coverColor,
                  width: 138,
                  height: 190,
                  radius: 10,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Warm.serif(size: 24, weight: FontWeight.w800, color: _ink),
              ),
              const SizedBox(height: 12),
              _authorRow(),
              const SizedBox(height: 18),
              _statsRow(),
              const SizedBox(height: 20),
              _introSection(),
              const SizedBox(height: 20),
              _reviewsHeader(),
              const SizedBox(height: 12),
              Expanded(
                child: ClipRect(
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: Column(
                      children: <Widget>[
                        for (final TitlePageReview r in reviews) ...<Widget>[
                          _reviewTile(r),
                          const SizedBox(height: 16),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _authorRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        CircleAvatar(
          radius: 12,
          backgroundColor: _accent.withValues(alpha: 0.18),
          child: Icon(Icons.person, size: 15, color: _accent),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            author ?? '',
            overflow: TextOverflow.ellipsis,
            style: Warm.sans(size: 14.5, weight: FontWeight.w600, color: _ink),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: _accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '+关注',
            style: Warm.sans(size: 12.5, weight: FontWeight.w600, color: _accent),
          ),
        ),
      ],
    );
  }

  Widget _statsRow() {
    Widget cell(String value, String label, {bool link = false}) {
      return Expanded(
        child: Column(
          children: <Widget>[
            Text(
              value,
              style: Warm.serif(size: 22, weight: FontWeight.w800, color: _ink),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Warm.sans(size: 12, color: link ? _accent : _sub),
            ),
          ],
        ),
      );
    }

    Widget divider() => Container(
          width: 1,
          height: 30,
          color: _ink.withValues(alpha: 0.10),
        );

    return Row(
      children: <Widget>[
        cell(rating, '$ratingCount ›', link: true),
        divider(),
        cell(readers, '正在阅读'),
        divider(),
        cell(words, status),
      ],
    );
  }

  Widget _introSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                '简介',
                style:
                    Warm.serif(size: 18, weight: FontWeight.w800, color: _ink),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    tags.map((String t) => _tagChip(t)).toList(growable: false),
              ),
            ),
          ],
        ),
        if (description != null && description!.trim().isNotEmpty) ...<Widget>[
          const SizedBox(height: 14),
          Text(
            description!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Warm.sans(size: 14.5, height: 1.6, color: _ink),
          ),
        ],
      ],
    );
  }

  Widget _reviewsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text('热门书评',
            style: Warm.serif(size: 18, weight: FontWeight.w800, color: _ink)),
        Text('更多书评', style: Warm.sans(size: 13, color: _accent)),
      ],
    );
  }

  Widget _reviewTile(TitlePageReview r) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        CircleAvatar(
          radius: 14,
          backgroundColor: _accent.withValues(alpha: 0.15),
          child: Icon(Icons.face_rounded, size: 16, color: _accent),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                r.text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Warm.sans(size: 14, height: 1.5, color: _ink),
              ),
              const SizedBox(height: 6),
              Row(
                children: <Widget>[
                  for (int i = 0; i < 5; i++)
                    Icon(
                      i < r.stars ? Icons.star_rounded : Icons.star_border_rounded,
                      size: 14,
                      color: const Color(0xFFF2A93B),
                    ),
                  const SizedBox(width: 8),
                  Text(r.meta, style: Warm.sans(size: 11.5, color: _sub)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tagChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
      decoration: BoxDecoration(
        color: _ink.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: Warm.sans(size: 12.5, color: _sub)),
    );
  }

  Widget _startHint() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _ink.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.chevron_left_rounded, size: 20, color: _sub),
          const SizedBox(width: 4),
          Text('左滑开始阅读',
              style: Warm.sans(size: 14, weight: FontWeight.w600, color: _ink)),
        ],
      ),
    );
  }
}
