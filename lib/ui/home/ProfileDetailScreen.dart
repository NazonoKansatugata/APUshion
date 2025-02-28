import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:apusion/ui/create/view/create_page.dart';

class ProfileDetailScreen extends StatefulWidget {
  final String documentId;

  ProfileDetailScreen({required this.documentId});

  @override
  _ProfileDetailScreenState createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen> {
  String? currentUserId;
  bool isOwner = false; // 現在のユーザーが出品者かどうかを判定
  Map<String, dynamic>? profileData;

  @override
  void initState() {
    super.initState();
    _checkIfOwner();
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

    /// 購入処理 & 来店予定の追加
  Future<void> _purchaseItem() async {
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ログインしてください")),
      );
      return;
    }

    // 来店予定日を入力するダイアログを表示
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
                    'userName':
                        FirebaseAuth.instance.currentUser!.displayName ??
                            '匿名ユーザー',
                    'visitDate': visitDateController.text,
                    'product': profileData?['name'] ?? '商品名なし',
                    'createdAt': Timestamp.now(),
                  });

                  Navigator.pop(context); // ダイアログを閉じる
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
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('profiles')
            .doc(widget.documentId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text("商品が見つかりません"));
          }

          var profile = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 画像表示（最大5枚）
                  if (profile['imageUrls'] != null && profile['imageUrls'].isNotEmpty)
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: profile['imageUrls']
                          .take(5)
                          .map<Widget>((imageUrl) => ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  imageUrl,
                                  width: 200,
                                  height: 200,
                                  fit: BoxFit.cover,
                                ),
                              ))
                          .toList(),
                    ),
                  if (profile['imageUrls'] == null || profile['imageUrls'].isEmpty)
                    Container(
                      width: 200,
                      height: 200,
                      color: Colors.grey[300],
                      child: Icon(Icons.image, size: 100, color: Colors.grey[600]),
                    ),
                  SizedBox(height: 16),

                  // 商品情報
                  _buildProfileSection("商品情報", [
                    _buildProfileRow("商品名", profile['name'] ?? '商品名なし'),
                    _buildCategoryTag(profile['category']),
                    _buildProfileRow("価格", profile['price'] != null ? '¥${profile['price']}' : '不明'),
                    _buildProfileRow("説明", profile['description']),
                    _buildProfileRow("作成日", profile['createdAt']?.toDate().toString() ?? '不明'),
                  ]),

                  SizedBox(height: 16),

                  // 購入 or 編集ボタン
                  isOwner
                      ? ElevatedButton(
                          onPressed: _editItem,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          ),
                          child: Text("編集する", style: TextStyle(fontSize: 16, color: Colors.white)),
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

                  SizedBox(height: 16),

                  // 戻るボタン
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                    child: Text("一覧画面へ戻る", style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // セクションデザイン
  Widget _buildProfileSection(String title, List<Widget> children) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            spreadRadius: 2,
            offset: Offset(2, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
          SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  // 情報行デザイン（エラーの原因となっていた関数）
Widget _buildProfileRow(String label, dynamic value) {
  return Padding(
    padding: EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("$label: ", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Expanded(
          child: Text(
            value != null ? value.toString() : '不明',
            style: TextStyle(fontSize: 16),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}

  // カテゴリータグデザイン
  Widget _buildCategoryTag(String? category) {
    if (category == null || category.isEmpty) return SizedBox.shrink();
    return Container(
      margin: EdgeInsets.only(top: 8),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        category,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue.shade800),
      ),
    );
  }
}
