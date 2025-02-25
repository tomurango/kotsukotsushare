import 'package:flutter/material.dart';
import 'package:material_color_utilities/material_color_utilities.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'src/auth_wrapper.dart';
import 'package:flutter/foundation.dart';
// Firebase Auth のエミュレーターを使用するためのインポート
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  _initializeFirebaseFunctions(); // FirebaseFunctionsのエミュレーター設定など

  await dotenv.load(fileName: ".env");

  // RevenueCat SDK の初期化
  await Purchases.configure(
    PurchasesConfiguration(dotenv.env['REVENUECAT_PUBLIC_KEY']!),
  );

  runApp(ProviderScope(
    child: MyApp(
      lightScheme: lightColorScheme,
      darkScheme: darkColorScheme,
    ),
  ));
}

void _initializeFirebaseFunctions() {
  final functions = FirebaseFunctions.instance;

  // デバッグモードでエミュレーターを使用
  if (kDebugMode) {
    // 🔥 エミュレーターを使っている場合、Auth のエミュレーターを設定
    FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
    // 🔥 エミュレーターを使っている場合、Functions のエミュレーターを設定
    functions.useFunctionsEmulator('localhost', 5001); // エミュレーター設定
    // 🔥 エミュレーターを使っている場合、Firestore のエミュレーターを設定
    FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
  }
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
      debugShowCheckedModeBanner: false,
      title: 'Chokushii',
      theme: lightTheme, // ライトテーマを適用
      darkTheme: darkTheme, // ダークテーマを適用
      home: AuthWrapper(),
    );
  }
}
