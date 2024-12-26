import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mebelmart_furniture/pages/auth/login_page.dart';
import 'package:mebelmart_furniture/pages/admin/admin_home_page.dart';
import 'package:mebelmart_furniture/pages/customer/customer_home_page.dart';
import 'package:mebelmart_furniture/providers/app_state.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mebelmart_furniture/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  runApp(
    ChangeNotifierProvider(
      create: (context) => AppState(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MebelMart',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: Consumer<AppState>(
        builder: (context, appState, child) {
          if (!appState.isLoggedIn) {
            return const LoginPage();
          }
          final userData = appState.userData;
          if (userData != null && userData['user']['role'] == 'admin') {
            return const AdminHomePage();
          }
          return const CustomerHomePage();
        },
      ),
    );
  }
}
