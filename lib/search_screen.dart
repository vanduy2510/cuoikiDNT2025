import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'product_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          autofocus: true,
          decoration: InputDecoration(
            hintText: "Tìm kiếm giày (VD: Jordan, Air Max...)",
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey),
          ),
          style: TextStyle(color: Colors.black, fontSize: 18),
          onChanged: (value) {
            setState(() {
              searchQuery = value.toLowerCase().trim();
            });
          },
        ),
      ),
      body: searchQuery.isEmpty
          ? Center(
        // TRƯỜNG HỢP 1: CHƯA NHẬP GÌ -> HIỆN HÌNH ẢNH CHỜ
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 100, color: Colors.grey[300]),
            SizedBox(height: 20),
            Text("Nhập tên giày để tìm kiếm...", style: TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      )
          : StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('products').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          var allProducts = snapshot.data!.docs;

          // Logic lọc sản phẩm
          var filteredProducts = allProducts.where((doc) {
            var data = doc.data() as Map<String, dynamic>;
            String productName = (data['name'] ?? "").toString().toLowerCase();
            return productName.contains(searchQuery);
          }).toList();

          // TRƯỜNG HỢP 2: NHẬP RỒI NHƯNG KHÔNG THẤY -> HIỆN THÔNG BÁO
          if (filteredProducts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sentiment_dissatisfied, size: 80, color: Colors.grey),
                  SizedBox(height: 10),
                  Text("Không tìm thấy kết quả nào cho \"$searchQuery\"", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          // TRƯỜNG HỢP 3: CÓ KẾT QUẢ -> HIỆN DANH SÁCH
          return Padding(
            padding: const EdgeInsets.all(15.0),
            child: GridView.builder(
              itemCount: filteredProducts.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
              ),
              itemBuilder: (context, index) {
                var data = filteredProducts[index].data() as Map<String, dynamic>;
                data['id'] = filteredProducts[index].id;
                return _buildProductCard(data);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: product),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                child: Image.network(
                  product['img'] ?? "",
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey[200],
                    child: Icon(Icons.image_not_supported, color: Colors.grey),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'] ?? "Tên giày",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 5),
                  Text(
                    product['price'] ?? "Liên hệ",
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
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