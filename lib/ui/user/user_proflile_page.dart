import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:apusion/model/user_model.dart';
import 'package:apusion/ui/auth/view_model/auth_view_model.dart';
import 'package:apusion/ui/auth/view/auth_page.dart';
import 'package:apusion/ui/user/user_proflile_page.dart';
import 'package:apusion/ui/user/favorite_page.dart';
import 'package:apusion/ui/home/ProfileListScreen.dart';
import 'package:apusion/ui/user/user_detail_page.dart';
import 'package:apusion/ui/home/home_page.dart'; // これが必要


class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);
    final UserModel? user = authViewModel.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('プロフィール(Profile)'),
        centerTitle: true,
      ),
      body: Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [Colors.green.shade800, Colors.green.shade600], // 濃い緑色のグラデーション(dark green gradient)
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
        child: SafeArea(
          child: user != null
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ListView(
                    children: [
                      const SizedBox(height: 24),
                      // 丸いアイコン（アバター）(Circular icon (avatar))
                      Center(
                        child: CircleAvatar(
                          radius: 50,
                          backgroundImage: (user.photoURL != null &&
                                  user.photoURL!.isNotEmpty)
                              ? NetworkImage(user.photoURL!)
                              : null,
                          child: (user.photoURL == null ||
                                  user.photoURL!.isEmpty)
                              ? const Icon(Icons.person, size: 50)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // ユーザー名(User name)
                      Center(
                        child: Column(
                          children: [
                            Text(
                              user.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      // ボタン一覧
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          foregroundColor: Colors.black,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => UserDetailScreen()),
                          );
                        },
                        child: const Text('ユーザー情報(User Details)'),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          foregroundColor: Colors.black,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => FavoriteScreen()),
                          );
                        },
                        child: const Text('いいねした商品一覧(Favorite Items List)'),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          minimumSize: const Size.fromHeight(48),
                          foregroundColor: Colors.black,
                        ),
                        onPressed: () async {
                          // ログアウト処理
                          await authViewModel.signOut();
                          // HomeScreenに遷移
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => MainScreen()),
                            );
                          },
                        child: const Text('ログアウト(Logout)'),
                      ),
                    ],
                  ),
                )
              : Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('ユーザーがログインしていません(User is not logged in)'),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/login');
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.black,
                        ),
                        child: const Text('ログイン画面へ(To Login Screen)'),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
