import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:apusion/ui/auth/view_model/auth_view_model.dart';
import 'package:apusion/ui/shop/shop_model.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({Key? key}) : super(key: key);

  @override
  _ShopScreenState createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final TextEditingController _visitDateController = TextEditingController();
  final TextEditingController _productController = TextEditingController();
  String _selectedStore = '未選択';
  final _formKey = GlobalKey<FormState>();

  final List<String> _stores = [
    '未選択',
    '本店',
    '支店A',
    '支店B',
  ];

  @override
  void dispose() {
    _visitDateController.dispose();
    _productController.dispose();
    super.dispose();
  }

  /// 来店予定の追加
  Future<void> _addVisit() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_formKey.currentState!.validate() && _selectedStore != '未選択') {
      ShopVisit visit = ShopVisit(
        id: '',
        userId: user.uid,
        userName: user.displayName ?? '匿名ユーザー',
        product: _productController.text,
        visitDate: _visitDateController.text,
        store: _selectedStore,
        visitType: 'listing',
        createdAt: Timestamp.now(),
      );

      await FirebaseFirestore.instance
          .collection('shopVisits')
          .add(visit.toMap());

      _visitDateController.clear();
      _productController.clear();
      setState(() {
        _selectedStore = '未選択';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('来店予定を追加しました')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('すべての項目を入力してください')),
      );
    }
  }

  /// 来店予定の削除
  Future<void> _deleteVisit(String documentId) async {
    await FirebaseFirestore.instance
        .collection('shopVisits')
        .doc(documentId)
        .delete();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('来店予定を削除しました')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ショップ")),
      body: Column(
        children: [
          Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  TextFormField(
                    controller: _productController,
                    decoration: const InputDecoration(
                      labelText: '商品名',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '商品名を入力してください';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _visitDateController,
                    decoration: const InputDecoration(
                      labelText: '来店予定日 (例: 2024-01-01)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '来店予定日を入力してください';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  DropdownButton<String>(
                    value: _selectedStore,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedStore = newValue!;
                      });
                    },
                    items: _stores.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _addVisit,
                    child: const Text('来店予定を追加'),
                  ),
                ],
              ),
            ),
          ),
          const Divider(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('shopVisits')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("来店予定はありません"));
                }

                var visits = snapshot.data!.docs
                    .map((doc) => ShopVisit.fromDocument(doc))
                    .toList();

                return ListView.builder(
                  itemCount: visits.length,
                  itemBuilder: (context, index) {
                    var visit = visits[index];
                    return ListTile(
                      title: Text(visit.product),
                      subtitle: Text("来店予定日: ${visit.visitDate}"),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
