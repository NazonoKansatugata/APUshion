import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:apusion/model/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 認証まわりの状態や処理をまとめる。
class AuthViewModel extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // 現在ログイン中のユーザーを表す (nullの場合は未ログイン)
  UserModel? currentUser;

  // 運営ユーザーID
  static const String adminUid = '0jbF0jcGAaeWyOiZ75LzFbmfQK22';

  /// 運営判定メソッド
  bool isAdmin() {
    return currentUser != null && currentUser!.uid == adminUid;
  }

  /// メールアドレスでログイン
  Future<void> signInWithEmail(String email, String password) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;
      if (user != null) {
        currentUser = _convertToUserModel(user);
        await storeUserProfile(currentUser!);
        debugPrint("メールログイン成功: ${currentUser!.toJson()}");
      }
    } catch (e, st) {
      debugPrint("メールログイン失敗: $e\n$st");
      rethrow;
    }
    notifyListeners();
  }

  /// メールアドレスでアカウント作成
  Future<void> signUpWithEmail(String email, String password) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;
      if (user != null) {
        currentUser = _convertToUserModel(user);
        await storeUserProfile(currentUser!);
        debugPrint("メールでアカウント作成成功: ${currentUser!.toJson()}");
      }
    } catch (e, st) {
      debugPrint("メールでアカウント作成失敗: $e\n$st");
      rethrow;
    }
    notifyListeners();
  }

  /// ログアウト
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    currentUser = null;
    debugPrint("ログアウトしました。");
    notifyListeners();
  }

  Future<void> fetchUser() async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      currentUser = _convertToUserModel(user);
      debugPrint("ユーザー情報取得: ${currentUser!.toJson()}");
    }
    notifyListeners();
  }

  Future<void> storeUserProfile(UserModel usermodel) async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      final userRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);
      await userRef.set(usermodel.toJson());
      await userRef
          .collection('createdProfiles')
          .doc('null')
          .set({});
      await userRef
          .collection('likedProfiles')
          .doc('null')
          .set({});
      debugPrint("ユーザー情報をFirestoreに保存しました: ${usermodel.toJson()}");
    }
    notifyListeners();
  }

  /// パスワードリセット用
  Future<void> resetPassword(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
    debugPrint("$email へパスワードリセット用のメールを送信しました");
  }

  /// FirebaseのUser情報をUserModelに変換するヘルパー
  UserModel _convertToUserModel(User user) {
    return UserModel(
      name: user.displayName ?? 'No Name',
      email: user.email,
      isEmailVerified: user.emailVerified,
      isAnonymous: user.isAnonymous,
      phoneNumber: user.phoneNumber,
      photoURL: user.photoURL,
      refreshToken: user.refreshToken,
      tenantId: user.tenantId,
      uid: user.uid,
    );
  }

  /// ユーザーのプロフィール情報（name, photoURL）を更新する処理
  Future<void> updateUserProfile({
    String? name,
    String? photoURL,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      if (name != null || photoURL != null) {
        await user.updateProfile(
          displayName: name ?? user.displayName,
          photoURL: photoURL ?? user.photoURL,
        );
        await user.reload();
      }

      final userRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);
      final Map<String, dynamic> updatedData = {};
      if (name != null) updatedData['name'] = name;
      if (photoURL != null) updatedData['photoURL'] = photoURL;
      if (updatedData.isNotEmpty) {
        await userRef.update(updatedData);
      }

      if (currentUser != null) {
        currentUser!.name = name ?? currentUser!.name;
        currentUser!.photoURL = photoURL ?? currentUser!.photoURL;
      }
      debugPrint("ユーザープロフィールを更新しました: $updatedData");
      notifyListeners();
    } else {
      debugPrint("プロフィール更新に失敗: ユーザーが存在しません。");
    }
  }
}
