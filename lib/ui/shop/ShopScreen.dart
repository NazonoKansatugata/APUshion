import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:apusion/ui/auth/view_model/auth_view_model.dart';
import 'package:apusion/ui/home/ProfileDetailScreen.dart';
import 'package:apusion/ui/create/view/create_page.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({Key? key}) : super(key: key);

  @override
  _ShopScreenState createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final TextEditingController _visitDateController = TextEditingController();
  final TextEditingController _productController = TextEditingController();
  String _visitType = 'listing';
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
      'userName': user.displayName ?? '匿名ユーザー(Anonymous)',
      'visitDate': _visitDateController.text,
      'product': _productController.text,
      'visitType': _visitType,
      'createdAt': Timestamp.now(),
    });

    _visitDateController.clear();
    _productController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('来店予定を追加しました(Added visit schedule)')),
    );
  }

  /// 商品詳細へ遷移
  void _navigateToDetail(String productId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileDetailScreen(documentId: productId),
      ),
    );
  }

  /// 出品画面へ遷移
  void _navigateToCreate() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final bool isAdmin = authVM.isAdmin();
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Shop")),
        body: const Center(child: Text("ログインしてください(Please log in)")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Shop"),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade800, Colors.green.shade600], // 濃い緑色のグラデーション
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            // 出品ボタンを上部に配置
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add_box, color: Colors.white),
                label: const Text("出品する(List)", style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _navigateToCreate,
              ),
            ),

            // 来店予定リスト
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: isAdmin
                    ? FirebaseFirestore.instance
                        .collection('shopVisits')
                        .orderBy('visitDate') // 来店予定日が早い順に並べる
                        .snapshots()
                    : FirebaseFirestore.instance
                        .collection('shopVisits')
                        .where('userId', isEqualTo: user.uid)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("来店予定はありません(No visit schedule)"));
                  }

                  var visits = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: visits.length,
                    itemBuilder: (context, index) {
                      var visit = visits[index].data() as Map<String, dynamic>;
                      String? productId = visit['productId'];

                      // アイコンと色、タグを決定
                      IconData iconData;
                      Color color;
                      String tag;
                      if (visit['pickupMethod'] == '仲介(Mediation)') {
                        iconData = Icons.handshake; // 仲介用のアイコン
                        color = Colors.blue;
                        tag = "仲介(Mediation)";
                      } else if (visit['visitType'] == 'purchase') {
                        iconData = Icons.shopping_cart;
                        color = Colors.green;
                        tag = "購入予定(Purchase)";
                      } else if (visit['visitType'] == 'cancel') {
                        iconData = Icons.cancel;
                        color = Colors.red;
                        tag = "キャンセル待ち(Cancel)";
                      } else {
                        iconData = Icons.store;
                        color = Colors.orange;
                        tag = "出品予定(Listing)";
                      }

                      return Card(
                        margin: const EdgeInsets.all(8),
                        child: ListTile(
                          leading: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(iconData, color: color),
                              const SizedBox(height: 4),
                              Text(tag,
                                  style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                          title: Text(visit['product'] ?? '商品名なし(No product name)'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("来店予定日(Scheduled visit date): ${visit['visitDate']}"),
                              Text("受け取り方法(Pickup Method): ${visit['pickupMethod'] ?? '未設定(Unset)'}"), // 受け取り方法を表示
                              if (isAdmin) Text("ユーザー(UserName): ${visit['userName']}"),
                            ],
                          ),
                          trailing: const Icon(Icons.arrow_forward),
                          onTap: productId != null
                              ? () => _navigateToDetail(productId)
                              : () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('商品情報が見つかりません(Product information not found)')),
                                  );
                                },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
