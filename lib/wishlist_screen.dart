import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'product_detail_screen.dart'; // Import để bấm vào xem chi tiết

class WishlistScreen extends StatefulWidget {
  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  User? user = FirebaseAuth.instance.currentUser;

  ImageProvider _getImageProvider(String? imgData) {
    if (imgData == null || imgData.isEmpty) {
      return NetworkImage("https://via.placeholder.com/150");
    }
    if (imgData.startsWith('http')) {
      return NetworkImage(imgData);
    }
    try {
      return MemoryImage(base64Decode(imgData));
    } catch (e) {
      return NetworkImage("https://via.placeholder.com/150");
    }
  }

  // Hàm xóa khỏi danh sách yêu thích
  void removeFromWishlist(String docId) {
    if (user != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('wishlist')
          .doc(docId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Đã xóa khỏi yêu thích")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Danh sách yêu thích ❤️", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      backgroundColor: Color(0xFFF5F5F5),
      body: user == null
          ? Center(child: Text("Vui lòng đăng nhập"))
          : StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .collection('wishlist')
            .orderBy('likedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 80, color: Colors.grey),
                  SizedBox(height: 10),
                  Text("Chưa có sản phẩm yêu thích nào", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          var wishlistDocs = snapshot.data!.docs;

          return ListView.builder(
            padding: EdgeInsets.all(15),
            itemCount: wishlistDocs.length,
            itemBuilder: (context, index) {
              String productId = wishlistDocs[index].id;

              // Lấy thông tin chi tiết sản phẩm từ collection 'products'
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('products').doc(productId).get(),
                builder: (context, productSnapshot) {
                  if (!productSnapshot.hasData) return SizedBox();

                  var productData = productSnapshot.data!.data() as Map<String, dynamic>?;
                  if (productData == null) return SizedBox(); // Sản phẩm có thể đã bị xóa

                  productData['id'] = productId; // Gán ID để truyền sang chi tiết

                  return Card(
                    margin: EdgeInsets.only(bottom: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: ListTile(
                      contentPadding: EdgeInsets.all(10),
                      leading: Container(
                        width: 60, height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey[100],
                          image: DecorationImage(
                            image: _getImageProvider(productData['img']),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      title: Text(
                          productData['name'] ?? "Tên sản phẩm",
                          style: TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 1, overflow: TextOverflow.ellipsis
                      ),
                      subtitle: Text(
                        productData['price'] ?? "Liên hệ",
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.delete_outline, color: Colors.grey),
                        onPressed: () => removeFromWishlist(productId),
                      ),
                      onTap: () {
                        // Chuyển sang màn hình chi tiết
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductDetailScreen(product: productData!),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}