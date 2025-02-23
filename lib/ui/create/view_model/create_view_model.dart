import 'package:flutter/material.dart';
import 'package:apusion/model/profile_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:apusion/ui/home/home_page.dart';
import 'package:apusion/ui/auth/view/auth_page.dart';

class CreateScreenViewModel extends ChangeNotifier {
  // 入力されるテキストを管理するコントローラー
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();
  final TextEditingController imageUrlController = TextEditingController();

  /// 商品を Firestore に保存する（新規作成）
  Future<void> submitProfile(BuildContext context) async {
    final profileId = FirebaseFirestore.instance.collection('profiles').doc().id;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      debugPrint('User is not logged in');
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => AuthPage()));
      return;
    }

    // 商品情報を保存するモデルを作成
    final profile = {
      'id': profileId,
      'userId': user.uid,
      'name': nameController.text,
      'description': descriptionController.text,
      'price': double.tryParse(priceController.text) ?? 0.0, // 数値として扱う
      'category': categoryController.text,
      'imageUrl': imageUrlController.text,
      'createdBy': user.uid,
      'createdAt': DateTime.now(),
      'updatedAt': DateTime.now(),
    };

    try {
      // Firestore に商品情報を保存
      await FirebaseFirestore.instance.collection('profiles').doc(profileId).set(profile);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('商品が保存されました')));
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => MainScreen()));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('保存に失敗しました: $e')));
    }
  }

  /// 商品情報を Firestore に更新する（編集）
  Future<void> updateProfile(BuildContext context, String profileId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('User is not logged in');
      return;
    }

    final profileUpdate = {
      'name': nameController.text,
      'description': descriptionController.text,
      'price': double.tryParse(priceController.text) ?? 0.0,
      'category': categoryController.text,
      'imageUrl': imageUrlController.text,
      'updatedAt': DateTime.now(),
    };

    try {
      await FirebaseFirestore.instance.collection('profiles').doc(profileId).update(profileUpdate);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('商品が更新されました')));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('更新に失敗しました: $e')));
    }
  }

  /// ViewModel を破棄するときにコントローラを解放
  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    categoryController.dispose();
    imageUrlController.dispose();
    super.dispose();
  }
}
