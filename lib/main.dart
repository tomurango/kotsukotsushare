import 'package:flutter/material.dart';
import 'package:material_color_utilities/material_color_utilities.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'firebase_options.dart';
import 'src/auth_wrapper.dart';

void main() async {
  // 基本カラーをTeal色 (#008080) に設定
  final int primaryColor = 0xFF008080;
  final CorePalette corePalette = CorePalette.of(primaryColor);

  // CorePaletteからカラーシェーマを生成
  final ColorScheme lightColorScheme = ColorScheme.fromSeed(
    seedColor: Color(primaryColor),
    brightness: Brightness.light,
  );
  final ColorScheme darkColorScheme = ColorScheme.fromSeed(
    seedColor: Color(primaryColor),
    brightness: Brightness.dark,
  );

  // 必要なバインディングを初期化
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(ProviderScope(
    child: MyApp(
      lightScheme: lightColorScheme,
      darkScheme: darkColorScheme,
    ),
  ));
}

class MyApp extends StatelessWidget {
  final ColorScheme lightScheme;
  final ColorScheme darkScheme;

  const MyApp({super.key, required this.lightScheme, required this.darkScheme});

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.of(context).platformBrightness;

    // テーマ定義時に直接Googleフォントを適用
    final ThemeData lightTheme = ThemeData(
      colorScheme: lightScheme,
      textTheme: GoogleFonts.zenKakuGothicNewTextTheme(
        Theme.of(context).textTheme,
      ),
      useMaterial3: true,
    );

    final ThemeData darkTheme = ThemeData(
      colorScheme: darkScheme,
      textTheme: GoogleFonts.zenKakuGothicNewTextTheme(
        Theme.of(context).textTheme,
      ),
      useMaterial3: true,
    );

    return MaterialApp(
      title: 'Chokushii',
      theme: lightTheme, // ライトテーマを適用
      darkTheme: darkTheme, // ダークテーマを適用
      home: AuthWrapper(),
    );
  }
}
