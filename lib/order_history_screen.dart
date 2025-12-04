import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrderHistoryScreen extends StatefulWidget {
  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {

  String formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.') + " đ";
  }

  String formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return "${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}";
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case 'pending':
        color = Colors.orange;
        text = "Đang xử lý";
        icon = Icons.hourglass_empty;
        break;
      case 'shipping':
        color = Colors.blue;
        text = "Đang giao";
        icon = Icons.local_shipping;
        break;
      case 'completed':
        color = Colors.green;
        text = "Giao thành công";
        icon = Icons.check_circle;
        break;
      case 'cancelled':
        color = Colors.red;
        text = "Đã hủy";
        icon = Icons.cancel;
        break;
      default:
        color = Colors.grey;
        text = "Chờ xác nhận";
        icon = Icons.help_outline;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          SizedBox(width: 4),
          Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text("Đơn hàng của tôi", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: IconThemeData(color: Colors.black),
        centerTitle: true,
      ),
      backgroundColor: Color(0xFFF5F5F5),
      body: user == null
          ? Center(child: Text("Vui lòng đăng nhập"))
          : StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('userId', isEqualTo: user.uid) // Lọc đúng user
        // .orderBy('createdAt', descending: true) // ⚠️ TẠM BỎ DÒNG NÀY ĐỂ TRÁNH LỖI INDEX
            .snapshots(),
        builder: (context, snapshot) {
          // Nếu có lỗi, in lỗi rõ ràng ra màn hình để biết đường sửa
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text("Lỗi: ${snapshot.error}", textAlign: TextAlign.center, style: TextStyle(color: Colors.red)),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined, size: 100, color: Colors.grey[300]),
                  SizedBox(height: 20),
                  Text("Bạn chưa có đơn hàng nào", style: TextStyle(color: Colors.grey, fontSize: 18)),
                  SizedBox(height: 10),
                  Text("UID: ${user.uid}", style: TextStyle(fontSize: 10, color: Colors.grey)), // Debug ID
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                    child: Text("Quay lại mua sắm", style: TextStyle(color: Colors.white)),
                  )
                ],
              ),
            );
          }

          var orders = snapshot.data!.docs;

          return ListView.builder(
            padding: EdgeInsets.all(15),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              var data = orders[index].data() as Map<String, dynamic>;

              var paymentDetails = data['paymentDetails'] as Map<String, dynamic>? ?? {};
              var userInfo = data['userInfo'] as Map<String, dynamic>? ?? {};
              var items = data['items'] as List<dynamic>? ?? [];
              Timestamp createdAt = data['createdAt'] ?? Timestamp.now();

              String status = data['status'] ?? 'pending';
              DateTime createdDate = createdAt.toDate();
              if (status != 'cancelled' && DateTime.now().difference(createdDate).inHours >= 24) {
                status = 'completed';
              }

              int totalItems = 0;
              for(var item in items) {
                totalItems += (item['quantity'] as num).toInt();
              }

              return Card(
                margin: EdgeInsets.only(bottom: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 3,
                shadowColor: Colors.black12,
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                    leading: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: status == 'completed' ? Colors.green : Colors.black,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                          status == 'completed' ? Icons.check : Icons.shopping_bag,
                          color: Colors.white, size: 20
                      ),
                    ),
                    title: Text(
                        "Đơn hàng #${orders[index].id.substring(0, 5).toUpperCase()}",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 8),
                        _buildStatusBadge(status),
                        SizedBox(height: 8),
                        Text(
                          "$totalItems sản phẩm  •  ${formatPrice(paymentDetails['totalPaid'] ?? 0)}",
                          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
                        ),
                      ],
                    ),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(15.0),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Divider(color: Colors.grey[300]),
                            Row(
                              children: [
                                Icon(Icons.location_on, size: 16, color: Colors.grey),
                                SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    "${userInfo['name']} - ${userInfo['phone']}\n${userInfo['address']}, ${userInfo['province']}",
                                    style: TextStyle(fontSize: 13, color: Colors.grey[800]),
                                  ),
                                ),
                              ],
                            ),
                            Divider(color: Colors.grey[300]),
                            Text("Chi tiết sản phẩm:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            SizedBox(height: 10),
                            ...items.map((item) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10.0),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        item['img'] ?? "",
                                        width: 50, height: 50, fit: BoxFit.cover,
                                        errorBuilder: (_,__,___) => Container(color: Colors.grey[300], width: 50, height: 50),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(item['name'] ?? "Giày", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                                          Text("Size: ${item['size']} | x${item['quantity']}", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                        ],
                                      ),
                                    ),
                                    Text(item['price'] ?? "0đ", style: TextStyle(fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              );
                            }).toList(),
                            Divider(color: Colors.black54),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Thành tiền:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                Text(
                                  formatPrice(paymentDetails['totalPaid'] ?? 0),
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}