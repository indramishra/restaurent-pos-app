import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/menu_item.dart' as model;
import '../../providers/cart_provider.dart';
import 'cart_screen.dart';

class MenuScreen extends StatelessWidget {
  final String tableNumber;

  const MenuScreen({super.key, required this.tableNumber});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Restaurant Menu',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Table $tableNumber • v2',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        actions: [
          Consumer<CartProvider>(
            builder: (context, cart, _) {
              final totalQty = cart.items.fold(
                0,
                (sum, item) => sum + item.quantity,
              );
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart, size: 28),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CartScreen(tableNumber: tableNumber),
                        ),
                      );
                    },
                  ),
                  if (totalQty > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$totalQty',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('menu')
            .orderBy('category')
            .snapshots(),
        builder: (context, snapshot) {
          // While loading or error, show dummy data
          List<model.MenuItem> menuItems;
          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            menuItems = snapshot.data!.docs
                .map(
                  (doc) => model.MenuItem.fromMap(
                    doc.data() as Map<String, dynamic>,
                    doc.id,
                  ),
                )
                .toList();
          } else {
            // Demo data until Firebase is set up
            menuItems = [
              model.MenuItem(
                id: '1',
                name: 'Margherita Pizza',
                description: 'Classic cheese & tomato sauce',
                price: 299,
                imageUrl: '',
                category: '🍕 Pizza',
              ),
              model.MenuItem(
                id: '2',
                name: 'Pepperoni Pizza',
                description: 'Loaded with pepperoni',
                price: 349,
                imageUrl: '',
                category: '🍕 Pizza',
              ),
              model.MenuItem(
                id: '3',
                name: 'BBQ Chicken Pizza',
                description: 'Smoky BBQ sauce with chicken',
                price: 379,
                imageUrl: '',
                category: '🍕 Pizza',
              ),
              model.MenuItem(
                id: '4',
                name: 'Caesar Salad',
                description: 'Fresh romaine, croutons, caesar dressing',
                price: 179,
                imageUrl: '',
                category: '🥗 Salads',
              ),
              model.MenuItem(
                id: '5',
                name: 'Greek Salad',
                description: 'Olives, feta, cucumber, tomato',
                price: 199,
                imageUrl: '',
                category: '🥗 Salads',
              ),
              model.MenuItem(
                id: '6',
                name: 'Veg Burger',
                description: 'Crispy veggie patty, lettuce, tomato',
                price: 149,
                imageUrl: '',
                category: '🍔 Burgers',
              ),
              model.MenuItem(
                id: '7',
                name: 'Chicken Burger',
                description: 'Grilled chicken, cheese, pickles',
                price: 199,
                imageUrl: '',
                category: '🍔 Burgers',
              ),
              model.MenuItem(
                id: '8',
                name: 'Cold Coffee',
                description: 'Chilled blended coffee',
                price: 99,
                imageUrl: '',
                category: '🥤 Drinks',
              ),
              model.MenuItem(
                id: '9',
                name: 'Fresh Lime Soda',
                description: 'Lime juice with soda',
                price: 79,
                imageUrl: '',
                category: '🥤 Drinks',
              ),
            ];
          }

          // Group by category
          final Map<String, List<model.MenuItem>> grouped = {};
          for (final item in menuItems) {
            grouped.putIfAbsent(item.category, () => []).add(item);
          }

          return ListView(
            padding: const EdgeInsets.only(bottom: 100),
            children: grouped.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                    child: Text(
                      entry.key,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  ...entry.value.map((item) => _MenuItemCard(item: item)),
                ],
              );
            }).toList(),
          );
        },
      ),
      bottomNavigationBar: Consumer<CartProvider>(
        builder: (context, cart, _) {
          if (cart.items.isEmpty) return const SizedBox.shrink();
          return SafeArea(
            child: Container(
              margin: const EdgeInsets.all(12),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.shopping_cart_checkout),
                label: Text(
                  'View Cart (${cart.items.fold(0, (s, i) => s + i.quantity)} items) - ₹${cart.totalAmount.toStringAsFixed(2)}',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(14),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CartScreen(tableNumber: tableNumber),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MenuItemCard extends StatelessWidget {
  final model.MenuItem item;

  const _MenuItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, _) {
        final cartItem =
            cart.items.where((ci) => ci.menuItem.id == item.id).isNotEmpty
            ? cart.items.firstWhere((ci) => ci.menuItem.id == item.id)
            : null;
        final qty = cartItem?.quantity ?? 0;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: item.imageUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            item.imageUrl,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(
                          Icons.fastfood,
                          color: Colors.deepOrange,
                          size: 30,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.description,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${item.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange,
                        ),
                      ),
                    ],
                  ),
                ),
                qty == 0
                    ? ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(56, 36),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () => Provider.of<CartProvider>(
                          context,
                          listen: false,
                        ).addItem(item),
                        child: const Icon(Icons.add),
                      )
                    : Row(
                        children: [
                          InkWell(
                            onTap: () => Provider.of<CartProvider>(
                              context,
                              listen: false,
                            ).removeItem(item.id),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              padding: const EdgeInsets.all(4),
                              child: const Icon(
                                Icons.remove,
                                size: 18,
                                color: Colors.deepOrange,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              '$qty',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () => Provider.of<CartProvider>(
                              context,
                              listen: false,
                            ).addItem(item),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.deepOrange,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              padding: const EdgeInsets.all(4),
                              child: const Icon(
                                Icons.add,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
              ],
            ),
          ),
        );
      },
    );
  }
}
