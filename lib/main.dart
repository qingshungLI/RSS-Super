
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rss_reader/database/database_helper.dart';
import 'package:rss_reader/models/article.dart';
import 'package:rss_reader/models/folder.dart';
import 'package:rss_reader/models/rss_feed.dart';
import 'package:rss_reader/models/video.dart';
import 'package:rss_reader/models/note.dart';
import 'package:rss_reader/services/rss_service.dart';
import 'package:rss_reader/providers/app_state_provider.dart';
import 'package:rss_reader/providers/theme_provider.dart';
import 'package:rss_reader/pages/home_page.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 确保数据库已初始化
  await DatabaseHelper.instance.database; 
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AppStateProvider()),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'RSS Super',
          debugShowCheckedModeBanner: false,
          themeMode: themeProvider.themeMode,
          theme: themeProvider.getLightTheme(),
          darkTheme: themeProvider.getDarkTheme(),
          home: HomePage(),
        );
      },
    );
  }
}

