import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:apusion/ui/create/view/create_page.dart';
import 'package:provider/provider.dart';
import 'package:apusion/ui/auth/view_model/auth_view_model.dart';

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

  /// 購入処理 & 来店予定の追加
  Future<void> _purchaseItem() async {
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ログインしてください")),
      );
      return;
    }

    final TextEditingController visitDateController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('来店予定日を入力'),
          content: TextField(
            controller: visitDateController,
            decoration: const InputDecoration(
              hintText: '例: 2024-01-01',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  // Firestore に購入情報を保存
                  await FirebaseFirestore.instance
                      .collection('purchases')
                      .doc(widget.documentId)
                      .set({
                    'buyerId': currentUserId,
                    'purchaseDate': DateTime.now(),
                  });

                  // Firestore に来店予定を保存
                  await FirebaseFirestore.instance.collection('shopVisits').add({
                    'userId': currentUserId,
                    'userName': FirebaseAuth.instance.currentUser!.displayName ?? '匿名ユーザー',
                    'visitDate': visitDateController.text,
                    'product': profileData?['name'] ?? '商品名なし',
                    'productId': widget.documentId,
                    'visitType': 'purchase',
                    'createdAt': Timestamp.now(),
                  });

                  // 購入後は status を購入済みに変更
                  await FirebaseFirestore.instance
                      .collection('profiles')
                      .doc(widget.documentId)
                      .update({'status': '購入済み'});

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

  /// 購入取り消し処理
  Future<void> _cancelPurchase() async {
    try {
      // purchases コレクションから削除
      await FirebaseFirestore.instance
          .collection('purchases')
          .doc(widget.documentId)
          .delete();

      // shopVisits コレクションから対応する来店予定を削除
      QuerySnapshot visitSnapshot = await FirebaseFirestore.instance
          .collection('shopVisits')
          .where('productId', isEqualTo: widget.documentId)
          .where('userId', isEqualTo: currentUserId)
          .get();

      // 取得したドキュメントを削除
      await Future.wait(
        visitSnapshot.docs.map((doc) => doc.reference.delete()),
      );

      // status を 出品中 に変更
      await FirebaseFirestore.instance
          .collection('profiles')
          .doc(widget.documentId)
          .update({'status': '出品中'});

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

  /// 編集画面へ遷移
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

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final bool isAdmin = authVM.isAdmin();

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
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                profileData?['name'] ?? '商品名なし',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              isPurchased
                  ? ElevatedButton(
                      onPressed: _cancelPurchase,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      ),
                      child: Text("購入取り消し", style: TextStyle(fontSize: 16, color: Colors.white)),
                    )
                  : ElevatedButton(
                      onPressed: _purchaseItem,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      ),
                      child: Text("購入する", style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
