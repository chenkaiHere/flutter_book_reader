import 'package:flutter/material.dart';

import 'bookshelf_page.dart';

void main() {
  runApp(const ReadBookApp());
}

class ReadBookApp extends StatelessWidget {
  const ReadBookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ReadBook 阅读器',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE0662B)),
        useMaterial3: true,
      ),
      home: const BookshelfPage(),
    );
  }
}
