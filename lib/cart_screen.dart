import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// 👇 Import màn hình thanh toán (QUAN TRỌNG)
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  User? user = FirebaseAuth.instance.currentUser;
  double totalPrice = 0;

  double parsePrice(String priceString) {
    try {
      String cleanPrice = priceString.replaceAll('.', '').replaceAll(' đ', '').trim();
      return double.parse(cleanPrice);
    } catch (e) {
      return 0;
    }
  }

  String formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.') + " đ";
  }

  void deleteItem(String docId) {
    if (user != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('cart')
          .doc(docId)
          .delete();
    }
  }

  ImageProvider _getImageProvider(String? imgData) {
    if (imgData == null || imgData.isEmpty) return NetworkImage("https://via.placeholder.com/150");
    if (imgData.startsWith('http')) return NetworkImage(imgData);
    try { return MemoryImage(base64Decode(imgData)); } catch (e) { return NetworkImage("https://via.placeholder.com/150"); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text("Giỏ hàng của bạn", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: user == null
          ? Center(child: Text("Vui lòng đăng nhập!"))
          : StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .collection('cart')
            .orderBy('createAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
                SizedBox(height: 10),
                Text("Giỏ hàng đang trống", style: TextStyle(fontSize: 18, color: Colors.grey)),
              ],
            ));
          }

          var documents = snapshot.data!.docs;

          totalPrice = 0;
          for (var doc in documents) {
            var data = doc.data() as Map<String, dynamic>;
            double p = parsePrice(data['price']);
            int q = data['quantity'] ?? 1;
            totalPrice += p * q;
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.all(15),
                  itemCount: documents.length,
                  itemBuilder: (context, index) {
                    var data = documents[index].data() as Map<String, dynamic>;
                    String docId = documents[index].id;

                    return Dismissible(
                      key: Key(docId),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.only(right: 20),
                        child: Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (direction) => deleteItem(docId),
                      child: Card(
                        margin: EdgeInsets.only(bottom: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        child: Padding(
                          padding: EdgeInsets.all(10),
                          child: Row(
                            children: [
                              Container(
                                width: 80, height: 80,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: Colors.grey[100],
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
                                    Text(data['name'] ?? "Sản phẩm", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    SizedBox(height: 5),
                                    Text("Size: ${data['size']} | SL: ${data['quantity']}", style: TextStyle(color: Colors.grey)),
                                    SizedBox(height: 5),
                                    Text(data['price'], style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.close, color: Colors.grey),
                                onPressed: () => deleteItem(docId),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Tổng cộng:", style: TextStyle(fontSize: 18, color: Colors.grey)),
                        Text(formatPrice(totalPrice), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        // 👇 LOGIC CHUYỂN TRANG THANH TOÁN Ở ĐÂY
                        onPressed: () {
                          if (totalPrice > 0) {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => CheckoutScreen(totalAmount: totalPrice)
                                )
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Giỏ hàng trống!")));
                          }
                        },
                        child: Text("THANH TOÁN NGAY", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}