import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_book_reader/flutter_book_reader.dart';
import 'package:flutter_book_reader/src/paginator.dart';
import 'package:flutter_book_reader/src/reader_config.dart';
import 'package:flutter_book_reader/src/widgets/page_frame.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final String fontPath in <String>[
    '/System/Library/Fonts/Hiragino Sans GB.ttc',
    '/System/Library/Fonts/STHeiti Light.ttc',
  ]) {
    testWidgets('font=$fontPath', (WidgetTester tester) async {
      const Size screen = Size(390, 844);
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      bool loaded = true;
      await tester.runAsync(() async {
        try {
          final Uint8List b = File(fontPath).readAsBytesSync();
          final FontLoader l = FontLoader('CJK')
            ..addFont(Future<ByteData>.value(ByteData.view(b.buffer)));
          await l.load();
        } catch (e) {
          loaded = false;
        }
      });
      if (!loaded) {
        // ignore: avoid_print
        print('$fontPath: load failed');
        return;
      }

      final Map<String, dynamic> book = json.decode(
        File('example/assets/sanguo.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final RegExp lead = RegExp(r'^[　\s]+');
      final List<String> paras =
          ((book['chapters'] as List<dynamic>)[0] as Map<String, dynamic>)[
                  'paragraphs']
              .cast<String>()
              .map<String>((String p) => p.replaceFirst(lead, ''))
              .toList();

      final double box = screen.height -
          kReaderPagePadding.vertical -
          kReaderHeaderHeight -
          kReaderFooterHeight;

      int over = 0, total = 0;
      for (final double fs in <double>[16, 19, 22]) {
        final ReaderConfig config = ReaderConfig()..setFontFamily('CJK');
        while (config.fontSize > fs) {
          config.decreaseFont();
        }
        final Size content = Size(
          screen.width - kReaderPagePadding.horizontal,
          screen.height -
              kReaderPagePadding.vertical -
              kReaderHeaderHeight -
              kReaderFooterHeight -
              kReaderContentSafety,
        );
        final List<ReaderPage> pages = Paginator.paginate(
          paragraphs: paras,
          style: config.textStyle,
          size: content,
          indent: config.indent,
          paragraphSpacing: config.paragraphSpacing,
          textAlign: config.textAlign,
          strutStyle: config.strut,
        );
        for (int i = 0; i < pages.length; i++) {
          total++;
          final GlobalKey k = GlobalKey();
          await tester.pumpWidget(
            MediaQuery(
              data: const MediaQueryData(size: screen),
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Align(
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    width: content.width,
                    child: KeyedSubtree(
                      key: k,
                      child: ReaderProse(page: pages[i], config: config),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final double h = tester.getSize(find.byKey(k)).height;
          if (h > box + 0.5) {
            over++;
            // ignore: avoid_print
            print('  CLIP fs=$fs page=$i natural=${h.toStringAsFixed(1)} > box=$box');
          }
        }
      }
      // ignore: avoid_print
      print('$fontPath => CLIP $over / $total');
    });
  }
}
