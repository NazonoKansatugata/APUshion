import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ProfileCard.dart';
import 'package:apusion/ui/user/favorite_page.dart'; // お気に入り画面のインポート

class ProfileListScreen extends StatefulWidget {
  @override
  _ProfileListScreenState createState() => _ProfileListScreenState();
}

class _ProfileListScreenState extends State<ProfileListScreen> {
  String selectedCategory = "すべて(All)"; // デフォルトのカテゴリ

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: EdgeInsets.only(top: 20),
          child: Text(
            "商品一覧(Catalog page)",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: DropdownButton<String>(
              value: selectedCategory,
              dropdownColor: Colors.white,
              items: ["すべて(All)", "電子レンジ(microwave oven)", "冷蔵庫(refrigerator)", "洗濯機(washing machine)", "その他(others)"]
                  .map((category) => DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedCategory = value!;
                });
              },
            ),
          ),
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
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade400, Colors.pinkAccent.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            SizedBox(height: kToolbarHeight + 30), // 余白を増やす
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: selectedCategory == "すべて(All)"
                    ? FirebaseFirestore.instance
                        .collection('profiles')
                        .where('status', isEqualTo: '出品中(listed)')
                        .snapshots()
                    : FirebaseFirestore.instance
                        .collection('profiles')
                        .where('status', isEqualTo: '出品中(listed)')
                        .where('category', isEqualTo: selectedCategory)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                        child: Text(
                      "プロフィールがありません",
                      style: TextStyle(color: Colors.white),
                    ));
                  }
                  var profiles = snapshot.data!.docs;
                  return GridView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3, // 一行に3つ表示
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1, // 正方形
                    ),
                    itemCount: profiles.length,
                    itemBuilder: (context, index) {
                      var profile = profiles[index].data() as Map<String, dynamic>;
                      return ProfileCard(profile: profile, documentId: profiles[index].id);
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
