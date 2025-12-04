import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

// Import các màn hình
import 'login_screen.dart';
import 'register_screen.dart';
import 'home_screen.dart';
import 'admin_home_screen.dart'; // Đã mở khóa màn hình Admin

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Khởi tạo Firebase
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Tắt chữ Debug
      title: 'Nike Shoes Shop',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        // Dùng font Roboto để nhìn hiện đại hơn (nếu máy không có sẽ dùng font mặc định)
        fontFamily: 'Roboto',
      ),

      // 1. Màn hình chạy đầu tiên
      initialRoute: '/',

      // 2. Danh sách đường dẫn (Routes)
      routes: {
        '/': (context) => LoginScreen(),             // Màn hình đăng nhập
        '/register': (context) => RegisterScreen(),  // Màn hình đăng ký
        '/home': (context) => HomeScreen(),          // Màn hình chính (User/Khách)
        '/admin_home': (context) => AdminScreen(),   // Màn hình quản lý (Admin)
      },
    );
  }
}