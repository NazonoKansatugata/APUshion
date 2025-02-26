import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:apusion/ui/home/ProfileDetailScreen.dart'; 

class PurchasedItemsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text("購入済み商品")),
        body: Center(child: Text("ログインしてください")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text("購入済み商品")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('purchases')
            .where('buyerId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("購入した商品はありません"));
          }

          var purchasedItems = snapshot.data!.docs;

          return ListView.builder(
            itemCount: purchasedItems.length,
            itemBuilder: (context, index) {
              var purchase = purchasedItems[index].data() as Map<String, dynamic>;
              String productId = purchasedItems[index].id;

              return ListTile(
                title: Text("商品ID: $productId"),
                subtitle: Text("購入日: ${purchase['purchaseDate'].toDate()}"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileDetailScreen(documentId: productId),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
