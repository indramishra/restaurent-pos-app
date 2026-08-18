import 'cart_item.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String? id;
  final String tableNumber;
  final List<CartItem> items;
  final double totalAmount;
  final String status; // 'pending', 'preparing', 'completed'
  final DateTime createdAt;
  final String? paymentId;

  OrderModel({
    this.id,
    required this.tableNumber,
    required this.items,
    required this.totalAmount,
    this.status = 'pending',
    required this.createdAt,
    this.paymentId,
  });

  factory OrderModel.fromMap(Map<String, dynamic> data, String documentId) {
    return OrderModel(
      id: documentId,
      tableNumber: data['tableNumber'] ?? '',
      items: (data['items'] as List<dynamic>?)
              ?.map((item) => CartItem.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
      totalAmount: (data['totalAmount'] ?? 0.0).toDouble(),
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      paymentId: data['paymentId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tableNumber': tableNumber,
      'items': items.map((e) => e.toMap()).toList(),
      'totalAmount': totalAmount,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'paymentId': paymentId,
    };
  }
}
