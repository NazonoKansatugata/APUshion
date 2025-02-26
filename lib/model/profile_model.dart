class ProfileModel {
  final String id;
  final String userId; // 出品者のユーザーID
  final String title; // 商品名
  final String description; // 商品説明
  final double price; // 価格
  final String category; // カテゴリ
  final String? imageUrl; // 商品画像URL
  final DateTime createdAt; // 出品日時
  final DateTime updatedAt; // 更新日時
  final String? condition; // 商品の状態（新品、未使用、良い、など）
  final bool isSold; // 商品が売れたかどうか
  
  ProfileModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
    this.condition,
    this.isSold = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'price': price,
      'category': category,
      'imageUrl': imageUrl,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'condition': condition,
      'isSold': isSold,
    };
  }
}
