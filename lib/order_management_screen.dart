import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderManagementScreen extends StatefulWidget {
  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen> {

  // Hàm format tiền tệ
  String formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.') + " đ";
  }

  // Hàm format thời gian đơn giản (DD/MM/YYYY HH:mm)
  String formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return "${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Quản lý đơn hàng", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      backgroundColor: Color(0xFFF5F5F5),
      body: StreamBuilder<QuerySnapshot>(
        // Lắng nghe collection 'orders', sắp xếp mới nhất lên đầu
        stream: FirebaseFirestore.instance
            .collection('orders')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long_outlined, size: 60, color: Colors.grey),
                Text("Chưa có đơn hàng nào"),
              ],
            ));
          }

          var orders = snapshot.data!.docs;

          return ListView.builder(
            padding: EdgeInsets.all(10),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              var data = orders[index].data() as Map<String, dynamic>;
              var userInfo = data['userInfo'] as Map<String, dynamic>;
              var paymentDetails = data['paymentDetails'] as Map<String, dynamic>;
              var items = data['items'] as List<dynamic>;
              Timestamp createdAt = data['createdAt'];

              // Tính tổng số lượng sản phẩm
              int totalQuantity = 0;
              for (var item in items) {
                totalQuantity += (item['quantity'] as num).toInt();
              }

              return Card(
                margin: EdgeInsets.only(bottom: 10),
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ExpansionTile(
                  // Phần hiển thị tóm tắt bên ngoài
                  leading: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.shopping_bag, color: Colors.white),
                  ),
                  title: Text(
                    userInfo['name'] ?? "Khách hàng",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Thời gian: ${formatTimestamp(createdAt)}"),
                      Text("SĐT: ${userInfo['phone']}"),
                      Text(
                        "Tổng tiền: ${formatPrice(paymentDetails['totalPaid'])}",
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  // Phần chi tiết bên trong khi bấm vào
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Divider(),
                          Text("Địa chỉ: ${userInfo['address']} - ${userInfo['province']}", style: TextStyle(fontStyle: FontStyle.italic)),
                          SizedBox(height: 10),
                          Text("Danh sách sản phẩm ($totalQuantity món):", style: TextStyle(fontWeight: FontWeight.bold)),
                          ...items.map((item) {
                            return ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: Image.network(
                                item['img'] ?? "",
                                width: 40, height: 40, fit: BoxFit.cover,
                                errorBuilder: (_,__,___) => Icon(Icons.image_not_supported),
                              ),
                              title: Text(item['name']),
                              subtitle: Text("Size: ${item['size']} | SL: ${item['quantity']}"),
                              trailing: Text(item['price']),
                            );
                          }).toList(),
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}