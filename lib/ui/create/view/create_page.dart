import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:apusion/ui/create/view_model/create_view_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'agreement.dart';  // 同意書の内容をインポート

class CreateScreen extends StatelessWidget {
  final String? profileId;
  final Map<String, dynamic>? initialProfileData;

  CreateScreen({Key? key, this.profileId, this.initialProfileData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isAdmin = user?.uid == '0jbF0jcGAaeWyOiZ75LzFbmfQK22';

    return ChangeNotifierProvider(
      create: (_) {
        final viewModel = CreateScreenViewModel();
        if (initialProfileData != null) {
          viewModel.nameController.text = initialProfileData!['name'] ?? '';
          viewModel.descriptionController.text = initialProfileData!['description'] ?? '';
          viewModel.priceController.text = initialProfileData!['price']?.toString() ?? '';
          viewModel.selectedCategory = initialProfileData!['category'] ?? '';
          viewModel.imageUrls = List<String>.from(initialProfileData!['imageUrls'] ?? []);
          viewModel.storeController.text = initialProfileData!['store'] ?? '本店';
          viewModel.visitDateController.text = initialProfileData!['visitDate'] ?? '';
        }
        return viewModel;
      },
      child: Scaffold(
        appBar: AppBar(title: Text(profileId != null ? "商品編集" : "商品作成")),
        body: Consumer<CreateScreenViewModel>(builder: (context, viewModel, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: viewModel.nameController,
                  decoration: InputDecoration(labelText: "商品名"),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: viewModel.descriptionController,
                  decoration: InputDecoration(labelText: "商品説明"),
                ),
                const SizedBox(height: 20),
                if (isAdmin)
                  TextField(
                    controller: viewModel.priceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: "価格"),
                  ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: viewModel.selectedCategory,
                  items: ['電子レンジ', '冷蔵庫', '洗濯機'].map((category) {
                    return DropdownMenuItem(value: category, child: Text(category));
                  }).toList(),
                  onChanged: (value) => viewModel.selectedCategory = value!,
                  decoration: InputDecoration(labelText: "カテゴリ"),
                ),
                const SizedBox(height: 20),
                Wrap(
                  children: viewModel.imageUrls.map((imageUrl) {
                    return Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Image.network(imageUrl, width: 80, height: 80),
                    );
                  }).toList(),
                ),
                ElevatedButton(
                  onPressed: () => _pickImages(viewModel),
                  child: const Text('画像を選択（最大5枚）'),
                ),
                const SizedBox(height: 20),

                // 一般ユーザーと運営で異なるフィールド
                if (isAdmin)
                  DropdownButtonFormField<String>(
                    value: viewModel.storeController.text.isNotEmpty
                        ? viewModel.storeController.text
                        : '本店',
                    items: ['本店'].map((store) {
                      return DropdownMenuItem(value: store, child: Text(store));
                    }).toList(),
                    onChanged: (value) {
                      viewModel.storeController.text = value!;
                    },
                    decoration: InputDecoration(labelText: "取り扱い店舗"),
                  )
                else
                  Column(
                    children: [
                      // 来店予定日をTextFormFieldに設定
                      TextFormField(
                        controller: viewModel.visitDateController,
                        decoration: InputDecoration(
                          labelText: "来店予定日",
                          suffixIcon: GestureDetector(
                            onTap: () async {
                              // カレンダーを表示
                              DateTime? selectedDate = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime(2101),
                              );
                              if (selectedDate != null) {
                                // 選択された日付をTextFieldに設定
                                viewModel.visitDateController.text = "${selectedDate.toLocal()}".split(' ')[0];
                              }
                            },
                            child: Icon(Icons.calendar_today),
                          ),
                        ),
                        readOnly: true, // テキストの直接入力を無効化
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        value: viewModel.storeController.text.isNotEmpty
                            ? viewModel.storeController.text
                            : '本店',
                        items: ['本店'].map((store) {
                          return DropdownMenuItem(value: store, child: Text(store));
                        }).toList(),
                        onChanged: (value) {
                          viewModel.storeController.text = value!;
                        },
                        decoration: InputDecoration(labelText: "来店店舗"),
                      ),
                    ],
                  ),
                const SizedBox(height: 20),

                // 同意書の表示ボタンとチェックボックス
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        _showAgreementDialog(context);
                      },
                      child: const Text("同意書を見る"),
                    ),
                    const SizedBox(width: 20),
                    Checkbox(
                      value: viewModel.isAgreementChecked,
                      onChanged: (bool? value) {
                        viewModel.toggleAgreementChecked(value!);  // 同意書のチェック状態を更新
                      },
                    ),
                    const Text("同意する"),
                  ],
                ),
                const SizedBox(height: 20),

                Center(
                  child: ElevatedButton(
                    onPressed: viewModel.isAgreementChecked
                        ? () {
                            if (profileId == null) {
                              viewModel.submitProfile(context, isAdmin);
                            } else {
                              viewModel.updateProfile(context, profileId!, isAdmin);
                            }
                          }
                        : null,
                    child: const Text("決定！"),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Future<void> _pickImages(CreateScreenViewModel viewModel) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );
    if (result == null) return;

    for (var file in result.files.take(5)) {
      final storageRef = FirebaseStorage.instance.ref().child('uploads/${file.name}');
      final uploadTask = storageRef.putData(file.bytes!);
      await uploadTask.whenComplete(() async {
        final downloadUrl = await storageRef.getDownloadURL();
        viewModel.addImageUrl(downloadUrl);
      });
    }
  }

  // 同意書の内容を表示するダイアログ
  void _showAgreementDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("売買契約書"),
          content: SingleChildScrollView(
            child: Text(agreementContent),  // 同意書の内容を表示
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("閉じる"),
            ),
          ],
        );
      },
    );
  }
}
