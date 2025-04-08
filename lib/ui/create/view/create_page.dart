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
        appBar: AppBar(title: Text(profileId != null ? "商品編集(Edit Product)" : "商品作成(Create Product)")),
        body: Consumer<CreateScreenViewModel>(builder: (context, viewModel, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: viewModel.nameController,
                  decoration: InputDecoration(labelText: "商品名(Product Name)"),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: viewModel.descriptionController,
                  decoration: InputDecoration(labelText: "商品説明(Product Description)"),
                ),
                const SizedBox(height: 20),
                if (isAdmin)
                  TextField(
                    controller: viewModel.priceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: "価格(Price)"),
                  ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: viewModel.selectedCategory,
                  items: ['電子レンジ(microwave oven)', '冷蔵庫(refrigerator)', '洗濯機(washing machine)', 'その他(others)'].map((category) {
                    return DropdownMenuItem(value: category, child: Text(category));
                  }).toList(),
                  onChanged: (value) => viewModel.selectedCategory = value!,
                  decoration: InputDecoration(labelText: "カテゴリ(Category)"),
                ),
                const SizedBox(height: 20),
                Wrap(
                  children: [
                    ReorderableListView(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      onReorder: (oldIndex, newIndex) {
                        viewModel.reorderImages(oldIndex, newIndex);
                      },
                      children: [
                        for (int i = 0; i < viewModel.imageUrls.length; i++)
                          ListTile(
                            key: ValueKey(viewModel.imageUrls[i]),
                            leading: Image.network(viewModel.imageUrls[i], width: 80, height: 80),
                            trailing: IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                viewModel.removeImageAt(i);
                              },
                            ),
                          ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () => _pickImages(context, viewModel),
                      child: const Text('画像を選択（最大5枚）(Select Images, Max 5)'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                Column(
                  children: [
                    TextFormField(
                      controller: viewModel.visitDateController,
                      decoration: InputDecoration(
                        labelText: "来店予定日(Visit Date)",
                        suffixIcon: GestureDetector(
                          onTap: () async {
                            DateTime? selectedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2101),
                            );
                            if (selectedDate != null) {
                              viewModel.visitDateController.text = "${selectedDate.toLocal()}".split(' ')[0];
                            }
                          },
                          child: Icon(Icons.calendar_today),
                        ),
                      ),
                      readOnly: true,
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
                      decoration: InputDecoration(labelText: isAdmin ? "取り扱い店舗(Store)" : "来店店舗(Visit Store)"),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        _showAgreementDialog(context);
                      },
                      child: const Text("同意書を見る(View Agreement)"),
                    ),
                    const SizedBox(width: 20),
                    Checkbox(
                      value: viewModel.isAgreementChecked,
                      onChanged: (bool? value) {
                        viewModel.toggleAgreementChecked(value!);
                      },
                    ),
                    const Text("同意する(Agree)"),
                  ],
                ),
                const SizedBox(height: 20),

                Center(
                  child: ElevatedButton(
                    onPressed: viewModel.isAgreementChecked &&
                               viewModel.visitDateController.text.isNotEmpty &&
                               viewModel.nameController.text.isNotEmpty
                        ? () {
                            if (profileId == null) {
                              viewModel.submitProfile(context, isAdmin);
                            } else {
                              viewModel.updateProfile(context, profileId!, isAdmin);
                            }
                          }
                        : null,
                    child: const Text("決定！(Submit)"),
                  ),
                ),

                if (profileId != null)
                  Center(
                    child: ElevatedButton(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text("確認(Confirm)"),
                              content: const Text("本当に削除しますか？(Are you sure you want to delete this?)"),
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: const Text("キャンセル(Cancel)"),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  child: const Text("削除(Delete)"),
                                ),
                              ],
                            );
                          },
                        );

                        if (confirm == true) {
                          final viewModel = Provider.of<CreateScreenViewModel>(context, listen: false);
                          await viewModel.deleteProfile(context, profileId!);
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text("削除(Delete)"),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Future<void> _pickImages(BuildContext context, CreateScreenViewModel viewModel) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("エラー: ユーザーが認証されていません(Error: User is not authenticated)")),
      );
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );
    if (result == null) return;

    for (var file in result.files.take(5 - viewModel.imageUrls.length)) { // 最大5枚まで制限
      if (file.bytes == null || file.bytes!.length > 5242880) { // 5MBを超える場合はスキップ
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("画像サイズが大きすぎます(Image size is too large): ${file.bytes?.length ?? 0} bytes")),
        );
        continue;
      }

      final storageRef = FirebaseStorage.instance.ref().child('uploads/${user.uid}/${file.name}');
      try {
        final uploadTask = storageRef.putData(file.bytes!);
        await uploadTask.whenComplete(() async {
          final downloadUrl = await storageRef.getDownloadURL();

          // アップロード後にリストに追加
          viewModel.imageUrls.add(downloadUrl);
          viewModel.notifyListeners();

          debugPrint("画像のアップロードが成功しました: $downloadUrl");
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("画像のアップロードに失敗しました(Failed to upload image): $e")),
        );
      }
    }
  }

  Future<int?> _getInsertIndex(BuildContext context, int maxIndex) async {
    return showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        int? selectedIndex;
        return AlertDialog(
          title: const Text("画像の挿入位置を選択(Select Insert Position)"),
          content: DropdownButtonFormField<int>(
            value: selectedIndex,
            items: List.generate(maxIndex + 1, (index) {
              return DropdownMenuItem(value: index, child: Text("位置 $index (Position $index)"));
            }),
            onChanged: (value) {
              selectedIndex = value;
            },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text("キャンセル(Cancel)"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(selectedIndex),
              child: const Text("決定(Confirm)"),
            ),
          ],
        );
      },
    );
  }

  void _showAgreementDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("売買契約書(Sales Agreement)"),
          content: SingleChildScrollView(
            child: Text(agreementContent),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("閉じる(Close)"),
            ),
          ],
        );
      },
    );
  }
}
