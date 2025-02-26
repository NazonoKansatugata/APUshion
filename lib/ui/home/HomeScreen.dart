import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ProfileCard.dart';
import 'package:apusion/ui/favorite/favorite_page.dart'; // お気に入り画面のインポート

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedCategory = "すべて"; // デフォルトのカテゴリ

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: EdgeInsets.only(top: 20),
          child: Text(
            "ぷろふぃーる一覧",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: EdgeInsets.only(top: 20, right: 16),
            child: DropdownButton<String>(
              value: selectedCategory,
              dropdownColor: Colors.white,
              items: ["すべて", "電子レンジ", "冷蔵庫", "洗濯機"]
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
                stream: selectedCategory == "すべて"
                    ? FirebaseFirestore.instance.collection('profiles').snapshots()
                    : FirebaseFirestore.instance
                        .collection('profiles')
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
                  return FutureBuilder<QuerySnapshot>(
                    future: FirebaseFirestore.instance.collection('purchases').get(),
                    builder: (context, purchaseSnapshot) {
                      if (purchaseSnapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }
                      List<String> purchasedItemIds = purchaseSnapshot.data?.docs
                              .map((doc) => doc.id)
                              .toList() ??
                          [];
                      var filteredProfiles =
                          profiles.where((profile) => !purchasedItemIds.contains(profile.id)).toList();
                      return ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                        itemCount: filteredProfiles.length,
                        itemBuilder: (context, index) {
                          var profile = filteredProfiles[index].data() as Map<String, dynamic>;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: ProfileCard(profile: profile, documentId: filteredProfiles[index].id),
                          );
                        },
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
