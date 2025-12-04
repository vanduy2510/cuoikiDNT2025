import 'package:flutter/material.dart';
import 'chat_screen.dart'; // Import màn hình chat chính

class AiWelcomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Spacer(), // Đẩy nội dung vào giữa

              // 1. LOGO NIKE
              Image.network(
                "https://upload.wikimedia.org/wikipedia/commons/thumb/a/a6/Logo_NIKE.svg/1200px-Logo_NIKE.svg.png",
                width: 120,
                color: Colors.black, // Logo màu đen
              ),

              SizedBox(height: 40),

              // 2. HÌNH ẢNH MINH HỌA (Robot hoặc Giày)
              Container(
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  // Bạn có thể thay bằng ảnh robot đẹp hơn nếu có link
                  child: Icon(Icons.smart_toy_outlined, size: 120, color: Colors.black87),
                ),
              ),

              SizedBox(height: 40),

              // 3. TIÊU ĐỀ & SLOGAN
              Text(
                "NIKE AI ASSISTANT",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  fontFamily: 'Futura', // Font kiểu Nike (nếu có)
                ),
              ),
              SizedBox(height: 15),
              Text(
                "Bạn đang tìm đôi giày hoàn hảo?\nHãy để AI tư vấn size, màu sắc và phong cách phù hợp nhất cho bạn ngay hôm nay.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),

              Spacer(),

              // 4. NÚT BẮT ĐẦU (Màu đen chủ đạo)
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () {
                    // Chuyển sang màn hình Chat chính
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => ChatScreen())
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 5,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "BẮT ĐẦU TRÒ CHUYỆN",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      SizedBox(width: 10),
                      Icon(Icons.arrow_forward, color: Colors.white),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
