import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passController = TextEditingController();
  bool _isObscured = true;
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    if (emailController.text.trim().isEmpty || passController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Vui lòng nhập đầy đủ thông tin")));
      return;
    }
    setState(() => isLoading = true);

    try {
      // 1. Đăng nhập vào Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passController.text.trim(),
      );

      User? user = userCredential.user;
      if (user != null) {
        // 2. Lấy thông tin từ Firestore để kiểm tra Role
        DocumentSnapshot userData = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

        if (userData.exists) {
          // --- ĐOẠN CODE QUAN TRỌNG VỪA THÊM VÀO ---
          String role = userData['role'] ?? 'user'; // Lấy role, mặc định là user

          print("Role của user là: $role"); // In ra log để kiểm tra

          if (role == 'admin') {
            // Nếu là admin -> Chuyển trang Admin
            Navigator.pushReplacementNamed(context, '/admin_home');
          } else {
            // Nếu là user thường -> Chuyển trang Home
            Navigator.pushReplacementNamed(context, '/home');
          }
          // ------------------------------------------
        } else {
          // Trường hợp user có trong Auth nhưng chưa có trong Firestore (lỗi dữ liệu)
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } on FirebaseAuthException catch (e) {
      String message = "Lỗi đăng nhập";
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        message = "Sai email hoặc mật khẩu";
      } else if (e.code == 'wrong-password') {
        message = "Sai mật khẩu";
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 25),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.network(
                "https://upload.wikimedia.org/wikipedia/commons/thumb/a/a6/Logo_NIKE.svg/1200px-Logo_NIKE.svg.png",
                height: 60, color: Colors.black,
              ),
              SizedBox(height: 40),
              Text("Chào mừng trở lại!", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              Text("Đăng nhập để tiếp tục mua sắm", style: TextStyle(fontSize: 16, color: Colors.grey)),
              SizedBox(height: 50),

              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: "Email",
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
              SizedBox(height: 20),

              TextField(
                controller: passController,
                obscureText: _isObscured,
                decoration: InputDecoration(
                  labelText: "Mật khẩu",
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isObscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _isObscured = !_isObscured;
                      });
                    },
                  ),
                ),
              ),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: Text("Quên mật khẩu?", style: TextStyle(color: Colors.black)),
                ),
              ),
              SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: isLoading ? null : login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 5,
                  ),
                  child: isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text("Đăng nhập", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Chưa có tài khoản? ", style: TextStyle(color: Colors.grey)),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, "/register"),
                    child: Text("Đăng ký ngay", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}