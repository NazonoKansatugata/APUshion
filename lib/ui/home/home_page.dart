import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Auth をインポート

// 画面遷移のためのWidget
import 'package:apusion/ui/home/HomeScreen.dart';
import 'package:apusion/ui/create/view/create_page.dart';
import 'package:apusion/ui/favorite/favorite_page.dart';
import 'package:apusion/ui/home/ProfileCard.dart'; // プロフィールカードのインポート
import 'package:apusion/ui/home/ProfileDetailScreen.dart'; // プロフィール詳細画面
import 'package:apusion/ui/auth/view/auth_page.dart';
import 'package:apusion/ui/user/user_page.dart';
import 'package:apusion/ui/items/PurchasedItemsScreen.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    HomeScreen(),
    CreateScreen(),
    PurchasedItemsScreen(),
    FavoriteScreen(),
    UserScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("ぷろふぃーるはぶ",
            style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'ホーム'),
          BottomNavigationBarItem(icon: Icon(Icons.create), label: 'クリエイト'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: '購入済み'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'お気に入り'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'ユーザー'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.black,
        onTap: _onItemTapped,
      ),
    );
  }
}
