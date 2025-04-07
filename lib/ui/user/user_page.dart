import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:apusion/model/user_model.dart';
import 'package:apusion/ui/auth/view_model/auth_view_model.dart';
import 'package:apusion/ui/auth/view/auth_page.dart';
import 'package:apusion/ui/user/user_proflile_page.dart';


class UserScreen extends StatefulWidget {
  const UserScreen({Key? key}) : super(key: key);

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  @override
  void initState() {
    super.initState();
    // 非同期処理のタイミングでfetchUser()を呼び出す
    Future.microtask(
        () => Provider.of<AuthViewModel>(context, listen: false).fetchUser());
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);
    final UserModel? user = authViewModel.currentUser;

    // ユーザーがログインしていればUserProfileScreen、未ログインならAuthPageを表示
    return user != null ? const UserProfileScreen() : const AuthPage();
  }
}