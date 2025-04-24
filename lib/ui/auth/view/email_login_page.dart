import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart'; // Providerパッケージ

import 'package:apusion/ui/home/home_page.dart';
import 'package:apusion/ui/auth/view_model/auth_view_model.dart';
import 'package:apusion/ui/user/user_profile_edit_page.dart';
import '../../components/background_animation.dart';

class EmailLoginPage extends StatefulWidget {
  const EmailLoginPage({Key? key}) : super(key: key);

  @override
  _EmailLoginPage createState() => _EmailLoginPage();
}

class _EmailLoginPage extends State<EmailLoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool hidePassword = true;
  String errorMessage = '';

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  /// メールアドレス＆パスワードでログイン
  Future<void> _login() async {
    final authVM = context.read<AuthViewModel>(); // ViewModel取得

    try {
      await authVM.signInWithEmail(
        emailController.text,
        passwordController.text,
      );
      // ログイン成功
      if (authVM.currentUser != null) {
        print("ログイン成功: ${authVM.currentUser!.toJson()}");

        // main.dartに遷移
        Navigator.pushReplacementNamed(context, '/');
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = 'メールアドレスまたはパスワードが間違っています';
      });
      print(e);
    } catch (e) {
      setState(() {
        errorMessage = '予期せぬエラーが発生しました';
      });
      print(e);
    }
  }

  /// パスワードリセット用ダイアログを表示
  Future<void> _showResetPasswordDialog() async {
    final TextEditingController resetEmailController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('パスワードリセット'),
          content: TextField(
            controller: resetEmailController,
            decoration: const InputDecoration(
              labelText: '登録済みのメールアドレスを入力してください',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () async {
                final email = resetEmailController.text.trim();
                if (email.isNotEmpty) {
                  try {
                    await _resetPassword(email);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('パスワードリセットメールを送信しました')),
                    );
                    Navigator.pop(context);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('エラーが発生しました: $e')),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('メールアドレスを入力してください')),
                  );
                }
              },
              child: const Text('送信'),
            ),
          ],
        );
      },
    );
  }

  /// パスワードリセット
  Future<void> _resetPassword(String email) async {
    final authVM = context.read<AuthViewModel>();
    await authVM.resetPassword(email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BackgroundAnimation1(
        size: MediaQuery.of(context).size,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Login',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    icon: Icon(Icons.mail),
                    hintText: 'example@email.com',
                    labelText: 'Email Address',
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: passwordController,
                  obscureText: hidePassword,
                  decoration: InputDecoration(
                    icon: const Icon(Icons.lock),
                    labelText: 'Password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        hidePassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          hidePassword = !hidePassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  child: const Text('ログイン'),
                  onPressed: _login,
                ),
                ElevatedButton(
                  onPressed: _showResetPasswordDialog,
                  child: const Text('パスワードを忘れた場合'),
                ),
                if (errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Text(
                      errorMessage,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
