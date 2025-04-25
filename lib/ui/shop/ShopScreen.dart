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

  void _showAdminDateSelectionDialog(BuildContext context, Map<String, dynamic> visit, String documentId) {
    // visitDates を List<String> に変換
    List<String> visitDates = (visit['visitDates'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    String? selectedDate; // 選択された日付を格納

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("来店予定日を選択(Select Visit Date)"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (visitDates.isNotEmpty)
                    DropdownButtonFormField<String>(
                      value: selectedDate,
                      items: visitDates.map((date) {
                        return DropdownMenuItem(
                          value: date,
                          child: Text(date),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedDate = value;
                        });
                      },
                      decoration: InputDecoration(labelText: "来店予定日(Visit Date)"),
                    )
                  else
                    Text("選択可能な日付がありません(No available dates)"),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("キャンセル(Cancel)"),
                ),
                ElevatedButton(
                  onPressed: selectedDate != null
                      ? () async {
                          try {
                            // Firestore に選択された日付を保存
                            await FirebaseFirestore.instance.collection('shopVisits').doc(documentId).update({
                              'visitDate': selectedDate, // 選択された日付を格納
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("日付が選択されました(Date Selected)")),
                            );

                            Navigator.pop(context);
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("エラーが発生しました: $e")),
                            );
                          }
                        }
                      : null,
                  child: const Text("確定(Confirm)"),
                ),
              ],
            );
          },
        );
      },
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

            // 出品と購入を分けて表示
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: isAdmin
                    ? FirebaseFirestore.instance
                        .collection('shopVisits')
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

                  var visits = snapshot.data!.docs.map((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    data['id'] = doc.id; // ドキュメントIDを追加
                    return data;
                  }).toList();

                  var listings = visits.where((visit) => visit['visitType'] == 'listing').toList();
                  var purchases = visits.where((visit) => visit['visitType'] == 'purchase').toList();
                  var mediations = visits.where((visit) => visit['visitType'] == 'Mediation').toList();
                  var cancellations = visits.where((visit) => visit['visitType'] == 'cancel').toList(); // キャンセル待ちリストを取得

                  return ListView(
                    children: [
                      // 出品リスト
                      if (listings.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text("出品リスト(Listings)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                        ...listings.map((visit) => _buildVisitCard(visit, isAdmin)),
                      ],

                      // 購入リスト
                      if (purchases.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text("購入リスト(Purchases)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                        ...purchases.map((visit) => _buildVisitCard(visit, isAdmin)),
                      ],

                      // 仲介リスト
                      if (mediations.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text("仲介リスト(Mediations)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                        ...mediations.map((visit) => _buildVisitCard(visit, isAdmin)),
                      ],

                      // キャンセル待ちリスト
                      if (cancellations.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text("キャンセル待ちリスト(Cancellations)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                        ...cancellations.map((visit) => _buildVisitCard(visit, isAdmin)),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisitCard(Map<String, dynamic> visit, bool isAdmin) {
    String? productId = visit['productId'];
    String documentId = visit['id']; // ドキュメントIDを取得

    // アイコンと色、タグを決定
    IconData iconData;
    Color color;
    String tag;

    if (visit['visitType'] == 'cancel') {
      iconData = Icons.cancel; // キャンセル待ち用のアイコン
      color = Colors.red;
      tag = "キャンセル待ち(Cancel)";
    } else if (visit['visitType'] == 'Mediation') {
      iconData = Icons.handshake; // 仲介用のアイコン
      color = Colors.blue;
      tag = "仲介(Mediation)";
      } else if (visit['pickupMethod'] == '仲介(Mediation)') {
      iconData = Icons.handshake; // 仲介用のアイコン
      color = Colors.blue;
      tag = "仲介(Mediation)";
    } else if (visit['pickupMethod'] == '配送(Delivery)') {
      iconData = Icons.local_shipping; // 配送用のアイコン
      color = Colors.purple;
      tag = "配送(Delivery)";
    } else if (visit['pickupMethod'] == '店舗受け取り(Store Pickup)') {
      iconData = Icons.store; // 店舗受け取り用のアイコン
      color = Colors.orange;
      tag = "店舗受け取り(Store Pickup)";
    } else {
      iconData = Icons.help; // 不明な場合のアイコン
      color = Colors.grey;
      tag = "未設定(Unset)";
    }

    return Card(
      margin: const EdgeInsets.all(8),
      child: ListTile(
        leading: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(iconData, color: color),
            const SizedBox(height: 4),
            Text(tag, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
        title: Text(visit['product'] ?? '商品名なし(No product name)'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("来店予定日(Scheduled visit date): ${visit['visitDate'] ?? '未設定(Unset)'}"),
            if (isAdmin) Text("ユーザー(UserName): ${visit['userName']}"),
          ],
        ),
        trailing: isAdmin && visit['visitType'] == 'Mediation'
            ? ElevatedButton(
                onPressed: () => _showAdminDateSelectionDialog(context, visit, documentId),
                child: const Text("日付選択(Select Date)"),
              )
            : const Icon(Icons.arrow_forward),
        onTap: productId != null
            ? () => _navigateToDetail(productId)
            : () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('商品情報が見つかりません(Product information not found)')),
                );
              },
      ),
    );
  }
}
