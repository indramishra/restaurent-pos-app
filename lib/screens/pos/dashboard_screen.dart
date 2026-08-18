import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/order_model.dart';
import 'order_detail_screen.dart';
import 'table_qr_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'preparing':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'preparing':
        return Icons.restaurant;
      case 'completed':
        return Icons.check_circle;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('POS Dashboard'),
          backgroundColor: Colors.deepOrange,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Pending', icon: Icon(Icons.hourglass_empty)),
              Tab(text: 'Preparing', icon: Icon(Icons.restaurant)),
              Tab(text: 'Completed', icon: Icon(Icons.check_circle)),
              Tab(text: 'QR Codes', icon: Icon(Icons.qr_code_2)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _OrderList(statusFilter: 'pending', statusColor: Colors.orange, statusIcon: Icons.hourglass_empty),
            _OrderList(statusFilter: 'preparing', statusColor: Colors.blue, statusIcon: Icons.restaurant),
            _OrderList(statusFilter: 'completed', statusColor: Colors.green, statusIcon: Icons.check_circle),
            const TableQRScreen(),
          ],
        ),
      ),
    );
  }
}

class _OrderList extends StatelessWidget {
  final String statusFilter;
  final Color statusColor;
  final IconData statusIcon;

  const _OrderList({
    required this.statusFilter,
    required this.statusColor,
    required this.statusIcon,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('status', isEqualTo: statusFilter)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(statusIcon, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text(
                  'No $statusFilter orders',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final order = OrderModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
            return _OrderCard(order: order, statusColor: statusColor);
          },
        );
      },
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final Color statusColor;

  const _OrderCard({required this.order, required this.statusColor});

  Future<void> _updateStatus(BuildContext context, String newStatus) async {
    await FirebaseFirestore.instance
        .collection('orders')
        .doc(order.id)
        .update({'status': newStatus});
  }

  @override
  Widget build(BuildContext context) {
    final timeAgo = DateTime.now().difference(order.createdAt);
    final minutesAgo = timeAgo.inMinutes;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor, width: 2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.table_restaurant, color: statusColor),
                      const SizedBox(width: 8),
                      Text(
                        'Table ${order.tableNumber}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      order.status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${order.items.length} item(s) | ${minutesAgo == 0 ? 'Just now' : '$minutesAgo min ago'}',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              ...order.items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text('• ${item.menuItem.name} x${item.quantity}'),
                  )),
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '₹${order.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Row(
                    children: [
                      if (order.status == 'pending')
                        ElevatedButton.icon(
                          icon: const Icon(Icons.restaurant, size: 16),
                          label: const Text('Prepare'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => _updateStatus(context, 'preparing'),
                        ),
                      if (order.status == 'preparing')
                        ElevatedButton.icon(
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Complete'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => _updateStatus(context, 'completed'),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
