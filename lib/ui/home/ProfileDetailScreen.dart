import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:apusion/ui/create/view/create_page.dart';
import 'package:provider/provider.dart';
import 'package:apusion/ui/auth/view_model/auth_view_model.dart';
import 'agreement_text.dart';  // 同意書の内容をインポート

class ProfileDetailScreen extends StatefulWidget {
  final String documentId;

  ProfileDetailScreen({required this.documentId});

  @override
  _ProfileDetailScreenState createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen> {
  String? currentUserId;
  bool isOwner = false;
  Map<String, dynamic>? profileData;
  bool isPurchased = false;

  @override
  void initState() {
    super.initState();
    _checkIfOwner();
    _checkIfPurchased();
  }

  Future<void> _checkIfOwner() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      currentUserId = user.uid;
    });

    DocumentSnapshot profileSnapshot = await FirebaseFirestore.instance
        .collection('profiles')
        .doc(widget.documentId)
        .get();

    if (profileSnapshot.exists) {
      setState(() {
        profileData = profileSnapshot.data() as Map<String, dynamic>;
        isOwner = profileData!['userId'] == currentUserId;
      });
    }
  }

  Future<void> _checkIfPurchased() async {
    DocumentSnapshot purchaseSnapshot = await FirebaseFirestore.instance
        .collection('purchases')
        .doc(widget.documentId)
        .get();

    setState(() {
      isPurchased = purchaseSnapshot.exists;
    });
  }

  // 購入処理 & 来店予定の追加
  Future<void> _purchaseItem() async {
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ログインしてください")),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _purchaseDialog(),
    );
  }

  // 購入処理ダイアログ
