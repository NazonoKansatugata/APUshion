import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileDetailViewModel extends ChangeNotifier {
  String? currentUserId;
  bool isPurchased = false;
  String selectedPickupMethod = '店舗受け取り(Store Pickup)';

  Future<void> checkIfPurchased(String documentId) async {
    DocumentSnapshot profileSnapshot = await FirebaseFirestore.instance
        .collection('profiles')
        .doc(documentId)
        .get();

    if (profileSnapshot.exists) {
      isPurchased = profileSnapshot['status'] == '購入済み(purchased)';
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
          title: const Text('来店予定日を入力(Enter visit date)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: visitDateController,
                decoration: const InputDecoration(hintText: '例: 2024-01-01'),
              ),
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: '店舗受け取り(Store Pickup)',
                items: [
                  DropdownMenuItem(
                    value: '店舗受け取り(Store Pickup)',
                    child: Text('店舗受け取り(Store Pickup)'),
                  ),
                  DropdownMenuItem(
                    value: '配送(Delivery)',
                    child: Text('配送(Delivery)'),
                  ),
                ],
                onChanged: (value) {
                  // 選択された受け取り方法を保存
                  selectedPickupMethod = value!;
                },
                decoration: const InputDecoration(labelText: '受け取り方法(Pickup Method)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル(Cancel)'),
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
                      .update({'status': '購入済み(purchased)'});

                  await FirebaseFirestore.instance.collection('shopVisits').add({
                    'userId': currentUserId,
                    'userName':
                        FirebaseAuth.instance.currentUser!.displayName ?? '匿名ユーザー(Anonymous)',
                    'productId': documentId,
                    'product': profileData?['name'] ?? '商品名なし(No product name)',
                    'store': profileData?['store'] ?? '店舗情報なし(No store info)',
                    'visitDate': visitDateController.text,
                    'visitType': 'purchase',
                    'pickupMethod': selectedPickupMethod, // 受け取り方法を追加
                    'createdAt': Timestamp.now(),
                  });

                  isPurchased = true;
                  notifyListeners();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("購入が完了しました(Purchase completed)")),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("購入に失敗しました: $e")),
                  );
                }
              },
              child: const Text('購入(Purchase)'),
            ),
          ],
        );
      },
    );
  }
}
