import 'package:cloud_firestore/cloud_firestore.dart';

class ShopVisit {
  String id;
  String userId;
  String userName;
  String product;
  String visitDate;
  String store;
  String visitType;
  Timestamp createdAt;

  ShopVisit({
    required this.id,
    required this.userId,
    required this.userName,
    required this.product,
    required this.visitDate,
    required this.store,
    required this.visitType,
    required this.createdAt,
  });

  // Firestore から取得したデータを ShopVisit オブジェクトに変換(Firestore to ShopVisit object)
  factory ShopVisit.fromDocument(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ShopVisit(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '匿名ユーザー(Anonymous User)',
      product: data['product'] ?? '商品名なし(No Product Name)',
      visitDate: data['visitDate'] ?? '未設定(Unset)',
      store: data['store'] ?? '未設定(Unset)',
      visitType: data['visitType'] ?? '不明(Unknown)',
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  // Firestore に保存するための Map に変換(Convert to Map for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'product': product,
      'visitDate': visitDate,
      'store': store,
      'visitType': visitType,
      'createdAt': createdAt,
    };
  }
}
