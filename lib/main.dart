import 'package:apusion/ui/auth/view_model/auth_view_model.dart'; // 以前のビュー・モデルを引き継ぐ
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Firebaseの初期化
import 'firebase_options.dart'; // Firebaseの設定（自動生成されたもの）
import 'app.dart'; // アプリ全体のウィジェットを引き継ぐ
import 'package:provider/provider.dart'; // Providerの利用

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebaseの初期化
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // Firebaseの設定ファイルから自動的にプラットフォームごとの設定をロード
  );

  runApp(
    // Providerで`AuthViewModel`を管理
    ChangeNotifierProvider(
      create: (_) => AuthViewModel(),
      child: const MyApp(), // アプリケーション本体
    ),
  );
}
