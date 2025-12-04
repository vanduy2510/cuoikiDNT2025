import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// 👇 IMPORT TẤT CẢ CÁC MÀN HÌNH CHỨC NĂNG
import 'chat_screen.dart';
import 'product_detail_screen.dart';
import 'cart_screen.dart';
import 'search_screen.dart';
import 'order_history_screen.dart';
import 'ai_welcome_screen.dart';
import 'wishlist_screen.dart'; // 👈 NHỚ IMPORT FILE NÀY

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String currentUserName = "";
  String currentUserImg = "";

  final List<String> categories = ["Tất cả", "Jordan", "Running", "Lifestyle", "Bóng rổ", "Đá bóng"];
  int selectedCategoryIndex = 0;

  @override
  void initState() {
    super.initState();
    getUserData();
  }

  void getUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (mounted && userDoc.exists) {
          setState(() {
            currentUserName = userDoc['username'] ?? user.email ?? "";
            currentUserImg = userDoc['img'] ?? "";
          });
        }
      } catch (e) { print(e); }
    }
  }

  void logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  ImageProvider _getUserAvatar(String? imgData) {
    if (imgData == null || imgData.isEmpty) {
      return NetworkImage("https://i.pravatar.cc/300");
    }
    if (imgData.startsWith('http')) {
      return NetworkImage(imgData);
    }
    try {
      return MemoryImage(base64Decode(imgData));
    } catch (e) {
      return NetworkImage("https://i.pravatar.cc/300");
    }
  }

  ImageProvider _getProductImage(String? imgData) {
    if (imgData == null || imgData.isEmpty) {
      return NetworkImage("https://via.placeholder.com/150?text=No+Image");
    }
    if (imgData.startsWith('http')) {
      return NetworkImage(imgData);
    }
    try {
      return MemoryImage(base64Decode(imgData));
    } catch (e) {
      return NetworkImage("https://via.placeholder.com/150?text=Error");
    }
  }

  // --- HÀM XỬ LÝ YÊU THÍCH (LIKE) ---
  Future<void> toggleFavorite(String productId, bool isLiked) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    DocumentReference favRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('wishlist')
        .doc(productId);

    if (isLiked) {
      await favRef.delete();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Đã xóa khỏi yêu thích"), duration: Duration(seconds: 1)));
    } else {
      await favRef.set({
        'likedAt': Timestamp.now(),
        'productId': productId
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Đã thêm vào yêu thích ❤️"), duration: Duration(seconds: 1)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Image.network("https://upload.wikimedia.org/wikipedia/commons/thumb/a/a6/Logo_NIKE.svg/1200px-Logo_NIKE.svg.png"),
        ),
        actions: [
          // 1. Nút Tìm kiếm
          IconButton(
              icon: Icon(Icons.search, color: Colors.black),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SearchScreen()))
          ),

          // 2. Nút Yêu thích (Wishlist) - MỚI THÊM
          IconButton(
              icon: Icon(Icons.favorite_border, color: Colors.black),
              tooltip: "Danh sách yêu thích",
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => WishlistScreen()))
          ),

          // 3. Nút Lịch sử đơn hàng
          IconButton(
              icon: Icon(Icons.receipt_long_outlined, color: Colors.black),
              tooltip: "Đơn hàng của tôi",
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => OrderHistoryScreen()))
          ),

          // 4. Nút Giỏ hàng (Có Badge)
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(FirebaseAuth.instance.currentUser?.uid)
                .collection('cart')
                .snapshots(),
            builder: (context, snapshot) {
              int cartCount = 0;
              if (snapshot.hasData) {
                for (var doc in snapshot.data!.docs) {
                  cartCount += (doc['quantity'] as num).toInt();
                }
              }

              return Stack(
                children: [
                  IconButton(
                      icon: Icon(Icons.shopping_bag_outlined, color: Colors.black),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => CartScreen()))
                  ),
                  if (cartCount > 0)
                    Positioned(
                      right: 5, top: 5,
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        constraints: BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text('$cartCount', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                      ),
                    )
                ],
              );
            },
          ),

          // 5. Nút Đăng xuất
          IconButton(icon: Icon(Icons.logout, color: Colors.black), onPressed: logout),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(20, 10, 20, 20),
            width: double.infinity,
            child: Row(
              children: [
                Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300, width: 2),
                    image: DecorationImage(image: _getUserAvatar(currentUserImg), fit: BoxFit.cover),
                  ),
                ),
                SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Chào mừng trở lại,", style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                      Text(currentUserName.isEmpty ? "..." : currentUserName, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10),

          Container(
            height: 50,
            padding: EdgeInsets.only(left: 15),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => setState(() => selectedCategoryIndex = index),
                  child: Container(
                    margin: EdgeInsets.only(right: 15),
                    padding: EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                    decoration: BoxDecoration(
                      color: selectedCategoryIndex == index ? Colors.black : Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(categories[index], style: TextStyle(color: selectedCategoryIndex == index ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 15),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('products').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return Center(child: Text("Chưa có sản phẩm"));

                  var documents = snapshot.data!.docs;
                  if (selectedCategoryIndex != 0) {
                    String selectedCat = categories[selectedCategoryIndex];
                    documents = documents.where((doc) {
                      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                      return data['category'] == selectedCat;
                    }).toList();
                  }

                  return GridView.builder(
                    itemCount: documents.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.7, crossAxisSpacing: 15, mainAxisSpacing: 15),
                    itemBuilder: (context, index) {
                      var data = documents[index].data() as Map<String, dynamic>;
                      data['id'] = documents[index].id;

                      return _buildProductCard(data);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AiWelcomeScreen())),
        backgroundColor: Colors.black,
        icon: Icon(Icons.auto_awesome, color: Colors.white),
        label: Text("Tư vấn AI", style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    String productId = product['id'];
    User? user = FirebaseAuth.instance.currentUser;

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProductDetailScreen(product: product))),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      color: Colors.grey[100],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      child: Hero(
                        tag: productId,
                        child: Image(image: _getProductImage(product['img']), fit: BoxFit.cover),
                      ),
                    ),
                  ),

                  // Nút Thả Tim trên từng sản phẩm
                  Positioned(
                    top: 5, right: 5,
                    child: StreamBuilder<DocumentSnapshot>(
                      stream: user != null
                          ? FirebaseFirestore.instance.collection('users').doc(user.uid).collection('wishlist').doc(productId).snapshots()
                          : null,
                      builder: (context, snapshot) {
                        bool isLiked = snapshot.hasData && snapshot.data!.exists;

                        return IconButton(
                          icon: Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            color: isLiked ? Colors.red : Colors.black,
                            size: 20,
                          ),
                          onPressed: () => toggleFavorite(productId, isLiked),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text((product['category'] ?? "Giày").toUpperCase(), style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text(product['name'] ?? "Tên sản phẩm", maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(product['price'] ?? "Liên hệ", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      Icon(Icons.add_circle, color: Colors.black),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}