import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:apusion/ui/home/home_page.dart';
import 'package:apusion/model/profile_model.dart';

class CreateScreenViewModel extends ChangeNotifier {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController storeController = TextEditingController(text: '本店');
  final TextEditingController visitDateController = TextEditingController();
  String selectedCategory = '電子レンジ';
  List<String> imageUrls = [];
  bool isUploading = false;

  // カテゴリーの選択
  void selectCategory(String category) {
    selectedCategory = category;
    notifyListeners();
  }

  // 画像の追加
  void addImageUrl(String url) {
    if (imageUrls.length < 5) {
      imageUrls.add(url);
      notifyListeners();
    }
  }

  // 画像の削除
  Future<void> removeImageUrl(String url) async {
    try {
      await FirebaseStorage.instance.refFromURL(url).delete();
      imageUrls.remove(url);
      notifyListeners();
    } catch (e) {
      debugPrint('画像の削除に失敗しました: $e');
    }
  }

  /// 新規作成時の保存処理
  Future<void> submitProfile(BuildContext context, bool isAdmin) async {
    final productId = FirebaseFirestore.instance.collection('profiles').doc().id;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // status を一般ユーザーは「下書き」、運営は「出品中」に設定
    final status = isAdmin ? '出品中' : '下書き';

    // 商品データを先に作成
    final productData = {
      'id': productId,
      'userId': user.uid,
      'userName': user.displayName ?? '匿名ユーザー',
      'name': nameController.text,
      'description': descriptionController.text,
      'price': double.tryParse(priceController.text) ?? 0.0,
      'category': selectedCategory,
      'imageUrls': imageUrls,
      'status': status,
      'store': storeController.text,
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    };

    try {
      // 1. 商品情報を Firestore の profiles コレクションに保存
      await FirebaseFirestore.instance.collection('profiles').doc(productId).set(productData);
      debugPrint('商品情報を保存しました: $productData');

      // 2. 商品情報を保存後、来店予定を作成
      if (!isAdmin) {
        await _addVisitSchedule(productId, user.uid, user.displayName ?? '匿名ユーザー');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isAdmin ? '出品しました' : '下書きとして保存しました')),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => MainScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存に失敗しました: $e')),
      );
    }
  }

  /// 来店予定に商品IDを格納
  Future<void> _addVisitSchedule(String productId, String userId, String userName) async {
    final visitData = {
      'userId': userId,
      'userName': userName,
      'productId': productId,
      'product': nameController.text,
      'store': storeController.text,
      'visitDate': visitDateController.text,
      'visitType': 'listing', // visitType を "listing" に設定
      'createdAt': Timestamp.now(),
    };

    await FirebaseFirestore.instance.collection('shopVisits').add(visitData);
    debugPrint('来店予定を保存しました: $visitData');
  }

  /// 更新処理
  Future<void> updateProfile(BuildContext context, String profileId, bool isAdmin) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // status を一般ユーザーは「下書き」、運営は「出品中」に設定
    final status = isAdmin ? '出品中' : '下書き';

    final productData = {
      'name': nameController.text,
      'description': descriptionController.text,
      'price': double.tryParse(priceController.text) ?? 0.0,
      'category': selectedCategory,
      'imageUrls': imageUrls,
      'status': status,
      'store': storeController.text,
      'updatedAt': Timestamp.now(),
    };

    try {
      // Firestore の profiles コレクションを更新
      await FirebaseFirestore.instance.collection('profiles').doc(profileId).update(productData);

      if (isAdmin) {
        // 運営の場合、出品中にしたら来店予定を削除
        await _deleteVisitSchedule(profileId);
      } else {
        // 一般ユーザーの場合、来店予定に商品IDを格納
        await _addVisitSchedule(profileId, user.uid, user.displayName ?? '匿名ユーザー');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isAdmin ? '出品情報を更新しました' : '下書きを更新しました')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('更新に失敗しました: $e')),
      );
    }
  }

  /// 出品中になった場合、来店予定を削除
  Future<void> _deleteVisitSchedule(String productId) async {
    final visitDocs = await FirebaseFirestore.instance
        .collection('shopVisits')
        .where('productId', isEqualTo: productId)
        .get();

    for (var doc in visitDocs.docs) {
      await doc.reference.delete();
    }
    debugPrint('来店予定を削除しました: productId=$productId');
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    storeController.dispose();
    visitDateController.dispose();
    super.dispose();
  }
}
