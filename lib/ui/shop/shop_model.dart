import 'package:cloud_firestore/cloud_firestore.dart';

class ShopVisit {
  String id;
  String userId;
  String userName;
  String product;
  List<String> visitDate; // visitDate をリスト形式に変更
  String store;
  String visitType;
  String pickupMethod; // 受け取り方法を追加
  Timestamp createdAt;

  ShopVisit({
    required this.id,
    required this.userId,
    required this.userName,
    required this.product,
    required this.visitDate,
    required this.store,
    required this.visitType,
    required this.pickupMethod, // コンストラクタに追加
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
      visitDate: (data['visitDate'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [], // 型変換を追加
      store: data['store'] ?? '未設定(Unset)',
      visitType: data['visitType'] ?? '不明(Unknown)',
      pickupMethod: data['pickupMethod'] ?? '未設定(Unset)',
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
      'pickupMethod': pickupMethod, // 受け取り方法を追加
      'createdAt': createdAt,
    };
  }
}
