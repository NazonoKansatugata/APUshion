import 'package:flutter/material.dart';
import 'package:apusion/model/profile_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:apusion/ui/home/home_page.dart';

class CreateScreenViewModel extends ChangeNotifier {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  String selectedCategory = '電子レンジ';
  List<String> imageUrls = [];

  void addImageUrl(String url) {
    if (imageUrls.length < 5) {
      imageUrls.add(url);
      notifyListeners();
    }
  }

  Future<void> removeImageUrl(String url) async {
    try {
      await FirebaseStorage.instance.refFromURL(url).delete();
      imageUrls.remove(url);
      notifyListeners();
    } catch (e) {
      debugPrint('画像の削除に失敗しました: $e');
    }
  }

  Future<void> submitProfile(BuildContext context) async {
    final profileId = FirebaseFirestore.instance.collection('profiles').doc().id;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      debugPrint('User is not logged in');
      return;
    }

    final profile = {
      'id': profileId,
      'userId': user.uid,
      'name': nameController.text,
      'description': descriptionController.text,
      'price': double.tryParse(priceController.text) ?? 0.0,
      'category': selectedCategory,
      'imageUrls': imageUrls,
      'createdAt': DateTime.now(),
      'updatedAt': DateTime.now(),
    };

    try {
      await FirebaseFirestore.instance.collection('profiles').doc(profileId).set(profile);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('商品が保存されました')));
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => MainScreen()));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('保存に失敗しました: $e')));
    }
  }

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
      'category': selectedCategory,
      'imageUrls': imageUrls,
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

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    super.dispose();
  }
}