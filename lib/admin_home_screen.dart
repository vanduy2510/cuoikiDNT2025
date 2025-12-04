import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'add_product_screen.dart';
import 'edit_product_screen.dart';

class AdminScreen extends StatefulWidget {
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  String adminName = "Admin";

  @override
  void initState() {
    super.initState();
    _loadAdminName();
  }

  void _loadAdminName() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        setState(() {
          adminName = userDoc['username'] ?? "Admin";
        });
      }
    }
  }

  void logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  void deleteProduct(String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Xác nhận xóa"),
        content: Text("Bạn có chắc muốn xóa giày này không?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Hủy")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              FirebaseFirestore.instance.collection('products').doc(docId).delete();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Đã xóa thành công")));
            },
            child: Text("Xóa", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Hàm xử lý ảnh
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Image.network(
            "https://upload.wikimedia.org/wikipedia/commons/thumb/a/a6/Logo_NIKE.svg/1200px-Logo_NIKE.svg.png",
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(icon: Icon(Icons.logout, color: Colors.black), onPressed: logout),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Chào mừng,", style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                Text("$adminName 🛡️", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                SizedBox(height: 5),
                Text("Quản lý kho hàng Nike", style: TextStyle(fontSize: 16, color: Colors.grey[800])),
              ],
            ),
          ),
          SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('products').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return Center(child: Text("Kho hàng trống!"));

                var documents = snapshot.data!.docs;

                return ListView.builder(
                  padding: EdgeInsets.all(10),
                  itemCount: documents.length,
                  itemBuilder: (context, index) {
                    var data = documents[index].data() as Map<String, dynamic>;
                    String docId = documents[index].id;

                    return Card(
                      margin: EdgeInsets.only(bottom: 10),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Row(
                          children: [
                            Container(
                              width: 80, height: 80,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey.shade200),
                                image: DecorationImage(
                                  image: _getImageProvider(data['img']),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(data['name'] ?? "Lỗi tên", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  SizedBox(height: 5),
                                  Text("${data['price']} đ", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
                                  Text(data['category'] ?? "---", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => EditProductScreen(productData: data, productId: docId)));
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete_outline, color: Colors.red),
                                  onPressed: () => deleteProduct(docId),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.black,
        icon: Icon(Icons.add, color: Colors.white),
        label: Text("Thêm Giày", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => AddProductScreen()));
        },
      ),
    );
  }
}