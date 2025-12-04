import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'dart:convert'; // Để giải mã ảnh Base64

// Import màn hình chi tiết để bấm vào thẻ giày là chuyển trang
import 'product_detail_screen.dart';

class ChatScreen extends StatefulWidget {
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = false;
  final List<ChatMessage> _messages = [];

  // Danh sách sản phẩm lưu tạm
  List<Map<String, dynamic>> _localProducts = [];

  @override
  void initState() {
    super.initState();
    _loadProductData();

    // Tin nhắn chào mừng
    _messages.add(ChatMessage(
        text: "Chào bạn! Mình là Nike Bot (Auto) 🤖. Mình có thể giúp gì cho bạn?\n\n"
            "🔥 Gợi ý:\n"
            "- Nhập tên giày (VD: Jordan, Air Force)\n"
            "- Tư vấn size (VD: 25cm)\n"
            "- Chính sách ship...",
        isUser: false
    ));
  }

  // 1. Tải dữ liệu từ Firestore về để Bot "học"
  Future<void> _loadProductData() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('products').get();
      setState(() {
        _localProducts = snapshot.docs.map((doc) {
          var data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return data;
        }).toList();
      });
      print("Bot đã học được ${_localProducts.length} sản phẩm.");
    } catch (e) {
      print("Lỗi tải dữ liệu cho Bot: $e");
    }
  }

  // Hàm xử lý ảnh (Link hoặc Base64)
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

  // 2. LOGIC TRẢ LỜI THÔNG MINH (KỊCH BẢN)
  void _handleUserMessage(String input) {
    String message = input.toLowerCase().trim();

    // Hiển thị tin nhắn người dùng trước
    setState(() {
      _messages.add(ChatMessage(text: input, isUser: true));
      _isLoading = true;
      _textController.clear();
    });
    _scrollToBottom();

    // Giả lập suy nghĩ
    Future.delayed(Duration(milliseconds: 800), () {
      ChatMessage botResponse;

      // --- LOGIC TÌM KIẾM SẢN PHẨM CỤ THỂ ---
      // Kiểm tra xem có tên giày nào trong tin nhắn không
      Map<String, dynamic>? foundProduct;
      for (var product in _localProducts) {
        String name = product['name'].toString().toLowerCase();
        // Tìm tương đối (contains)
        if (message.contains(name) || (name.contains(message) && message.length > 3)) {
          foundProduct = product;
          break; // Tìm thấy 1 cái là dừng (hoặc bạn có thể làm list danh sách)
        }
      }

      if (foundProduct != null) {
        // NẾU TÌM THẤY SẢN PHẨM -> TRẢ VỀ THẺ SẢN PHẨM
        botResponse = ChatMessage(
          text: "Mình tìm thấy mẫu này phù hợp với bạn nè! 👇",
          isUser: false,
          product: foundProduct, // Gán dữ liệu sản phẩm vào tin nhắn
        );
      } else {
        // NẾU KHÔNG TÌM THẤY -> TRẢ LỜI TEXT BÌNH THƯỜNG
        String responseText = _generateTextResponse(message);
        botResponse = ChatMessage(text: responseText, isUser: false);
      }

      if (mounted) {
        setState(() {
          _messages.add(botResponse);
          _isLoading = false;
        });
        _scrollToBottom();
      }
    });
  }

  String _generateTextResponse(String message) {
    // --- A. TƯ VẤN SIZE ---
    RegExp regExp = RegExp(r"(\d+[\.,]?\d*)");
    Match? match = regExp.firstMatch(message);

    if ((message.contains("size") || message.contains("cỡ") || message.contains("chân")) && match != null) {
      double footSize = double.parse(match.group(0)!.replaceAll(',', '.'));
      if (footSize < 10) return "Bạn nhập số đo cm chuẩn nhé! 😊";

      String suggestedSize = "";
      if (footSize <= 22.5) suggestedSize = "35.5";
      else if (footSize <= 23.0) suggestedSize = "36";
      else if (footSize <= 23.5) suggestedSize = "36.5";
      else if (footSize <= 24.0) suggestedSize = "38";
      else if (footSize <= 24.5) suggestedSize = "38.5";
      else if (footSize <= 25.0) suggestedSize = "40";
      else if (footSize <= 25.5) suggestedSize = "40.5";
      else if (footSize <= 26.0) suggestedSize = "41";
      else if (footSize <= 26.5) suggestedSize = "42";
      else if (footSize <= 27.0) suggestedSize = "42.5";
      else if (footSize <= 27.5) suggestedSize = "43";
      else if (footSize <= 28.0) suggestedSize = "44";
      else suggestedSize = "45 trở lên";

      return "🦶 Với chân $footSize cm, bạn nên chọn size: **$suggestedSize**.\n(Nhích lên 0.5 size nếu chân bè nhé!)";
    }

    // --- B. CÁC CÂU HỎI KHÁC ---
    if (message == "ok" || message == "oki" || message == "uk") return "Dạ vâng ạ! 🥰";
    if (message.contains("cảm ơn") || message.contains("thanks")) return "Dạ không có chi! ❤️";
    if (message.contains("ship") || message.contains("giao hàng")) return "🚚 Giao hàng 2-4 ngày. Freeship đơn > 2 triệu!";
    if (message.contains("đổi") || message.contains("trả")) return "🔄 Đổi trả trong 7 ngày nếu lỗi NSX.";
    if (message.contains("địa chỉ")) return "🏠 123 Đường ABC, Quận 1, TP.HCM.";
    if (message.contains("voucher")) return "🎁 Nhập mã **CR7** giảm ngay 11% nhé!";

    if (message.contains("jordan")) return "🏀 Jordan bên mình nhiều mẫu lắm! Bạn nhập tên cụ thể (VD: 'Jordan 1') mình tìm cho nhé.";
    if (message.contains("hi") || message.contains("chào")) return "Chào bạn! Cần tìm giày gì cứ bảo mình nha.";

    // Mặc định
    List<String> defaultReplies = [
      "Xin lỗi, mình chưa tìm thấy mẫu đó. Bạn thử nhập tên khác xem?",
      "Bạn có thể hỏi mình về: Giá, Size, Ship hoặc tên giày bất kỳ nhé!",
      "Mẫu này hiện shop chưa có hoặc bạn gõ chưa đúng tên. Thử lại xem sao?"
    ];
    return defaultReplies[Random().nextInt(defaultReplies.length)];
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
        title: Row(
          children: [
            CircleAvatar(backgroundColor: Colors.black, child: Icon(Icons.smart_toy, color: Colors.white, size: 20)),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Trợ lý Nike (Auto)", style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                Text("Luôn sẵn sàng", style: TextStyle(color: Colors.green, fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(15),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return Align(
                  alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: msg.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      // 1. HIỂN THỊ TIN NHẮN TEXT
                      Container(
                        margin: EdgeInsets.only(bottom: 5),
                        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        decoration: BoxDecoration(
                          color: msg.isUser ? Colors.black : Colors.grey[200],
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(15),
                            topRight: Radius.circular(15),
                            bottomLeft: msg.isUser ? Radius.circular(15) : Radius.circular(0),
                            bottomRight: msg.isUser ? Radius.circular(0) : Radius.circular(15),
                          ),
                        ),
                        child: Text(
                            msg.text,
                            style: TextStyle(color: msg.isUser ? Colors.white : Colors.black87, fontSize: 15)
                        ),
                      ),

                      // 2. HIỂN THỊ THẺ SẢN PHẨM (NẾU CÓ)
                      if (msg.product != null && !msg.isUser)
                        GestureDetector(
                          onTap: () {
                            // Chuyển sang trang chi tiết khi bấm vào thẻ
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => ProductDetailScreen(product: msg.product!)
                                )
                            );
                          },
                          child: Container(
                            width: 200,
                            margin: EdgeInsets.only(bottom: 10, top: 5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 2))],
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Ảnh giày
                                ClipRRect(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                                  child: Image(
                                    image: _getImageProvider(msg.product!['img']),
                                    height: 120,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        msg.product!['name'] ?? "Tên sản phẩm",
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        msg.product!['price'] ?? "Liên hệ",
                                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                      ),
                                      SizedBox(height: 8),
                                      Container(
                                        width: double.infinity,
                                        padding: EdgeInsets.symmetric(vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.black,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          "Xem chi tiết",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(color: Colors.white, fontSize: 12),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            Padding(
                padding: const EdgeInsets.only(left: 20, bottom: 10),
                child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Đang nhập...", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 12))
                )
            ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                        hintText: "Nhập tin nhắn (VD: Jordan)...",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: EdgeInsets.symmetric(horizontal: 20)
                    ),
                    onSubmitted: (val) => _handleUserMessage(val),
                  ),
                ),
                SizedBox(width: 10),
                CircleAvatar(
                    backgroundColor: Colors.black,
                    radius: 24,
                    child: IconButton(
                      icon: Icon(Icons.send, color: Colors.white, size: 20),
                      onPressed: () => _handleUserMessage(_textController.text),
                    )
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Class ChatMessage cập nhật để chứa thêm thông tin sản phẩm
class ChatMessage {
  final String text;
  final bool isUser;
  final Map<String, dynamic>? product; // Thêm trường này để chứa data sản phẩm

  ChatMessage({
    required this.text,
    required this.isUser,
    this.product, // Optional
  });
}