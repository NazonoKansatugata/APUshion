import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileDetailViewModel extends ChangeNotifier {
  String? currentUserId;
  bool isPurchased = false;

  Future<void> checkIfPurchased(String documentId) async {
    DocumentSnapshot profileSnapshot = await FirebaseFirestore.instance
        .collection('profiles')
        .doc(documentId)
        .get();

    if (profileSnapshot.exists) {
      isPurchased = profileSnapshot['status'] == '購入済み';
      notifyListeners();
    }
  }

  Future<void> purchaseItem(
      BuildContext context, String documentId, Map<String, dynamic>? profileData) async {
    final TextEditingController visitDateController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('来店予定日を入力'),
          content: TextField(
            controller: visitDateController,
            decoration: const InputDecoration(hintText: '例: 2024-01-01'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await FirebaseFirestore.instance
                      .collection('purchases')
                      .doc(documentId)
                      .set({
                    'buyerId': currentUserId,
                    'purchaseDate': DateTime.now(),
                  });

                  await FirebaseFirestore.instance
                      .collection('profiles')
                      .doc(documentId)
                      .update({'status': '購入済み'});

                  await FirebaseFirestore.instance.collection('shopVisits').add({
                    'userId': currentUserId,
                    'userName':
                        FirebaseAuth.instance.currentUser!.displayName ?? '匿名ユーザー',
                    'productId': documentId,
                    'product': profileData?['name'] ?? '商品名なし',
                    'store': profileData?['store'] ?? '店舗情報なし',
                    'visitDate': visitDateController.text,
                    'visitType': 'purchase',
                    'createdAt': Timestamp.now(),
                  });

                  isPurchased = true;
                  notifyListeners();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("購入が完了しました")),
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
}
