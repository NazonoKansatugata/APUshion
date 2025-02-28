import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  String id;
  String userId;
  String name;
  String description;
  double price;
  String category;
  List<String> imageUrls;
  String status;
  String store;
  String visitDate;
  Timestamp createdAt;
  Timestamp updatedAt;

  Product({
    required this.id,
    required this.userId,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.imageUrls,
    required this.status,
    required this.store,
    required this.visitDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Product.fromDocument(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '商品名なし',
      description: data['description'] ?? '説明なし',
      price: data['price']?.toDouble() ?? 0.0,
      category: data['category'] ?? '未分類',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      status: data['status'] ?? '下書き',
      store: data['store'] ?? '未設定',
      visitDate: data['visitDate'] ?? '未設定',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'imageUrls': imageUrls,
      'status': status,
      'store': store,
      'visitDate': visitDate,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
