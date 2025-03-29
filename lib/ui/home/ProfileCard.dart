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
        SnackBar(content: Text("ログインしてください")),
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
        SnackBar(content: Text("お気に入りを解除しました")),
      );
    } else {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('likedProfiles')
          .doc(widget.documentId)
          .set({'isFavorite': true});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("お気に入りに追加しました")),
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
      child: Card(
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8), // 角を丸める
            child: widget.profile['imageUrls'] != null && widget.profile['imageUrls'].isNotEmpty
                ? Image.network(
                    widget.profile['imageUrls'][0], // 1枚目を表示
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[300],
                        child: Icon(Icons.image, size: 40, color: Colors.grey[600]),
                      );
                    },
                  )
                : Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[300],
                    child: Icon(Icons.image, size: 40, color: Colors.grey[600]),
                  ),
          ),
          title: Text(widget.profile['name'] ?? '名前なし'),
          subtitle: Row(
            children: [
              if (widget.profile['category'] != null)
                _buildTag(widget.profile['category']),
            ],
          ),
          trailing: IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.red : null,
            ),
            onPressed: () => _toggleFavorite(context),
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String tag) {
    return Container(
      margin: EdgeInsets.only(right: 4),
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(tag, style: TextStyle(fontSize: 12)),
    );
  }
}
