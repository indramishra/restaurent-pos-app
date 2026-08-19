import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/order_model.dart';

class OrderDetailScreen extends StatelessWidget {
  final OrderModel order;

  const OrderDetailScreen({super.key, required this.order});

  Future<Uint8List> _generateReceiptPdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(
              child: pw.Text(
                'RESTAURANT NAME',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            pw.Center(child: pw.Text('QR Order Receipt')),
            pw.SizedBox(height: 8),
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Table: ${order.tableNumber}'),
                pw.Text(
                  'Order: #${order.id?.substring(0, 6).toUpperCase() ?? 'N/A'}',
                ),
              ],
            ),
            pw.Text(
              'Date: ${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year} ${order.createdAt.hour}:${order.createdAt.minute.toString().padLeft(2, '0')}',
            ),
            pw.Divider(),
            pw.SizedBox(height: 4),
            pw.Text(
              'ITEMS',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            ...order.items.map(
              (item) => pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: pw.Text('${item.menuItem.name} x${item.quantity}'),
                  ),
                  pw.Text('₹${item.totalPrice.toStringAsFixed(2)}'),
                ],
              ),
            ),
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'TOTAL',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  '₹${order.totalAmount.toStringAsFixed(2)}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
            if (order.paymentId != null) ...[
              pw.SizedBox(height: 4),
              pw.Text('Payment ID: ${order.paymentId}'),
            ],
            pw.SizedBox(height: 12),
            pw.Center(child: pw.Text('Thank you for dining with us!')),
            pw.Center(child: pw.Text('Please visit again!')),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  Future<void> _updateStatus(String newStatus) async {
    await FirebaseFirestore.instance.collection('orders').doc(order.id).update({
      'status': newStatus,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order - Table ${order.tableNumber}'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'Print Receipt',
            onPressed: () async {
              final pdfData = await _generateReceiptPdf();
              await Printing.layoutPdf(onLayout: (_) => pdfData);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order header card
            Card(
              color: Colors.orange.shade50,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Table ${order.tableNumber}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Order #${order.id?.substring(0, 8).toUpperCase() ?? 'N/A'}',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          Text(
                            '${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year} at ${order.createdAt.hour}:${order.createdAt.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: order.status == 'pending'
                            ? Colors.orange
                            : order.status == 'preparing'
                            ? Colors.blue
                            : Colors.green,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        order.status.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            const Text(
              'Order Items',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),

            // Items list
            ...order.items.map(
              (item) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(item.menuItem.name),
                  subtitle: Text(item.menuItem.description),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'x${item.quantity}',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      Text(
                        '₹${item.totalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TOTAL',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  '₹${order.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.deepOrange,
                  ),
                ),
              ],
            ),

            if (order.paymentId != null) ...[
              const SizedBox(height: 8),
              Text(
                'Payment ID: ${order.paymentId}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],

            const SizedBox(height: 32),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.print),
                    label: const Text('Print Receipt'),
                    onPressed: () async {
                      final pdfData = await _generateReceiptPdf();
                      await Printing.layoutPdf(onLayout: (_) => pdfData);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                if (order.status == 'pending')
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.restaurant),
                      label: const Text('Start Preparing'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        _updateStatus('preparing');
                        Navigator.pop(context);
                      },
                    ),
                  ),
                if (order.status == 'preparing')
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Mark Complete'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        _updateStatus('completed');
                        Navigator.pop(context);
                      },
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
