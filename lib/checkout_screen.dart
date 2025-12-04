import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CheckoutScreen extends StatefulWidget {
  final double totalAmount;

  // Nhận tổng tiền từ giỏ hàng truyền sang
  CheckoutScreen({required this.totalAmount});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController(); // Số nhà, xã/phường
  final voucherController = TextEditingController();

  // Danh sách Tỉnh/Thành phố Việt Nam (Dữ liệu cứng cho đơn giản)
  final List<String> provinces = [
    "Hà Nội", "TP. Hồ Chí Minh", "Đà Nẵng", "Hải Phòng", "Cần Thơ",
    "An Giang", "Bà Rịa - Vũng Tàu", "Bắc Giang", "Bắc Kạn", "Bạc Liêu",
    "Bắc Ninh", "Bến Tre", "Bình Định", "Bình Dương", "Bình Phước",
    "Bình Thuận", "Cà Mau", "Cao Bằng", "Đắk Lắk", "Đắk Nông",
    "Điện Biên", "Đồng Nai", "Đồng Tháp", "Gia Lai", "Hà Giang",
    "Hà Nam", "Hà Tĩnh", "Hải Dương", "Hậu Giang", "Hòa Bình",
    "Hưng Yên", "Khánh Hòa", "Kiên Giang", "Kon Tum", "Lai Châu",
    "Lâm Đồng", "Lạng Sơn", "Lào Cai", "Long An", "Nam Định",
    "Nghệ An", "Ninh Bình", "Ninh Thuận", "Phú Thọ", "Quảng Bình",
    "Quảng Nam", "Quảng Ngãi", "Quảng Ninh", "Quảng Trị", "Sóc Trăng",
    "Sơn La", "Tây Ninh", "Thái Bình", "Thái Nguyên", "Thanh Hóa",
    "Thừa Thiên Huế", "Tiền Giang", "Trà Vinh", "Tuyên Quang", "Vĩnh Long",
    "Vĩnh Phúc", "Yên Bái"
  ];
  String? selectedProvince; // Biến lưu tỉnh đã chọn

  double discountAmount = 0; // Số tiền được giảm
  bool isVoucherApplied = false;
  bool isLoading = false;

  // Tính tổng tiền cuối cùng
  double get finalTotal => widget.totalAmount - discountAmount;

  // Hàm định dạng tiền tệ
  String formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.') + " đ";
  }

  // --- LOGIC VOUCHER ---
  void applyVoucher() {
    if (voucherController.text.trim().toUpperCase() == "CR7") {
      setState(() {
        isVoucherApplied = true;
        discountAmount = widget.totalAmount * 0.11; // Giảm 11%
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("SIUUU! Đã áp dụng mã CR7 giảm 11%")));
    } else {
      setState(() {
        isVoucherApplied = false;
        discountAmount = 0;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Mã giảm giá không hợp lệ")));
    }
  }

  // --- LOGIC THANH TOÁN ---
  Future<void> submitOrder() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedProvince == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Vui lòng chọn Tỉnh/Thành phố")));
      return;
    }

    setState(() => isLoading = true);

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // 1. Lấy toàn bộ sản phẩm trong giỏ hàng hiện tại
      var cartSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .get();

      List<Map<String, dynamic>> orderItems = [];
      for (var doc in cartSnapshot.docs) {
        orderItems.add(doc.data());
      }

      // 2. Lưu đơn hàng vào collection 'orders'
      await FirebaseFirestore.instance.collection('orders').add({
        'userId': user.uid,
        'userInfo': {
          'name': nameController.text.trim(),
          'phone': phoneController.text.trim(),
          'address': addressController.text.trim(),
          'province': selectedProvince,
        },
        'items': orderItems,
        'paymentDetails': {
          'totalOriginal': widget.totalAmount,
          'discount': discountAmount,
          'totalPaid': finalTotal,
          'voucher': isVoucherApplied ? "CR7" : null,
        },
        'status': 'pending', // Trạng thái: Đang xử lý
        'createdAt': Timestamp.now(),
      });

      // 3. Xóa sạch giỏ hàng sau khi đặt thành công
      for (var doc in cartSnapshot.docs) {
        await doc.reference.delete();
      }

      // 4. Thông báo và quay về trang chủ
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Đặt hàng thành công! Cảm ơn bạn.")));

      // Quay về màn hình đầu tiên (Home)
      Navigator.of(context).popUntil((route) => route.isFirst);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi thanh toán: $e")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Thanh toán", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- THÔNG TIN GIAO HÀNG ---
              Text("Thông tin giao hàng", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 15),

              TextFormField(
                controller: nameController,
                decoration: InputDecoration(labelText: "Họ tên người nhận", border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                validator: (val) => val!.isEmpty ? "Vui lòng nhập họ tên" : null,
              ),
              SizedBox(height: 10),

              TextFormField(
                controller: phoneController,
                decoration: InputDecoration(labelText: "Số điện thoại", border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                keyboardType: TextInputType.phone,
                validator: (val) => val!.isEmpty ? "Vui lòng nhập số điện thoại" : null,
              ),
              SizedBox(height: 10),

              // Dropdown chọn Tỉnh/Thành
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: "Tỉnh / Thành phố",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                value: selectedProvince,
                items: provinces.map((String province) {
                  return DropdownMenuItem<String>(
                    value: province,
                    child: Text(province),
                  );
                }).toList(),
                onChanged: (val) => setState(() => selectedProvince = val),
              ),
              SizedBox(height: 10),

              TextFormField(
                controller: addressController,
                decoration: InputDecoration(labelText: "Địa chỉ cụ thể (Số nhà, Xã/Phường)", border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                validator: (val) => val!.isEmpty ? "Vui lòng nhập địa chỉ" : null,
              ),

              SizedBox(height: 30),

              // --- VOUCHER ---
              Text("Mã giảm giá", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: voucherController,
                      decoration: InputDecoration(
                        hintText: "Nhập mã voucher",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: EdgeInsets.symmetric(horizontal: 15),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: applyVoucher,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.black, padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15)),
                    child: Text("Áp dụng", style: TextStyle(color: Colors.white)),
                  )
                ],
              ),
              if (isVoucherApplied)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text("Đã áp dụng mã CR7 (-11%)", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                ),

              SizedBox(height: 30),

              // --- TỔNG KẾT ---
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Tạm tính:"),
                        Text(formatPrice(widget.totalAmount), style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Giảm giá:"),
                        Text("- ${formatPrice(discountAmount)}", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Divider(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("TỔNG THANH TOÁN:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text(formatPrice(finalTotal), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red)),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20),

              // Nút xác nhận
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: isLoading ? null : submitOrder,
                  child: isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text("XÁC NHẬN ĐẶT HÀNG", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}