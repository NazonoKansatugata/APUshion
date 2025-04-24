import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:apusion/ui/home/home_page.dart';
import 'dart:io';  // この行を追加

class CreateScreenViewModel extends ChangeNotifier {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController storeController = TextEditingController(text: '本店');
  final TextEditingController visitDateController = TextEditingController();
  String selectedCategory = '電子レンジ(microwave oven)';
  String selectedCondition = '新品(New)'; // 初期値を設定
  String selectedPickupMethod = '店舗受け取り(Store Pickup)'; // 初期値を設定
  List<String> imageUrls = [];
  bool isUploading = false;

  // 同意書のチェック状態を保持するプロパティ
  bool isAgreementChecked = false;

  // カテゴリーの選択
  void selectCategory(String category) {
    selectedCategory = category;
    notifyListeners();
  }

  // 商品の状態を選択
  void selectCondition(String condition) {
    selectedCondition = condition;
    notifyListeners();
  }

  // 画像の並び替え
  void reorderImages(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final String movedImage = imageUrls.removeAt(oldIndex);
    imageUrls.insert(newIndex, movedImage);
    notifyListeners();
  }

  // 画像の削除（インデックス指定）
  void removeImageAt(int index) async {
    if (index >= 0 && index < imageUrls.length) {
      final imageUrl = imageUrls[index];
      imageUrls.removeAt(index);
      notifyListeners();

      // Firebase Storage から画像を削除
      try {
        await FirebaseStorage.instance.refFromURL(imageUrl).delete();
        debugPrint('画像を削除しました(Deleted image): $imageUrl');
      } catch (e) {
        debugPrint('画像の削除に失敗しました(Failed to delete image): $e');
      }
    }
  }

  // 同意書のチェック状態を更新するメソッド
  void toggleAgreementChecked(bool value) {
    isAgreementChecked = value;
    notifyListeners();
  }

  // 画像をアップロードするメソッド
 Future<String?> uploadImage(String imagePath, BuildContext context) async {
  try {
    File file = File(imagePath);

    // 画像サイズをチェック（1MB = 1,048,576バイト）
    final int fileSize = await file.length();
    if (fileSize > 1048576) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('画像サイズが大きすぎます(Image size is too large): $fileSize bytes')),
      );
      return null;
    }

    // Firebase Storage にアップロード
    String fileName = 'images/${DateTime.now().millisecondsSinceEpoch}.jpg';
    TaskSnapshot uploadTask = await FirebaseStorage.instance.ref(fileName).putFile(file);

    // アップロード完了後に URL を取得
    String downloadUrl = await uploadTask.ref.getDownloadURL();
    return downloadUrl;
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('画像のアップロードに失敗しました(Failed to upload image): $e')),
    );
    return null;
  }
}



  // 新規作成時の保存処理
  // submitProfile メソッド内の修正
