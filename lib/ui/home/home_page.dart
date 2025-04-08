import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

// 画面遷移のためのWidget
import 'package:apusion/ui/home/HomeScreen.dart';
import 'package:apusion/ui/create/view/create_page.dart';
import 'package:apusion/ui/home/ProfileCard.dart';
import 'package:apusion/ui/home/ProfileDetailScreen.dart';
import 'package:apusion/ui/auth/view/auth_page.dart';
import 'package:apusion/ui/user/user_page.dart';
import 'package:apusion/ui/shop/ShopScreen.dart'; // ShopScreen をインポート
import 'package:apusion/ui/admin/user_list_screen.dart'; // 新しい画面をインポート

// AuthViewModel をインポート
import 'package:apusion/ui/auth/view_model/auth_view_model.dart';
import 'package:apusion/ui/home/help_texts.dart'; // ヘルプテキストをインポート

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // 管理者用の画面
  final List<Widget> _adminScreens = [
    HomeScreen(),
    CreateScreen(),
    ShopScreen(),
    UserListScreen(), // 一般ユーザー情報画面を追加
    UserScreen(),
  ];

  // 一般ユーザー用の画面
  final List<Widget> _userScreens = [
    HomeScreen(),
    ShopScreen(),
    UserScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final bool isAdmin = authVM.isAdmin();

    // ナビゲーションバーのアイテムを管理者用と一般ユーザー用に分ける
    final adminNavItems = const [
      BottomNavigationBarItem(icon: Icon(Icons.home), label: 'ホーム'),
      BottomNavigationBarItem(icon: Icon(Icons.create), label: 'クリエイト'),
      BottomNavigationBarItem(icon: Icon(Icons.store), label: 'ショップ'),
      BottomNavigationBarItem(icon: Icon(Icons.list), label: 'ユーザー一覧'), // 新しいアイテム
      BottomNavigationBarItem(icon: Icon(Icons.person), label: 'ユーザー'),
    ];

    final userNavItems = const [
      BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
      BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Shop'),
      BottomNavigationBarItem(icon: Icon(Icons.person), label: 'User'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "APUshion",
          style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text("どの画面の説明を表示しますか？"),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          title: const Text("ホーム画面"),
                          onTap: () {
                            Navigator.of(context).pop();
                            _showHelpDialog(context, HelpTexts.home);
                          },
                        ),
                        ListTile(
                          title: const Text("ショップ画面"),
                          onTap: () {
                            Navigator.of(context).pop();
                            _showHelpDialog(context, HelpTexts.shop);
                          },
                        ),
                        ListTile(
                          title: const Text("ユーザー画面"),
                          onTap: () {
                            Navigator.of(context).pop();
                            _showHelpDialog(context, HelpTexts.user);
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: isAdmin
          ? _adminScreens[_selectedIndex]
          : _userScreens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: isAdmin ? adminNavItems : userNavItems,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.black,
        onTap: _onItemTapped,
      ),
    );
  }

  void _showHelpDialog(BuildContext context, String helpText) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("画面の説明"),
          content: Text(helpText),
          actions: [
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