// 購入処理ダイアログ
Widget _purchaseDialog() {
  final TextEditingController visitDateController = TextEditingController();
  DateTime? pickedDate;
  bool isAgreementChecked = false; // チェックボックスの状態を管理

  return StatefulBuilder(
    builder: (context, setState) {
      return AlertDialog(
        title: const Text('来店予定日を入力'),
        content: Form(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: visitDateController,
                decoration: const InputDecoration(
                  hintText: '例: 2024-01-01',
                ),
                readOnly: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '来店予定日を選択してください';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(Duration(days: 365)),
                  );

                  if (pickedDate != null) {
                    visitDateController.text = "${pickedDate?.toLocal()}".split(' ')[0];
                  }
                },
                child: Text('カレンダーで選択'),
              ),
              // 契約書表示ボタン
              ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => _agreementDialog(),
                  );
                },
                child: Text('契約書を表示'),
              ),
              SizedBox(height: 10),
              // チェックボックスを追加
              Row(
                children: [
                  Checkbox(
                    value: isAgreementChecked,
                    onChanged: (bool? newValue) {
                      setState(() {
                        isAgreementChecked = newValue ?? false;
                      });
                    },
                  ),
                  Expanded(
                    child: Text(
                      '契約書に同意する',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (visitDateController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('来店予定日を選択してください')),
                );
                return;
              }

              if (!isAgreementChecked) { // チェックボックスが選択されていない場合
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('契約書に同意してください')),
                );
                return;
              }

              try {
                await FirebaseFirestore.instance.collection('purchases').doc(widget.documentId).set({
                  'buyerId': currentUserId,
                  'purchaseDate': DateTime.now(),
                });

                await FirebaseFirestore.instance.collection('shopVisits').add({
                  'userId': currentUserId,
                  'userName': FirebaseAuth.instance.currentUser!.displayName ?? '匿名ユーザー',
                  'visitDate': visitDateController.text,
                  'product': profileData?['name'] ?? '商品名なし',
                  'productId': widget.documentId,
                  'visitType': 'purchase',
                  'createdAt': Timestamp.now(),
                });

                await FirebaseFirestore.instance.collection('profiles').doc(widget.documentId).update({'status': '購入済み'});

                setState(() {
                  isPurchased = true;
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("購入が完了し、来店予定を追加しました")),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("購入に失敗しました: $e")),
                );
              }
            },
            child: const Text('購入'),
          ),
        ],
      );
    },
  );
}

  // 購入取り消し処理
  Future<void> _cancelPurchase() async {
    try {
      await FirebaseFirestore.instance.collection('purchases').doc(widget.documentId).delete();

      QuerySnapshot visitSnapshot = await FirebaseFirestore.instance
          .collection('shopVisits')
          .where('productId', isEqualTo: widget.documentId)
          .where('userId', isEqualTo: currentUserId)
          .get();

      await Future.wait(visitSnapshot.docs.map((doc) => doc.reference.delete()));

      await FirebaseFirestore.instance.collection('profiles').doc(widget.documentId).update({'status': '出品中'});

      setState(() {
        isPurchased = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("購入を取り消しました")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("取り消しに失敗しました: $e")),
      );
    }
  }

  // 編集画面へ遷移
  void _editItem() {
    if (profileData != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CreateScreen(
            profileId: widget.documentId,
            initialProfileData: profileData!,
          ),
        ),
      );
    }
  }

  // 商品画像表示
  Widget _buildProductImages() {
    if (profileData?['imageUrls'] != null && profileData!['imageUrls'].isNotEmpty) {
      return SizedBox(
        height: 250,
        child: PageView(
          children: List<Widget>.from(
            profileData!['imageUrls'].map<Widget>((url) => Image.network(
              url,
              fit: BoxFit.cover,
              width: double.infinity,
            )),
          ),
        ),
      );
    } else {
      return Container(
        height: 250,
        color: Colors.grey[300],
        child: Center(
          child: Text(
            '画像はありません',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
        ),
      );
    }
  }

  // 商品詳細カード
  Widget _buildProductDetailsCard() {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profileData?['name'] ?? '商品名なし',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              if (profileData?['category'] != null)
                Chip(
                  label: Text(profileData!['category']),
                  backgroundColor: Colors.blue.shade100,
                ),
              SizedBox(height: 8),
              Text(
                '価格: ¥${profileData?['price']?.toString() ?? '不明'}',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text(
                profileData?['description'] ?? '商品説明なし',
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              SizedBox(height: 16),
              Text(
                '取り扱い店舗: ${profileData?['store'] ?? '未設定'}',
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              SizedBox(height: 8),
              Text(
                '出品者: ${profileData?['userName'] ?? '匿名'}',
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              SizedBox(height: 8),
              Text(
                '商品ID: ${widget.documentId}',
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              SizedBox(height: 8),
              Text(
                '出品日時: ${profileData?['updatedAt']?.toDate().toString() ?? '不明'}',
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 契約書ダイアログ
  Widget _agreementDialog() {
    return AlertDialog(
      title: Text('売買契約書'),
      content: SingleChildScrollView(
        child: Text(agreementText),  // agreementTextを表示
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('閉じる'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final bool isAdmin = authVM.isAdmin();
    final bool isLoggedIn = currentUserId != null;
    final String? status = profileData?['status'];

    return Scaffold(
      backgroundColor: Colors.purple.shade50,
      appBar: AppBar(
        title: Text(
          "商品詳細",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: isLoggedIn
          ? SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildProductImages(),
                  _buildProductDetailsCard(),
                  if (isAdmin || status == "下書き") 
                    ElevatedButton(
                      onPressed: _editItem,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      ),
                      child: Text("編集", style: TextStyle(fontSize: 16, color: Colors.white)),
                    )
                  else if (isPurchased)
                    ElevatedButton(
                      onPressed: _cancelPurchase,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      ),
                      child: Text("購入取り消し", style: TextStyle(fontSize: 16, color: Colors.white)),
                    )
                  else
                    ElevatedButton(
                      onPressed: _purchaseItem,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      ),
                      child: Text("購入する", style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                  SizedBox(height: 20),
                ],
              ),
            )
          : Center(
              child: Text(
                'ログインしてください',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey[700]),
              ),
            ),
    );
  }
}
