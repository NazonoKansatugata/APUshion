class UserModel {
  String name;
  final String? email;
  final bool? isEmailVerified;
  final bool? isAnonymous;
  String? phoneNumber;
  String? photoURL;
  final String? refreshToken;
  final String? tenantId;
  final String? uid;

  // 新しく追加するフィールド
  String? fullName;   // 本名
  String? address;    // 住所

  UserModel({
    required this.name,
    this.email,
    this.isEmailVerified,
    this.isAnonymous,
    this.phoneNumber,
    this.photoURL,
    this.refreshToken,
    this.tenantId,
    this.uid,
    this.fullName,
    this.address,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'isEmailVerified': isEmailVerified,
      'isAnonymous': isAnonymous,
      'phoneNumber': phoneNumber,
      'photoURL': photoURL,
      'refreshToken': refreshToken,
      'tenantId': tenantId,
      'uid': uid,
      'fullName': fullName,
      'address': address,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      name: json['name'] ?? '',
      email: json['email'],
      isEmailVerified: json['isEmailVerified'],
      isAnonymous: json['isAnonymous'],
      phoneNumber: json['phoneNumber'],
      photoURL: json['photoURL'],
      refreshToken: json['refreshToken'],
      tenantId: json['tenantId'],
      uid: json['uid'],
      fullName: json['fullName'],
      address: json['address'],
    );
  }
}
