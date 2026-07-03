import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app_theme.dart';
import 'pages/home_page.dart';
import 'services/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  final themeProvider = ThemeProvider();
  await themeProvider.loadPassword();
  runApp(DiaryApp(themeProvider: themeProvider));
}

class DiaryApp extends StatelessWidget {
  final ThemeProvider themeProvider;

  const DiaryApp({super.key, required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeProvider,
      builder: (ctx, _) => MaterialApp(
        title: 'Diary',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeProvider.mode,
        home: HomePage(themeProvider: themeProvider),
      ),
    );
  }
}