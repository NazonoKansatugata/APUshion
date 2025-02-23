import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:apusion/ui/create/view_model/create_view_model.dart';
import 'package:apusion/ui/auth/view/auth_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:apusion/ui/home/home_page.dart';  // ここを確認してインポートしてください
import 'package:firebase_storage/firebase_storage.dart';

class CreateScreen extends StatelessWidget {
  final String? profileId; // 編集時に渡される商品ID
  final Map<String, dynamic>? initialProfileData; // 初期データ

  CreateScreen({Key? key, this.profileId, this.initialProfileData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final viewModel = CreateScreenViewModel();
        
        // 編集モードなら初期値をセット
        if (initialProfileData != null) {
          viewModel.nameController.text = initialProfileData!['name'] ?? '';
          viewModel.descriptionController.text = initialProfileData!['description'] ?? '';
          viewModel.priceController.text = initialProfileData!['price']?.toString() ?? '';
          viewModel.categoryController.text = initialProfileData!['category'] ?? '';
          viewModel.imageUrlController.text = initialProfileData!['imageUrl'] ?? '';
        }

        return viewModel;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(profileId != null ? "商品編集" : "商品作成"), // 編集ならタイトル変更
        ),
        body: Consumer<CreateScreenViewModel>(
          builder: (context, viewModel, child) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 商品名
                  TextField(
                    controller: viewModel.nameController,
                    decoration: InputDecoration(
                      labelText: "商品名",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // 商品説明
                  TextField(
                    controller: viewModel.descriptionController,
                    decoration: InputDecoration(
                      labelText: "商品説明",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 価格
                  TextField(
                    controller: viewModel.priceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "価格",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // カテゴリ
                  TextField(
                    controller: viewModel.categoryController,
                    decoration: InputDecoration(
                      labelText: "カテゴリ",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 画像URL
                  TextField(
                    controller: viewModel.imageUrlController,
                    decoration: InputDecoration(
                      labelText: "画像URL",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 画像選択ボタン
                  ElevatedButton(
                    onPressed: () => _pickImage(viewModel),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 25),
                    ),
                    child: const Text('画像を選択'),
                  ),
                  const SizedBox(height: 20),

                  // 出品ボタン
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        if (profileId == null) {
                          viewModel.submitProfile(context); // 新規作成
                        } else {
                          viewModel.updateProfile(context, profileId!); // 編集
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                      ),
                      child: const Text("決定！"),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // 画像アップロードの処理
  Future<void> _pickImage(CreateScreenViewModel viewModel) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result == null) {
      return;
    }
    final file = result.files.single;

    final storageRef = FirebaseStorage.instance.ref().child('uploads/${file.name}');
    final metadata = SettableMetadata(contentType: 'image/png');
    final uploadTask = storageRef.putData(file.bytes!, metadata);

    await uploadTask.whenComplete(() async {
      final downloadUrl = await storageRef.getDownloadURL();
      viewModel.imageUrlController.text = downloadUrl;
    });
  }
}
