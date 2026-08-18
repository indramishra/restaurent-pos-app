import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import '../models/menu_item.dart';
import '../models/order_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;

  double get totalAmount {
    return _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  void addItem(MenuItem menuItem) {
    final index = _items.indexWhere((item) => item.menuItem.id == menuItem.id);
    if (index >= 0) {
      _items[index].quantity += 1;
    } else {
      _items.add(CartItem(menuItem: menuItem));
    }
    notifyListeners();
  }

  void removeItem(String menuItemId) {
    final index = _items.indexWhere((item) => item.menuItem.id == menuItemId);
    if (index >= 0) {
      if (_items[index].quantity > 1) {
        _items[index].quantity -= 1;
      } else {
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  Future<void> placeOrder(String tableNumber) async {
    if (_items.isEmpty) return;

    final order = OrderModel(
      tableNumber: tableNumber,
      items: _items,
      totalAmount: totalAmount,
      createdAt: DateTime.now(),
      status: 'pending',
    );

    await FirebaseFirestore.instance.collection('orders').add(order.toMap());
    
    // In a real app, you would integrate Razorpay here.
    
    clearCart();
  }
}
