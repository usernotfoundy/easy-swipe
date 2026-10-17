import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0F172A),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const EasySwipeApp());
}

class EasySwipeApp extends StatelessWidget {
  const EasySwipeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EasySwipe',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6366F1),
          secondary: Color(0xFFEC4899),
          surface: Color(0xFF1E293B),
          error: Color(0xFFF43F5E),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E293B),
          elevation: 0,
          centerTitle: false,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
