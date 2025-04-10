import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ProfileCard.dart';
import 'ProfileListScreen.dart'; // 全商品一覧画面
import 'package:apusion/ui/user/favorite_page.dart'; // お気に入り画面のインポート

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: EdgeInsets.only(top: 20),
          child: Text(
            "おすすめ商品 (Top Picks)",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        backgroundColor: Colors.green.shade800, // 濃い緑色
        elevation: 0,
        actions: [
          Padding(
            padding: EdgeInsets.only(top: 20, right: 16),
            child: IconButton(
              icon: Icon(Icons.favorite, color: Colors.red),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FavoriteScreen()),
                );
              },
            ),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          color: Colors.green.shade800, // 背景を濃い緑色に変更
        ),
        child: Column(
          children: [
            SizedBox(height: kToolbarHeight + 30), // 余白を増やす
            Expanded(
              child: FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection('profiles')
                    .where('status', isEqualTo: '出品中(listed)') // 出品中の商品のみ取得
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        "出品中の商品がありません (No products available for sale)",
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  var profiles = snapshot.data!.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();

                  // 🔥 ここでランダムに5つ選ぶ
                  profiles.shuffle(Random());
                  List<Map<String, dynamic>> randomProfiles = profiles.take(9).toList();

                  return GridView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3, // 一行に3つ表示
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1, // 正方形
                    ),
                    itemCount: randomProfiles.length,
                    itemBuilder: (context, index) {
                      var profile = randomProfiles[index];
                      return ProfileCard(profile: profile, documentId: profile['id'] ?? 'unknown');
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProfileListScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  "すべての商品を見る (Catalog page)",
                  style: TextStyle(fontSize: 18, color: Colors.green.shade800),
                ), // ボタンの文字色を濃い緑に変更
              ),
            ),
          ],
        ),
      ),
    );
  }
}
