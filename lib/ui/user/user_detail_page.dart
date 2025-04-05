import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:apusion/model/user_model.dart';
import 'package:apusion/ui/auth/view_model/auth_view_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:apusion/ui/user/user_profile_edit_page.dart';

class UserDetailScreen extends StatefulWidget {
  const UserDetailScreen({Key? key}) : super(key: key);

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);
    final UserModel? user = authViewModel.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('ユーザー詳細(User Details)'),
        automaticallyImplyLeading: true,
      ),
      body: SafeArea(
        child: user != null
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ListView(
                  children: [
                    const SizedBox(height: 24),
                    // ユーザーのアバター
                    Center(
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage:
                            (user.photoURL != null && user.photoURL!.isNotEmpty)
                                ? NetworkImage(user.photoURL!)
                                : null,
                        child: (user.photoURL == null || user.photoURL!.isEmpty)
                            ? const Icon(Icons.person, size: 50)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // ユーザー名表示のみ（キャラ愛Lv.削除）
                    Center(
                      child: Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    ListView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        ListTile(
                          title: const Text('Email(メールアドレス)'),
                          subtitle: Text(user.email ?? 'メールアドレス未提供'),
                        ),
                        ListTile(
                          title: const Text('UID(ユーザーID)'),
                          subtitle: Text(user.uid ?? 'ユーザーID未提供'),
                        ),
                        ListTile(
                          title: const Text('本名(Full Name)'),
                          subtitle: Text(user.fullName ?? '未設定'),
                        ),
                        ListTile(
                          title: const Text('住所(Address)'),
                          subtitle: Text(user.address ?? '未設定'),
                        ),
                        ListTile(
                          title: const Text('電話番号(Phone Number)'),
                          subtitle: Text(user.phoneNumber ?? '未設定'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => UserProfileEditPage()),
                        );
                      },
                      child: const Text('プロフィール編集(Edit Profile)'),
                    ),
                  ],
                ),
              )
            : Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('ユーザーがログインしていません(User not logged in)'),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/login');
                      },
                      child: const Text('ログイン画面へ(To Login Screen)'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
