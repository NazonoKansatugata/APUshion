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
        viewModel.initializeData(initialProfileData); // 初期データを設定
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
                  decoration: InputDecoration(
                    labelText: "商品説明(Product Description)",
                    hintText: "例: メーカー、年数、特徴など (e.g., Manufacturer, Year, Features)",
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: viewModel.priceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: "価格(Price)"),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: viewModel.selectedCategory, // カテゴリの初期値を反映
                  items: ['電子レンジ(microwave oven)', '冷蔵庫(refrigerator)', '洗濯機(washing machine)', 'その他(others)'].map((category) {
                    return DropdownMenuItem(value: category, child: Text(category));
                  }).toList(),
                  onChanged: (value) => viewModel.selectedCategory = value!,
                  decoration: InputDecoration(labelText: "カテゴリ(Category)"),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: viewModel.selectedCondition,
                  items: [
                    '新品(New)',
                    '未使用に近い(Almost New)',
                    '目立った傷や汚れなし(No Noticeable Damage)',
                    'やや傷や汚れあり(Some Damage)',
                    '傷や汚れあり(Damaged)',
                    '全体的に状態が悪い(Poor Condition)',
                  ].map((condition) {
                    return DropdownMenuItem(value: condition, child: Text(condition));
                  }).toList(),
                  onChanged: (value) => viewModel.selectedCondition = value!,
                  decoration: InputDecoration(labelText: "商品の状態(Product Condition)"),
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
                const SizedBox(height: 20),

                DropdownButtonFormField<String>(
                  value: viewModel.selectedTransactionType,
                  items: [
                    DropdownMenuItem(
                      value: '買取(Purchase)',
                      child: Text('買取(Purchase)'),
                    ),
                    DropdownMenuItem(
                      value: '仲介(Mediation)',
                      child: Text('仲介(Mediation)'),
                    ),
                  ],
                  onChanged: (value) {
                    viewModel.selectedTransactionType = value!;
                    viewModel.notifyListeners(); // 状態を更新
                  },
                  decoration: const InputDecoration(labelText: '取引タイプ(Transaction Type)'),
                ),
                const SizedBox(height: 20),

                if (viewModel.selectedTransactionType == '買取(Purchase)') ...[
                  DropdownButtonFormField<String>(
                    value: viewModel.selectedPickupMethod.isNotEmpty ? viewModel.selectedPickupMethod : null,
                    items: [
                      DropdownMenuItem(
                        value: '店舗受け取り(Store Pickup)',
                        child: Text('店舗受け取り(Store Pickup)'),
                      ),
                      DropdownMenuItem(
                        value: '配送(Delivery)',
                        child: Text('配送(Delivery)'),
                      ),
                    ],
                    onChanged: (value) {
                      viewModel.selectedPickupMethod = value!;
                      viewModel.notifyListeners(); // 状態を更新
                    },
                    decoration: const InputDecoration(labelText: '受け取り方法(Pickup Method)'),
                  ),
                  if (viewModel.selectedPickupMethod == '配送(Delivery)')
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        '配送には500~1000円の送料がかかります(Delivery incurs a shipping fee of ¥500~¥1000)',
                        style: TextStyle(color: Colors.red, fontSize: 14),
                      ),
                    ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: viewModel.visitDateController,
                    decoration: InputDecoration(
                      labelText: viewModel.selectedPickupMethod == '配送(Delivery)'
                          ? '希望到着日(Desired Delivery Date)'
                          : '来店予定日(Visit Date)',
                      suffixIcon: GestureDetector(
                        onTap: () async {
                          DateTime? selectedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now().add(Duration(days: (DateTime.wednesday - DateTime.now().weekday + 7) % 7)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2101),
                            selectableDayPredicate: (date) {
                              return date.weekday == DateTime.wednesday;
                            },
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
                ],

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
                        ? () async {
                            if (viewModel.selectedPickupMethod == '配送(Delivery)') {
                              final user = FirebaseAuth.instance.currentUser;
                              if (user == null ||
                                  user.email == null ||
                                  user.email!.isEmpty ||
                                  user.displayName == null ||
                                  user.displayName!.isEmpty ||
                                  user.phoneNumber == null ||
                                  user.phoneNumber!.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      '配送を選択した場合、メールアドレス、本名、電話番号が必要です(Email, Full Name, and Phone Number are required for delivery)',
                                    ),
                                  ),
                                );
                                return;
                              }
                            }

                            if (profileId == null) {
                              await viewModel.submitProfile(context, isAdmin);
                            } else {
                              await viewModel.updateProfile(context, profileId!, isAdmin);
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
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );
    if (result == null) return;

    for (var file in result.files.take(5 - viewModel.imageUrls.length)) { // 最大5枚まで制限
      if (file.bytes == null || file.bytes!.length > 5242880) { // 5MBを超える場合はスキップ
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
