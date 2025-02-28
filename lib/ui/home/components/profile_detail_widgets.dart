import 'package:flutter/material.dart';

/// プロフィールセクション
Widget buildProfileSection(String title, List<Widget> children) {
  return Container(
    margin: EdgeInsets.only(bottom: 16),
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        ...children,
      ],
    ),
  );
}

/// 情報行デザイン
Widget buildProfileRow(String label, dynamic value) {
  return Padding(
    padding: EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Text("$label: ", style: TextStyle(fontWeight: FontWeight.bold)),
        Expanded(child: Text(value != null ? value.toString() : '不明')),
      ],
    ),
  );
}

/// カテゴリータグ
Widget buildCategoryTag(String? category) {
  if (category == null || category.isEmpty) return SizedBox.shrink();
  return Chip(label: Text(category));
}
