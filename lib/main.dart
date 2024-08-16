import 'package:flutter/material.dart';
import 'package:material_color_utilities/material_color_utilities.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'src/auth_wrapper.dart';

void main() async{

  // 基本カラーをオレンジ色 (#FF9900) に設定
  final int primaryColor = 0xffff9900;
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

  runApp(MyApp(lightScheme: lightColorScheme, darkScheme: darkColorScheme));
}

class MyApp extends StatelessWidget {
  final ColorScheme lightScheme;
  final ColorScheme darkScheme;

  const MyApp({super.key, required this.lightScheme, required this.darkScheme});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.of(context).platformBrightness;

    // Use with Google Fonts package to use downloadable fonts
    TextTheme textTheme = GoogleFonts.robotoTextTheme();

    MaterialTheme theme = MaterialTheme(textTheme, lightScheme, darkScheme);
    return MaterialApp(
      title: 'KotsuKotsuShare',
      theme: theme.light(), // ライトテーマを適用
      darkTheme: theme.dark(), // ダークテーマを適用
      home: AuthWrapper(),
    );
  }
}

class MaterialTheme {
  final TextTheme textTheme;
  final ColorScheme lightColorScheme;
  final ColorScheme darkColorScheme;

  MaterialTheme(this.textTheme, this.lightColorScheme, this.darkColorScheme);

  ThemeData light() {
    return ThemeData(
      colorScheme: lightColorScheme,
      textTheme: textTheme,
      // Material Design 3を使用
      applyElevationOverlayColor: true,
      useMaterial3: true,
    );
  }

  ThemeData dark() {
    return ThemeData(
      colorScheme: darkColorScheme,
      textTheme: textTheme,
      // Material Design 3を使用
      applyElevationOverlayColor: true,
      useMaterial3: true,
    );
  }
}
