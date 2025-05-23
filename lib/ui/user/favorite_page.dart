import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../home/ProfileCard.dart'; // プロフィールカードのインポート

class FavoriteScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: EdgeInsets.only(top: 20),
          child: Text(
            "お気に入り一覧((Favorites)",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.pink.shade300, Colors.redAccent.shade200],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            SizedBox(height: kToolbarHeight + 30), // 余白を増やして重なりを防ぐ
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(FirebaseAuth.instance.currentUser?.uid)
                    .collection('likedProfiles')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        "お気に入りの商品はありません(No favorite products)",
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    );
                  }

                  var likedProfiles = snapshot.data!.docs;

                  return GridView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3, // 一行に3つ表示
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1, // 正方形
                    ),
                    itemCount: likedProfiles.length,
                    itemBuilder: (context, index) {
                      var profileId = likedProfiles[index].id;

                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance.collection('profiles').doc(profileId).get(),
                        builder: (context, profileSnapshot) {
                          if (profileSnapshot.connectionState == ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          }
                          if (!profileSnapshot.hasData || !profileSnapshot.data!.exists) {
                            // プロファイルが存在しない場合、likedProfilesから削除
                            FirebaseFirestore.instance
                                .collection('users')
                                .doc(FirebaseAuth.instance.currentUser?.uid)
                                .collection('likedProfiles')
                                .doc(profileId)
                                .delete();
                            return SizedBox.shrink();
                          }

                          var profile = profileSnapshot.data!.data() as Map<String, dynamic>;
                          if (profile['status'] != '出品中(listed)') {
                            // ステータスが出品中でない場合、likedProfilesから削除
                            FirebaseFirestore.instance
                                .collection('users')
                                .doc(FirebaseAuth.instance.currentUser?.uid)
                                .collection('likedProfiles')
                                .doc(profileId)
                                .delete();
                            return SizedBox.shrink();
                          }

                          return ProfileCard(profile: profile, documentId: profileId);
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
