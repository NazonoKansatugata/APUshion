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
    final transactionType = profileData?['transactionType'] ?? '買取(Purchase)';
    if (transactionType == '仲介(Mediation)') {
      _showMediationPurchaseDialog(context, documentId, profileData);
    } else {
      _showPurchaseDialog(context, documentId, profileData);
    }
  }

  void _showMediationPurchaseDialog(BuildContext context, String documentId, Map<String, dynamic>? profileData) {
    List<String> visitDates = []; // 複数の日付を管理
    final TextEditingController visitDatesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('仲介購入手続き(Mediation Purchase Process)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: visitDatesController,
                decoration: const InputDecoration(hintText: '例: 2024-01-01, 2024-01-08'),
                readOnly: true,
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  DateTime now = DateTime.now();
                  DateTime initialDate = now.add(Duration(days: (DateTime.wednesday - now.weekday + 7) % 7));

                  final DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: initialDate,
                    firstDate: now,
                    lastDate: now.add(Duration(days: 365)),
                    selectableDayPredicate: (date) {
                      return date.weekday == DateTime.wednesday;
                    },
                  );

                  if (pickedDate != null) {
                    final formattedDate = pickedDate.toLocal().toString().split(' ')[0];
                    if (!visitDates.contains(formattedDate)) {
                      visitDates.add(formattedDate);
                      visitDatesController.text = visitDates.join(', ');
                    }
                  }
                },
                child: const Text('カレンダーで日付を選択(Select dates from calendar)'),
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
                if (visitDates.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('少なくとも1つの日付を選択してください(Please select at least one date)')),
                  );
                  return;
                }

                try {
                  await FirebaseFirestore.instance.collection('shopVisits').add({
                    'userId': currentUserId ?? '', // 必須フィールドを確認
                    'userName': FirebaseAuth.instance.currentUser?.displayName ?? '匿名ユーザー(Anonymous)',
                    'sellerId': profileData?['userId'] ?? '', // 出品者のIDを追加
                    'productId': documentId,
                    'product': profileData?['name'] ?? '商品名なし(No product name)',
                    'store': profileData?['store'] ?? '店舗情報なし(No store info)',
                    'visitDate': visitDates.first, // 最初の日付を格納
                    'visitDates': visitDates, // 全ての日付を格納
                    'visitType': 'Mediation',
                    'createdAt': Timestamp.now(), // 型を明示
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

  void _showPurchaseDialog(BuildContext context, String documentId, Map<String, dynamic>? profileData) {
    List<String> visitDate = []; // visitDate をリストとして管理
    final TextEditingController visitDateController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('来店予定日を入力(Enter visit dates)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: visitDateController,
                decoration: const InputDecoration(hintText: '例: 2024-01-01, 2024-01-08'),
                readOnly: true,
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  DateTime now = DateTime.now();
                  DateTime initialDate = now.add(Duration(days: (DateTime.wednesday - now.weekday + 7) % 7));

                  final DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: initialDate,
                    firstDate: now,
                    lastDate: now.add(Duration(days: 365)),
                    selectableDayPredicate: (date) {
                      return date.weekday == DateTime.wednesday;
                    },
                  );

                  if (pickedDate != null) {
                    final formattedDate = pickedDate.toLocal().toString().split(' ')[0];
                    if (!visitDate.contains(formattedDate)) {
                      visitDate.add(formattedDate);
                      visitDateController.text = visitDate.join(', ');
                    }
                  }
                },
                child: const Text('カレンダーで日付を選択(Select dates from calendar)'),
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
                      .collection('profiles')
                      .doc(documentId)
                      .update({'status': '購入済み(purchased)'});

                  await FirebaseFirestore.instance.collection('shopVisits').add({
                    'userId': currentUserId,
                    'userName': FirebaseAuth.instance.currentUser!.displayName ?? '匿名ユーザー(Anonymous)',
                    'productId': documentId,
                    'product': profileData?['name'] ?? '商品名なし(No product name)',
                    'store': profileData?['store'] ?? '店舗情報なし(No store info)',
                    'visitDate': visitDate, // visitDate を保存
                    'visitType': 'purchase',
                    'pickupMethod': selectedPickupMethod,
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
