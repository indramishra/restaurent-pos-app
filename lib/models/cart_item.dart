import 'menu_item.dart';

class CartItem {
  final MenuItem menuItem;
  int quantity;

  CartItem({
    required this.menuItem,
    this.quantity = 1,
  });

  double get totalPrice => menuItem.price * quantity;

  Map<String, dynamic> toMap() {
    return {
      'menuItem': menuItem.toMap(),
      'quantity': quantity,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> data) {
    return CartItem(
      menuItem: MenuItem.fromMap(data['menuItem'], data['menuItem']['id'] ?? ''),
      quantity: data['quantity'] ?? 1,
    );
  }
}
