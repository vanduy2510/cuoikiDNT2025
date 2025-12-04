import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class EditProductScreen extends StatefulWidget {
  final Map<String, dynamic> productData;
  final String productId;

  EditProductScreen({required this.productData, required this.productId});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final nameController = TextEditingController();
  final priceController = TextEditingController();
  // Controller cho mô tả
  final descController = TextEditingController();

  final List<String> categories = ["Jordan", "Running", "Lifestyle", "Bóng rổ", "Đá bóng"];
  String selectedCategory = "Jordan";

  File? _newImageFile;
  String? imgData;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    // Đổ dữ liệu cũ vào các ô
    nameController.text = widget.productData['name'] ?? "";
    priceController.text = widget.productData['price'] ?? "";
    descController.text = widget.productData['description'] ?? "";
    imgData = widget.productData['img'] ?? "";

    String oldCat = widget.productData['category'] ?? "Jordan";
    if (categories.contains(oldCat)) selectedCategory = oldCat;
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (file != null) {
      final bytes = File(file.path).readAsBytesSync();
      setState(() {
        _newImageFile = File(file.path);
        imgData = base64Encode(bytes);
      });
    }
  }

  Future<void> updateProduct() async {
    if (nameController.text.isEmpty || priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Nhập đủ tên và giá!")));
      return;
    }
    setState(() => isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('products').doc(widget.productId).update({
        "name": nameController.text.trim(),
        "price": priceController.text.trim(),
        "description": descController.text.trim(),
        "img": imgData,
        "category": selectedCategory,
        "updateAt": Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Đã cập nhật!")));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  ImageProvider _getImageProvider() {
    if (_newImageFile != null) return FileImage(_newImageFile!);
    if (imgData != null && imgData!.isNotEmpty) {
      if (imgData!.startsWith('http')) return NetworkImage(imgData!);
      try { return MemoryImage(base64Decode(imgData!)); } catch (e) { return NetworkImage("https://via.placeholder.com/150"); }
    }
    return NetworkImage("https://via.placeholder.com/150");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Sửa thông tin"), backgroundColor: Colors.black),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              GestureDetector(
                onTap: pickImage,
                child: Container(
                  height: 200, width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200], borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey),
                    image: DecorationImage(image: _getImageProvider(), fit: BoxFit.cover),
                  ),
                  child: Align(alignment: Alignment.bottomRight, child: Container(padding: EdgeInsets.all(8), margin: EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle), child: Icon(Icons.edit, color: Colors.white))),
                ),
              ),
              SizedBox(height: 20),

              TextField(controller: nameController, decoration: InputDecoration(labelText: "Tên giày", border: OutlineInputBorder())),
              SizedBox(height: 15),

              TextField(controller: priceController, decoration: InputDecoration(labelText: "Giá bán", border: OutlineInputBorder())),
              SizedBox(height: 15),

              // Ô nhập mô tả
              TextField(
                controller: descController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: "Mô tả sản phẩm",
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              SizedBox(height: 20),

              DropdownButton<String>(
                value: selectedCategory, isExpanded: true,
                items: categories.map((String value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
                onChanged: (newValue) => setState(() => selectedCategory = newValue!),
              ),
              SizedBox(height: 40),

              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                  onPressed: isLoading ? null : updateProduct,
                  child: isLoading ? CircularProgressIndicator(color: Colors.white) : Text("LƯU THAY ĐỔI", style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}