import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:apusion/model/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';

class AuthViewModel extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  UserModel? currentUser;

  static const String adminUid = '0jbF0jcGAaeWyOiZ75LzFbmfQK22';

  bool isAdmin() {
    return currentUser != null && currentUser!.uid == adminUid;
  }

  Future<void> signInWithEmail(String email, String password) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;
      if (user != null) {
        currentUser = await _convertToUserModel(user);
        await storeUserProfile(currentUser!);
      }
    } catch (e) {
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
        currentUser = await _convertToUserModel(user);
        await storeUserProfile(currentUser!);
      }
    } catch (e) {
      rethrow;
    }
    notifyListeners();
  }

  /// ログアウト
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    currentUser = null;
    notifyListeners();
  }

  Future<void> fetchUser() async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      currentUser = await _convertToUserModel(user);
    }
    notifyListeners();
  }

  Future<void> storeUserProfile(UserModel usermodel) async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      final userRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);
      await userRef.set(usermodel.toJson());
      await userRef.collection('likedProfiles').doc('null').set({});
    }
    notifyListeners();
  }

  /// パスワードリセット用
  Future<void> resetPassword(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  /// FirebaseのUser情報をUserModelに変換し、Firestoreの追加プロフィール情報もマージ
  Future<UserModel> _convertToUserModel(User user) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final firestoreData = doc.data();

    return UserModel(
      name: user.displayName ?? firestoreData?['name'] ?? 'No Name',
      email: user.email,
      isEmailVerified: user.emailVerified,
      isAnonymous: user.isAnonymous,
      phoneNumber: firestoreData?['phoneNumber'] ?? user.phoneNumber,
      photoURL: user.photoURL ?? firestoreData?['photoURL'],
      refreshToken: user.refreshToken,
      tenantId: user.tenantId,
      uid: user.uid,
      fullName: firestoreData?['fullName'],
      address: firestoreData?['address'],
    );
  }

  /// ユーザーのプロフィール情報（name, photoURL）を更新する処理
  Future<void> updateUserProfile({
    String? name,
    String? photoURL,
    String? fullName,
    String? address,
    String? phoneNumber,
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
      if (fullName != null) updatedData['fullName'] = fullName;
      if (address != null) updatedData['address'] = address;
      if (phoneNumber != null) updatedData['phoneNumber'] = phoneNumber;

      if (updatedData.isNotEmpty) {
        await userRef.update(updatedData);
      }

      // currentUser にも反映（nullチェック済み）
      if (currentUser != null) {
        currentUser!.name = name ?? currentUser!.name;
        currentUser!.photoURL = photoURL ?? currentUser!.photoURL;
        currentUser!.fullName = fullName ?? currentUser!.fullName;
        currentUser!.address = address ?? currentUser!.address;
        currentUser!.phoneNumber = phoneNumber ?? currentUser!.phoneNumber;
      }

      notifyListeners();
    }
  }

  /// LINEログイン (Web用)
  Future<void> signInWithLineWeb() async {
    try {
      // FirestoreからLINE設定を取得
      final settingsDoc = await FirebaseFirestore.instance.collection('settings').doc('line').get();
      final settings = settingsDoc.data();

      if (settings == null || !settings.containsKey('LINE_CHANNEL_ID') || !settings.containsKey('LINE_REDIRECT_URI')) {
        throw Exception("FirestoreにLINE設定が見つかりません。");
      }

      final clientId = settings['LINE_CHANNEL_ID'];
      final redirectUri = settings['LINE_REDIRECT_URI'];
      final state = "random_state_string"; // CSRF対策用のランダムな文字列

      final authUrl = Uri.https("access.line.me", "/oauth2/v2.1/authorize", {
        "response_type": "code",
        "client_id": clientId,
        "redirect_uri": redirectUri,
        "state": state,
        "scope": "profile openid email",
      }).toString();

      // Webブラウザで認証を開始
      final result = await FlutterWebAuth.authenticate(
        url: authUrl,
        callbackUrlScheme: Uri.parse(redirectUri).scheme,
      );

      // 認証コードを取得
      final code = Uri.parse(result).queryParameters['code'];
      if (code != null) {
        print("Authorization Code: $code");
        // ここでアクセストークンを取得し、ユーザー情報を取得する処理を追加できます
      }
    } catch (e) {
      print("LINEログインエラー: $e");
      rethrow;
    }
  }
}
