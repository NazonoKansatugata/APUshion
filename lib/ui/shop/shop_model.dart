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

  // Firestore から取得したデータを ShopVisit オブジェクトに変換
  factory ShopVisit.fromDocument(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ShopVisit(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '匿名ユーザー',
      product: data['product'] ?? '商品名なし',
      visitDate: data['visitDate'] ?? '未設定',
      store: data['store'] ?? '未設定',
      visitType: data['visitType'] ?? '不明',
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  // Firestore に保存するための Map に変換
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
