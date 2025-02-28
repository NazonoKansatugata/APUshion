import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:apusion/ui/create/view/create_page.dart';
import 'package:apusion/ui/home/view_model/profile_detail_view_model.dart';
import 'package:apusion/ui/home/components/profile_detail_widgets.dart';

class ProfileDetailScreen extends StatefulWidget {
  final String documentId;

  ProfileDetailScreen({required this.documentId});

  @override
  _ProfileDetailScreenState createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen> {
  Map<String, dynamic>? profileData;
  bool isOwner = false;

  @override
  void initState() {
    super.initState();
    _checkIfOwner();
  }

  Future<void> _checkIfOwner() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    DocumentSnapshot profileSnapshot = await FirebaseFirestore.instance
        .collection('profiles')
        .doc(widget.documentId)
        .get();

    if (profileSnapshot.exists) {
      setState(() {
        profileData = profileSnapshot.data() as Map<String, dynamic>;
        isOwner = profileData!['userId'] == user.uid;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileDetailViewModel(),
      child: Consumer<ProfileDetailViewModel>(
        builder: (context, viewModel, child) {
          viewModel.checkIfPurchased(widget.documentId);

          return Scaffold(
            appBar: AppBar(title: const Text("商品詳細")),
            body: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    buildProfileSection("商品情報", [
                      buildProfileRow("商品名", profileData?['name'] ?? '商品名なし'),
                      buildCategoryTag(profileData?['category']),
                      buildProfileRow("価格", profileData?['price'] != null ? '¥${profileData?['price']}' : '不明'),
                      buildProfileRow("説明", profileData?['description']),
                      buildProfileRow("作成日", profileData?['createdAt']?.toDate().toString() ?? '不明'),
                    ]),

                    SizedBox(height: 16),

                    isOwner
                        ? ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CreateScreen(
                                    profileId: widget.documentId,
                                    initialProfileData: profileData!,
                                  ),
                                ),
                              );
                            },
                            child: const Text("編集する"),
                          )
                        : viewModel.isPurchased
                            ? ElevatedButton(
                                onPressed: () {}, 
                                child: const Text("購入取り消し"),
                              )
                            : ElevatedButton(
                                onPressed: () {
                                  viewModel.purchaseItem(context, widget.documentId, profileData);
                                },
                                child: const Text("購入する"),
                              ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
