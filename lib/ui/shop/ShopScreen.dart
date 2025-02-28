import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:apusion/ui/auth/view_model/auth_view_model.dart';
import 'package:apusion/ui/create/view/create_page.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({Key? key}) : super(key: key);

  @override
  _ShopScreenState createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final TextEditingController _visitDateController = TextEditingController();
  final TextEditingController _productController = TextEditingController();
  String _visitType = 'listing'; // デフォルトは "出品"
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _visitDateController.dispose();
    _productController.dispose();
    super.dispose();
  }

  /// 来店予定の追加
  Future<void> _addVisit() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('shopVisits').add({
      'userId': user.uid,
      'userName': user.displayName ?? '匿名ユーザー',
      'visitDate': _visitDateController.text,
      'product': _productController.text,
      'visitType': _visitType, // 出品のみ
      'createdAt': Timestamp.now(),
    });

    // フィールドをクリア
    _visitDateController.clear();
    _productController.clear();

    // スナックバーで通知
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('来店予定を追加しました')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final bool isAdmin = authVM.isAdmin();
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("ショップ")),
        body: const Center(child: Text("ログインしてください")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("ショップ")),
      body: Column(
        children: [
          // デバッグ情報の表示
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Text("ユーザーID: ${user.uid}"),
                Text("管理者: ${isAdmin ? 'はい' : 'いいえ'}"),
              ],
            ),
          ),

          // 来店予定の入力フォーム
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  controller: _productController,
                  decoration: const InputDecoration(
                    labelText: '商品名',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _visitDateController,
                  decoration: const InputDecoration(
                    labelText: '来店予定日 (例: 2024-01-01)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _addVisit,
                  child: const Text('来店予定を追加'),
                ),
              ],
            ),
          ),
          const Divider(),

          // 来店予定リスト
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('shopVisits')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("来店予定はありません"));
                }

                var visits = snapshot.data!.docs;

                // デバッグ用: 取得したデータをすべて表示
                for (var visit in visits) {
                  debugPrint('取得データ: ${visit.data()}');
                }

                return ListView.builder(
                  itemCount: visits.length,
                  itemBuilder: (context, index) {
                    var visit = visits[index].data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        leading: Icon(
                          visit['visitType'] == 'listing'
                              ? Icons.store
                              : Icons.error,
                          color: visit['visitType'] == 'listing'
                              ? Colors.orange
                              : Colors.red,
                        ),
                        title: Text(visit['product'] ?? '商品名なし'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("来店予定日: ${visit['visitDate']}"),
                            Text("ユーザー: ${visit['userName']}"),
                          ],
                        ),
                        trailing: Text(
                          '出品',
                          style: const TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // 出品するボタン
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateScreen(profileId: null),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('出品する'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