Future<void> submitProfile(BuildContext context, bool isAdmin) async {
  final productId = FirebaseFirestore.instance.collection('profiles').doc().id;
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  // 画像が選択されていればアップロード
  List<String> uploadedImageUrls = [];
  for (var i = 0; i < imageUrls.length; i++) {
    String? url = await uploadImage(imageUrls[i], context);  // 修正: 画像パスを渡す
    if (url != null) {
      uploadedImageUrls.add(url);
    }
  }

  // status を一般ユーザーは「下書き(draft)」、運営は「出品中(listed)」に設定
  final status = isAdmin ? '出品中(listed)' : '下書き(draft)';

  final productData = {
    'id': productId,
    'userId': user.uid,
    'userName': user.displayName ?? '匿名ユーザー',
    'name': nameController.text,
    'description': descriptionController.text,
    'price': double.tryParse(priceController.text) ?? 0.0,
    'category': selectedCategory,
    'condition': selectedCondition,
    'imageUrls': uploadedImageUrls.isEmpty ? imageUrls : uploadedImageUrls,
    'status': status,
    'store': storeController.text,
    'createdAt': Timestamp.now(),
    'updatedAt': Timestamp.now(),
  };

  try {
    // 1. 商品情報を Firestore の profiles コレクションに保存
    await FirebaseFirestore.instance.collection('profiles').doc(productId).set(productData);
    debugPrint('商品情報を保存しました(Saved product data): $productData');

    // 2. 商品情報を保存後、来店予定を作成
    if (!isAdmin) {
      await _addVisitSchedule(productId, user.uid, user.displayName ?? '匿名ユーザー');
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(isAdmin ? '出品しました(Listed)' : '下書きとして保存しました(Saved as draft)')),
    );
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => MainScreen()),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('保存に失敗しました(Failed to save): $e')),
    );
  }
}

  // 来店予定に商品IDを格納
  Future<void> _addVisitSchedule(String productId, String userId, String userName) async {
    final visitData = {
      'userId': userId,
      'userName': userName,
      'productId': productId,
      'product': nameController.text,
      'store': storeController.text,
      'visitDate': visitDateController.text,
      'visitType': 'listing',
      'pickupMethod': selectedPickupMethod, // 受け取り方法を追加
      'createdAt': Timestamp.now(),
    };

    await FirebaseFirestore.instance.collection('shopVisits').add(visitData);
    debugPrint('来店予定を保存しました(Saved visit schedule): $visitData');
  }

  // 更新処理
  Future<void> updateProfile(BuildContext context, String profileId, bool isAdmin) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final status = isAdmin ? '出品中(listed)' : '下書き(draft)';

    final productData = {
      'name': nameController.text,
      'description': descriptionController.text,
      'price': double.tryParse(priceController.text) ?? 0.0,
      'category': selectedCategory,
      'condition': selectedCondition,
      'imageUrls': imageUrls,
      'status': status,
      'store': storeController.text,
      'updatedAt': Timestamp.now(),
    };

    try {
      // Firestore の profiles コレクションを更新
      await FirebaseFirestore.instance.collection('profiles').doc(profileId).update(productData);

      // 古い来店予定を削除
      await _deleteVisitSchedule(profileId);

      if (!isAdmin) {
        // 新しい来店予定を作成
        await _addVisitSchedule(profileId, user.uid, user.displayName ?? '匿名ユーザー');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isAdmin ? '出品情報を更新しました(Listing updated)' : '下書きを更新しました(Draft updated)')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('更新に失敗しました(Failed to update): $e')),
      );
    }
  }

  // 出品中になった場合、来店予定を削除
  Future<void> _deleteVisitSchedule(String productId) async {
    final visitDocs = await FirebaseFirestore.instance
        .collection('shopVisits')
        .where('productId', isEqualTo: productId)
        .get();

    for (var doc in visitDocs.docs) {
      await doc.reference.delete();
    }
    debugPrint('来店予定を削除しました(Deleted visit schedule): productId=$productId');
  }

  // プロファイル削除処理
  Future<void> deleteProfile(BuildContext context, String profileId) async {
    try {
      // Firestore からプロファイルを取得
      final profileDoc = await FirebaseFirestore.instance.collection('profiles').doc(profileId).get();
      if (!profileDoc.exists) return;

      final profileData = profileDoc.data()!;
      final imageUrls = List<String>.from(profileData['imageUrls'] ?? []);

      // Firebase Storage 内の画像を削除
      for (var imageUrl in imageUrls) {
        try {
          await FirebaseStorage.instance.refFromURL(imageUrl).delete();
        } catch (e) {
          debugPrint('画像の削除に失敗しました(Failed to delete image): $e');
        }
      }

      // Firestore の profiles コレクションから削除
      await FirebaseFirestore.instance.collection('profiles').doc(profileId).delete();

      // 来店予定を削除
      await _deleteVisitSchedule(profileId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('プロファイルを削除しました(Profile deleted)')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('削除に失敗しました(Failed to delete): $e')),
      );
    }
  }

  void initializeData(Map<String, dynamic>? initialProfileData) {
    if (initialProfileData != null) {
      nameController.text = initialProfileData['name'] ?? '';
      descriptionController.text = initialProfileData['description'] ?? '';
      priceController.text = initialProfileData['price']?.toString() ?? '';
      selectedCategory = initialProfileData['category'] ?? selectedCategory; // カテゴリを初期化
      selectedCondition = initialProfileData['condition'] ?? selectedCondition;
      selectedPickupMethod = initialProfileData['pickupMethod'] ?? selectedPickupMethod;
      imageUrls = List<String>.from(initialProfileData['imageUrls'] ?? []);
      storeController.text = initialProfileData['store'] ?? '本店';
      visitDateController.text = initialProfileData['visitDate'] ?? ''; // 来店予定日を初期化
    }
    notifyListeners();
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
