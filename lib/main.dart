import 'package:apusion/ui/auth/view_model/auth_view_model.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app.dart';
import 'package:provider/provider.dart';
import 'package:flutter_line_sdk/flutter_line_sdk.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ); // Firebaseの初期化
  LineSDK.instance.setup("YOUR_CHANNEL_ID").then((_) {
    print("LineSDK is ready");
  });
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthViewModel(),
      child: const MyApp(),
    ),
  );
}
