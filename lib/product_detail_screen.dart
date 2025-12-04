import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'cart_screen.dart'; // Import để chuyển trang giỏ hàng

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  ProductDetailScreen({required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> with SingleTickerProviderStateMixin {
  int selectedSize = 40;
  final List<int> sizes = [38, 39, 40, 41, 42, 43, 44];

  bool isAdding = false;

  // --- VARIABLES CHO ANIMATION ---
  late AnimationController _controller;
  final GlobalKey _imageKey = GlobalKey(); // Key để lấy vị trí ảnh sản phẩm
  final GlobalKey _cartKey = GlobalKey();  // Key để lấy vị trí icon giỏ hàng
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    // Khởi tạo controller cho animation (thời gian bay 0.8 giây)
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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

  // --- HÀM CHẠY HIỆU ỨNG BAY ---
  void _runAnimation() {
    try {
      // 1. Lấy vị trí bắt đầu (Ảnh sản phẩm)
      RenderBox? imageBox = _imageKey.currentContext?.findRenderObject() as RenderBox?;
      // 2. Lấy vị trí kết thúc (Icon giỏ hàng)
      RenderBox? cartBox = _cartKey.currentContext?.findRenderObject() as RenderBox?;

      if (imageBox == null || cartBox == null) return;

      Offset startPos = imageBox.localToGlobal(Offset.zero);
      Offset endPos = cartBox.localToGlobal(Offset.zero);
      Size imageSize = imageBox.size;

      // 3. Tạo Overlay (Lớp phủ lên trên cùng màn hình)
      _overlayEntry = OverlayEntry(
        builder: (context) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              // Tính toán vị trí hiện tại theo thời gian (từ 0.0 đến 1.0)
              double value = _controller.value;

              // Di chuyển theo đường cong (Parabol nhẹ hoặc thẳng)
              double dx = startPos.dx + (endPos.dx - startPos.dx) * value;
              double dy = startPos.dy + (endPos.dy - startPos.dy) * value;

              // Thu nhỏ dần từ 1.0 xuống 0.1
              double scale = 1.0 - (value * 0.9);

              // Mờ dần ở đoạn cuối
              double opacity = (1.0 - value).clamp(0.0, 1.0);

              return Positioned(
                top: dy,
                left: dx,
                child: Opacity(
                  opacity: opacity,
                  child: Transform.scale(
                    scale: scale,
                    child: Material(
                      elevation: 5,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: imageSize.width,
                        height: imageSize.height,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          image: DecorationImage(
                            image: _getImageProvider(widget.product['img']),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      );

      // 4. Chèn Overlay vào màn hình và chạy
      Overlay.of(context).insert(_overlayEntry!);
      _controller.forward(from: 0.0).then((_) {
        // Chạy xong thì xóa Overlay đi
        _overlayEntry?.remove();
        _overlayEntry = null;
      });

    } catch (e) {
      print("Lỗi Animation: $e");
    }
  }

  Future<void> addToCart() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Vui lòng đăng nhập!")));
      return;
    }

    // 🔥 CHẠY ANIMATION BAY VÀO GIỎ
    _runAnimation();

    setState(() => isAdding = true);

    try {
      String cartItemId = "${widget.product['id']}_$selectedSize";
      DocumentReference cartItemRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .doc(cartItemId);

      DocumentSnapshot doc = await cartItemRef.get();

      if (doc.exists) {
        await cartItemRef.update({'quantity': FieldValue.increment(1)});
      } else {
        await cartItemRef.set({
          'name': widget.product['name'],
          'price': widget.product['price'],
          'img': widget.product['img'],
          'size': selectedSize,
          'quantity': 1,
          'productId': widget.product['id'],
          'createAt': Timestamp.now(),
        });
      }

      // Chờ 1 chút cho animation bay xong rồi mới hiện thông báo
      await Future.delayed(Duration(milliseconds: 800));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Đã thêm vào giỏ hàng!")));

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    } finally {
      setState(() => isAdding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. ẢNH NỀN (Gắn Key _imageKey để biết vị trí bắt đầu bay)
          Positioned(
            top: 0, left: 0, right: 0,
            height: MediaQuery.of(context).size.height * 0.5,
            child: Container(
              key: _imageKey, // 📍 QUAN TRỌNG: Đánh dấu vị trí ảnh
              color: Color(0xFFF5F5F5),
              child: Hero(
                tag: widget.product['name'] ?? 'unknown',
                child: Image(
                  image: _getImageProvider(widget.product['img']),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // 2. HEADER (Back + Cart Icon)
          Positioned(
            top: 40, left: 20, right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                // Thay icon tim bằng Giỏ hàng để có đích đến cho animation
                CircleAvatar(
                  key: _cartKey, // 📍 QUAN TRỌNG: Đánh dấu đích đến
                  backgroundColor: Colors.white,
                  child: IconButton(
                    icon: Icon(Icons.shopping_cart_outlined, color: Colors.black),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => CartScreen()));
                    },
                  ),
                ),
              ],
            ),
          ),

          // 3. THÔNG TIN CHI TIẾT
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.55,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (widget.product['category'] ?? "Giày").toUpperCase(),
                              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 5),
                            Text(
                              widget.product['name'] ?? "Tên sản phẩm",
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                              maxLines: 2, overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        "${widget.product['price']}",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),

                  Text("Chọn Size", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(height: 10),
                  SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: sizes.length,
                      itemBuilder: (context, index) {
                        bool isSelected = selectedSize == sizes[index];
                        return GestureDetector(
                          onTap: () => setState(() => selectedSize = sizes[index]),
                          child: Container(
                            margin: EdgeInsets.only(right: 10),
                            width: 50,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.black : Colors.grey[200],
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              "${sizes[index]}",
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 20),

                  Text("Mô tả", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(height: 5),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        widget.product['description'] ??
                            "Sản phẩm chính hãng từ Nike. Thiết kế hiện đại, êm ái giúp bạn tự tin trên mọi nẻo đường. Chất liệu cao cấp, bền bỉ.",
                        style: TextStyle(color: Colors.grey[600], height: 1.5),
                      ),
                    ),
                  ),

                  SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      onPressed: isAdding ? null : addToCart,
                      child: isAdding
                          ? CircularProgressIndicator(color: Colors.white)
                          : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_cart, color: Colors.white),
                          SizedBox(width: 10),
                          Text("THÊM VÀO GIỎ HÀNG", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}