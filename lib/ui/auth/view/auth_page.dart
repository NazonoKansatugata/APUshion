import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

// ViewModel, Model
import 'package:apusion/ui/auth/view_model/auth_view_model.dart';
import 'email_login_page.dart';
import 'email_sign_up_page.dart';
import 'package:apusion/ui/home/home_page.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ChangeNotifierProvider で AuthViewModel を提供
    return ChangeNotifierProvider(
      create: (_) => AuthViewModel(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('ログイン・サインアップ'),
        ),
        body: Consumer<AuthViewModel>(
          builder: (context, authVM, child) {
            return Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    // メールアドレスでログイン
                    Container(
                      width: 300,
                      margin: const EdgeInsets.all(10),
                      child: ElevatedButton(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon( // HugeIconをIconに変更
                              Icons.mail,
                              color: Colors.black,
                              size: 24.0,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Center(
                                child: const Text(
                                  'メールアドレスでログイン',
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                            ),
                          ],
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EmailLoginPage(),
                            ),
                          );
                        },
                      ),
                    ),

                    // メールアドレスでアカウント登録
                    Container(
                      width: 300,
                      margin: const EdgeInsets.all(10),
                      child: ElevatedButton(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon( // HugeIconをIconに変更
                              Icons.person_add,
                              color: Colors.black,
                              size: 24.0,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Center(
                                child: const Text(
                                  'メールアドレスでアカウント登録',
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                            ),
                          ],
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EmailSignUpPage(),
                            ),
                          );
                        },
                      ),
                    ),

                    // LINEログイン
                    Container(
                      width: 300,
                      margin: const EdgeInsets.all(10),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.chat_bubble, // LINEアイコンの代替
                              color: Colors.white,
                              size: 24.0,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Center(
                                child: const Text(
                                  'LINEでログイン',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                        onPressed: () async {
                          try {
                            await context.read<AuthViewModel>().signInWithLineWeb();
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MainScreen(),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('LINEログインに失敗しました: $e')),
                            );
                          }
                        },
                      ),
                    ),

                    // LINEログイン (Web用)
                    Container(
                      width: 300,
                      margin: const EdgeInsets.all(10),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.chat_bubble, // LINEアイコンの代替
                              color: Colors.white,
                              size: 24.0,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Center(
                                child: const Text(
                                  'LINEでログイン (Web)',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                        onPressed: () async {
                          try {
                            await context.read<AuthViewModel>().signInWithLineWeb();
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MainScreen(),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('LINEログインに失敗しました: $e')),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
