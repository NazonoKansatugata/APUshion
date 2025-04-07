import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:apusion/model/user_model.dart';

class AdminUserDetailScreen extends StatelessWidget {
  final String userId; // ユーザーIDを受け取る
  const AdminUserDetailScreen({Key? key, required this.userId}) : super(key: key);

  Future<UserModel?> _fetchUserDetails() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
    if (doc.exists) {
      return UserModel.fromJson(doc.data()!);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ユーザー詳細(User Details)'),
      ),
      body: FutureBuilder<UserModel?>(
        future: _fetchUserDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('ユーザー情報が見つかりません'));
          }

          final user = snapshot.data!;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ListView(
                children: [
                  const SizedBox(height: 24),
                  Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: (user.photoURL != null &&
                              user.photoURL!.isNotEmpty)
                          ? NetworkImage(user.photoURL!)
                          : null,
                      child: (user.photoURL == null || user.photoURL!.isEmpty)
                          ? const Icon(Icons.person, size: 50)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
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
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
