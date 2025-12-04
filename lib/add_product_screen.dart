import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class AddProductScreen extends StatefulWidget {
  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final nameController = TextEditingController();
  final priceController = TextEditingController();

  // Có danh mục "Đá bóng"
  final List<String> categories = ["Jordan", "Running", "Lifestyle", "Bóng rổ", "Đá bóng"];
  String selectedCategory = "Jordan";

  File? _imageFile;
  String? imgBase64;
  bool isLoading = false;

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (file != null) {
      final bytes = File(file.path).readAsBytesSync();
      setState(() {
        _imageFile = File(file.path);
        imgBase64 = base64Encode(bytes);
      });
    }
  }

  Future<void> addProduct() async {
    if (nameController.text.isEmpty || priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Vui lòng nhập tên và giá!")));
      return;
    }
    if (imgBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Vui lòng chọn ảnh sản phẩm!")));
      return;
    }

    setState(() => isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('products').add({
        "name": nameController.text.trim(),
        "price": priceController.text.trim(),
        "img": imgBase64,
        "category": selectedCategory,
        "createAt": Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Thêm giày thành công!")));
      Navigator.pop(context);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Thêm giày mới"), backgroundColor: Colors.black),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              GestureDetector(
                onTap: pickImage,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.grey),
                    image: _imageFile != null ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover) : null,
                  ),
                  child: _imageFile == null
                      ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.camera_alt, size: 50, color: Colors.grey), Text("Bấm chọn ảnh", style: TextStyle(color: Colors.grey))])
                      : null,
                ),
              ),
              SizedBox(height: 20),
              TextField(controller: nameController, decoration: InputDecoration(labelText: "Tên giày", border: OutlineInputBorder())),
              SizedBox(height: 15),
              TextField(controller: priceController, decoration: InputDecoration(labelText: "Giá bán", border: OutlineInputBorder())),
              SizedBox(height: 20),
              DropdownButton<String>(
                value: selectedCategory,
                isExpanded: true,
                items: categories.map((String value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
                onChanged: (newValue) => setState(() => selectedCategory = newValue!),
              ),
              SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                  onPressed: isLoading ? null : addProduct,
                  child: isLoading ? CircularProgressIndicator(color: Colors.white) : Text("LƯU SẢN PHẨM", style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}