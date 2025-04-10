import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // FirebaseAuthのインポート
import 'ProfileDetailScreen.dart';

class ProfileCard extends StatefulWidget {
  final Map<String, dynamic> profile;
  final String documentId;

  ProfileCard({required this.profile, required this.documentId});

  @override
  _ProfileCardState createState() => _ProfileCardState();
}

class _ProfileCardState extends State<ProfileCard> {
  bool isFavorite = false;

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
  }

  void _checkFavoriteStatus() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    DocumentSnapshot likedProfileDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .collection('likedProfiles')
        .doc(widget.documentId)
        .get();

    setState(() {
      isFavorite = likedProfileDoc.exists;
    });
  }

  void _toggleFavorite(BuildContext context) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("ログインしてください(Please log in)")),
      );
      return;
    }

    if (isFavorite) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('likedProfiles')
          .doc(widget.documentId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("お気に入りを解除しました(Removed from favorites)")),
      );
    } else {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('likedProfiles')
          .doc(widget.documentId)
          .set({'isFavorite': true});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("お気に入りに追加しました(Added to favorites)")),
      );
    }

    setState(() {
      isFavorite = !isFavorite;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileDetailScreen(documentId: widget.documentId),
          ),
        );
      },
      child: Container(
        width: MediaQuery.of(context).size.width / 3 - 16, // 画面幅の1/3から余白を引く
        margin: EdgeInsets.all(8),
        child: Stack(
          children: [
            AspectRatio(
              aspectRatio: 1, // 正方形
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: widget.profile['imageUrls'] != null && widget.profile['imageUrls'].isNotEmpty
                    ? Image.network(
                        widget.profile['imageUrls'][0],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: Icon(Icons.image, size: 40, color: Colors.grey[600]),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey[300],
                        child: Icon(Icons.image, size: 40, color: Colors.grey[600]),
                      ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => _toggleFavorite(context),
                child: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.red : Colors.white,
                  size: 24,
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  widget.profile['price'] != null ? '¥${widget.profile['price']}' : '価格未設定',
                  style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
