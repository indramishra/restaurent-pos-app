import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class TableQRScreen extends StatefulWidget {
  const TableQRScreen({Key? key}) : super(key: key);

  @override
  State<TableQRScreen> createState() => _TableQRScreenState();
}

class _TableQRScreenState extends State<TableQRScreen> {
  // Base URL — update this to your deployed web app URL or deep link scheme
  // For now, the table number is embedded as a query param
  static const String _baseUrl =
      'https://restorent-pos-system.web.app/menu?table=';

  final List<String> _tables = List.generate(10, (i) => '${i + 1}');
  final TextEditingController _tableController = TextEditingController();

  // Map of GlobalKeys to capture each QR as an image for printing
  final Map<String, GlobalKey> _qrKeys = {};

  @override
  void initState() {
    super.initState();
    for (final t in _tables) {
      _qrKeys[t] = GlobalKey();
    }
  }

  @override
  void dispose() {
    _tableController.dispose();
    super.dispose();
  }

  void _addTable() {
    final tableNum = _tableController.text.trim();
    if (tableNum.isEmpty) return;
    if (_tables.contains(tableNum)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Table $tableNum already exists')));
      return;
    }
    setState(() {
      _tables.add(tableNum);
      _tables.sort(
        (a, b) =>
            int.tryParse(a)?.compareTo(int.tryParse(b) ?? 0) ?? a.compareTo(b),
      );
      _qrKeys[tableNum] = GlobalKey();
    });
    _tableController.clear();
  }

  void _removeTable(String tableNum) {
    setState(() {
      _tables.remove(tableNum);
      _qrKeys.remove(tableNum);
    });
  }

  Future<Uint8List?> _captureQRImage(GlobalKey key) async {
    try {
      final boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error capturing QR: $e');
      return null;
    }
  }

  Future<void> _printSingleQR(String tableNum) async {
    final key = _qrKeys[tableNum];
    if (key == null) return;

    final imageBytes = await _captureQRImage(key);
    if (imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not capture QR code. Please try again.'),
        ),
      );
      return;
    }

    final pdf = pw.Document();
    final image = pw.MemoryImage(imageBytes);
    final url = '$_baseUrl$tableNum';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        build: (context) => pw.Center(
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text(
                'RESTAURANT NAME',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 22,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Scan to order from your seat',
                style: const pw.TextStyle(fontSize: 13),
              ),
              pw.SizedBox(height: 24),
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(width: 2),
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(12),
                  ),
                ),
                padding: const pw.EdgeInsets.all(16),
                child: pw.Image(image, width: 200, height: 200),
              ),
              pw.SizedBox(height: 20),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
                decoration: pw.BoxDecoration(
                  color: PdfColors.orange,
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(30),
                  ),
                ),
                child: pw.Text(
                  'TABLE $tableNum',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Text(
                url,
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (_) => pdf.save());
  }

  Future<void> _printAllQRs() async {
    final pdf = pw.Document();

    for (final tableNum in _tables) {
      final key = _qrKeys[tableNum];
      if (key == null) continue;

      final imageBytes = await _captureQRImage(key);
      if (imageBytes == null) continue;

      final image = pw.MemoryImage(imageBytes);
      final url = '$_baseUrl$tableNum';

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a5,
          build: (context) => pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  'RESTAURANT NAME',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text('Scan to order from your seat'),
                pw.SizedBox(height: 24),
                pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(width: 2),
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(12),
                    ),
                  ),
                  padding: const pw.EdgeInsets.all(16),
                  child: pw.Image(image, width: 200, height: 200),
                ),
                pw.SizedBox(height: 20),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 10,
                  ),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.orange,
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(30),
                    ),
                  ),
                  child: pw.Text(
                    'TABLE $tableNum',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                pw.SizedBox(height: 16),
                pw.Text(
                  url,
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    await Printing.layoutPdf(onLayout: (_) => pdf.save());
  }

  void _showQRDialog(String tableNum) {
    final url = '$_baseUrl$tableNum';
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Table $tableNum',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Scan to access the menu',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: url,
                  size: 200,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.deepOrange,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  'TABLE $tableNum',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                url,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.print),
                label: const Text('Print This QR'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _printSingleQR(tableNum);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Table QR Codes'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.print_outlined, color: Colors.white),
            label: const Text(
              'Print All',
              style: TextStyle(color: Colors.white),
            ),
            onPressed: _tables.isEmpty ? null : _printAllQRs,
          ),
        ],
      ),
      body: Column(
        children: [
          // Add table card
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tableController,
                    decoration: InputDecoration(
                      hintText: 'Enter table number (e.g. 11)',
                      prefixIcon: const Icon(Icons.table_restaurant),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    keyboardType: TextInputType.text,
                    onSubmitted: (_) => _addTable(),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _addTable,
                  child: const Text('Add Table'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Base URL hint
          Container(
            width: double.infinity,
            color: Colors.blue.shade50,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'QR links to: $_baseUrl<table>',
                    style: TextStyle(color: Colors.blue.shade700, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          // QR grid
          Expanded(
            child: _tables.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.table_restaurant,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No tables added yet',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 200,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.85,
                        ),
                    itemCount: _tables.length,
                    itemBuilder: (context, index) {
                      final tableNum = _tables[index];
                      final url = '$_baseUrl$tableNum';
                      _qrKeys.putIfAbsent(tableNum, () => GlobalKey());

                      return GestureDetector(
                        onTap: () => _showQRDialog(tableNum),
                        child: Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Capturable QR widget
                                    RepaintBoundary(
                                      key: _qrKeys[tableNum],
                                      child: Container(
                                        color: Colors.white,
                                        child: QrImageView(
                                          data: url,
                                          size: 110,
                                          backgroundColor: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.deepOrange,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        'TABLE $tableNum',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Delete button
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: const Text('Remove Table?'),
                                        content: Text(
                                          'Remove Table $tableNum from the list?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                              _removeTable(tableNum);
                                            },
                                            child: const Text(
                                              'Remove',
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.cancel,
                                      color: Colors.red,
                                      size: 22,
                                    ),
                                  ),
                                ),
                              ),
                              // Print button
                              Positioned(
                                top: 4,
                                left: 4,
                                child: GestureDetector(
                                  onTap: () => _printSingleQR(tableNum),
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.print,
                                      color: Colors.deepOrange,
                                      size: 22,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
