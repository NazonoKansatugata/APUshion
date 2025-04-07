import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:apusion/ui/admin/user_detail_screen.dart'; // 新しい詳細画面をインポート

class UserListScreen extends StatelessWidget {
  const UserListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ユーザー一覧(User List)'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('ユーザーが見つかりません(No Users Found)'));
          }

          final users = snapshot.data!.docs;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index].data() as Map<String, dynamic>;
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: user['photoURL'] != null
                      ? NetworkImage(user['photoURL'])
                      : null,
                  child: user['photoURL'] == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                title: Text(user['name'] ?? 'No Name'),
                subtitle: Text(user['email'] ?? 'No Email'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdminUserDetailScreen(
                        userId: users[index].id, // ユーザーIDを渡す
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
