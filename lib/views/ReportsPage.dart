import 'package:flutter/material.dart';
import 'package:graduation_project/Services/MaterialSerivce.dart';
import 'package:graduation_project/Services/alertService.dart';
import 'package:graduation_project/Models/UserRoleModel.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedCategory = 'All Categories';
  String _selectedStatus = 'All Statuses';

  @override
  void initState() {
    super.initState();
    AlertService.initializeAlerts();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // Check if user is supervisor
  bool get isSupervisor => AuthService.isSupervisor;

  Future<void> _printReport() async {
    try {
      // Check if printing is available
      // final info = await Printing.info();

      // if (!info.canPrint && !info.canShare) {
      //   if (mounted) {
      //     _showErrorDialog('Printing is not available on this device.');
      //   }
      //   return;
      // }

      final pdf = pw.Document();

      // Sample data for PDF
      final displayMaterials = [
        {
          'name': 'Sterile Gauze Pads',
          'category': 'Medical Supplies',
          'quantity': 350,
          'expiry': '2025-12-31',
          'status': 'In Stock',
        },
        {
          'name': 'Latex Gloves (M)',
          'category': 'Protective Gear',
          'quantity': 45,
          'expiry': '2024-08-15',
          'status': 'Expiring Soon',
        },
        {
          'name': 'Saline Solution',
          'category': 'Pharmaceuticals',
          'quantity': 0,
          'expiry': '2024-05-20',
          'status': 'Out of Stock',
        },
        {
          'name': 'Syringes (10ml)',
          'category': 'Medical Supplies',
          'quantity': 800,
          'expiry': '2026-02-01',
          'status': 'In Stock',
        },
      ];

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Text(
                  'Materials Inventory Report',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Generated: ${DateTime.now().toString().substring(0, 16)}',
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.SizedBox(height: 20),

                // KPI Summary
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    _buildPdfKpi('Total Materials', '1250'),
                    _buildPdfKpi('Total Categories', '15'),
                    _buildPdfKpi('Expiring Soon', '24'),
                    _buildPdfKpi('Out of Stock', '8'),
                  ],
                ),
                pw.SizedBox(height: 30),

                // Materials Table
                pw.Text(
                  'Materials List',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Table.fromTextArray(
                  headers: ['Name', 'Category', 'Quantity', 'Expiry', 'Status'],
                  data: displayMaterials.map((material) {
                    return [
                      material['name'],
                      material['category'],
                      material['quantity'].toString(),
                      material['expiry'],
                      material['status'],
                    ];
                  }).toList(),
                  headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 10,
                  ),
                  cellStyle: const pw.TextStyle(fontSize: 9),
                  cellAlignment: pw.Alignment.centerLeft,
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColors.grey300,
                  ),
                ),
              ],
            );
          },
        ),
      );

      // Show options dialog
      if (mounted) {
        _showPrintOptionsDialog(pdf);
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Error generating report: ${e.toString()}');
      }
    }
  }

  void _showPrintOptionsDialog(pw.Document pdf) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Report'),
        content: const Text('Choose how you would like to export the report:'),
        actions: [
          TextButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await _printPdf(pdf);
            },
            icon: const Icon(Icons.print),
            label: const Text('Print'),
          ),
          TextButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await _sharePdf(pdf);
            },
            icon: const Icon(Icons.share),
            label: const Text('Share'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _printPdf(pw.Document pdf) async {
    try {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report sent to printer'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Error printing: ${e.toString()}');
      }
    }
  }

  Future<void> _sharePdf(pw.Document pdf) async {
    try {
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename:
            'inventory_report_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Error sharing PDF: ${e.toString()}');
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfKpi(String title, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 5),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final materials = MaterialService.getAllMaterials();

    // Calculate metrics
    final totalMaterials = 1250;
    final totalCategories = 15;
    final expiringSoon = 24;
    final outOfStock = 8;

    // Sample materials for display
    final displayMaterials = [
      {
        'name': 'Sterile Gauze Pads',
        'category': 'Medical Supplies',
        'quantity': 350,
        'expiry': '2025-12-31',
        'status': 'In Stock',
      },
      {
        'name': 'Latex Gloves (M)',
        'category': 'Protective Gear',
        'quantity': 45,
        'expiry': '2024-08-15',
        'status': 'Expiring Soon',
      },
      {
        'name': 'Saline Solution',
        'category': 'Pharmaceuticals',
        'quantity': 0,
        'expiry': '2024-05-20',
        'status': 'Out of Stock',
      },
      {
        'name': 'Syringes (10ml)',
        'category': 'Medical Supplies',
        'quantity': 800,
        'expiry': '2026-02-01',
        'status': 'In Stock',
      },
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      color: isDark ? const Color(0xFF0E1621) : const Color(0xFFF5F5F5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title Row with Print Button (only for supervisor)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Reports & Analytics',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              // Print button - only visible for supervisors
              if (isSupervisor)
                ElevatedButton.icon(
                  onPressed: _printReport,
                  icon: const Icon(Icons.print, size: 18),
                  label: const Text('Export Report'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D6EFD),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // KPI Cards Row
          Row(
            children: [
              Expanded(
                child: _buildKpiCard(
                  'Total Materials',
                  totalMaterials.toString(),
                  isDark,
                  null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildKpiCard(
                  'Total Categories',
                  totalCategories.toString(),
                  isDark,
                  null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildKpiCard(
                  'Expiring Soon',
                  expiringSoon.toString(),
                  isDark,
                  const Color(0xFFFFA500),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildKpiCard(
                  'Out of Stock',
                  outOfStock.toString(),
                  isDark,
                  const Color(0xFFDC3545),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Search and Filters Row
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1A2332) : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (value) => setState(() {}),
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search materials...',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.white38 : Colors.black38,
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: isDark ? Colors.white54 : Colors.black54,
                        size: 20,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _buildDropdownButton(
                isDark,
                _selectedCategory,
                [
                  'All Categories',
                  'Medical Supplies',
                  'Protective Gear',
                  'Pharmaceuticals',
                ],
                (value) => setState(() => _selectedCategory = value!),
              ),
              const SizedBox(width: 12),
              _buildDropdownButton(
                isDark,
                _selectedStatus,
                ['All Statuses', 'In Stock', 'Expiring Soon', 'Out of Stock'],
                (value) => setState(() => _selectedStatus = value!),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Materials Table
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A2332) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF2A3F5F)
                      : Colors.grey.shade200,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'Materials',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                  // Table Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF233044)
                          : const Color(0xFFF8F9FA),
                      border: Border(
                        top: BorderSide(
                          color: isDark
                              ? const Color(0xFF2A3F5F)
                              : Colors.grey.shade200,
                        ),
                        bottom: BorderSide(
                          color: isDark
                              ? const Color(0xFF2A3F5F)
                              : Colors.grey.shade200,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            'Name',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Category',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            'Quantity',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Expiry Date',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            'Status',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Table Rows
                  Expanded(
                    child: ListView.builder(
                      itemCount: displayMaterials.length,
                      itemBuilder: (context, index) {
                        final material = displayMaterials[index];
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: isDark
                                    ? const Color(0xFF2A3F5F)
                                    : Colors.grey.shade200,
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  material['name'] as String,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  material['category'] as String,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark
                                        ? Colors.white60
                                        : Colors.black54,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  material['quantity'].toString(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  material['expiry'] as String,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark
                                        ? Colors.white60
                                        : Colors.black54,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: _buildStatusBadge(
                                  material['status'] as String,
                                  isDark,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Bottom Section: Stock Transactions and Alerts
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stock Transactions
              Expanded(
                child: Container(
                  height: 280,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1A2332) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF2A3F5F)
                          : Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'Stock Transactions',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                'Material',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white60
                                      : Colors.black54,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                'Type',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white60
                                      : Colors.black54,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                'Qty',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white60
                                      : Colors.black54,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Date',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white60
                                      : Colors.black54,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          children: [
                            _buildTransactionRow(
                              'Syringes',
                              'IN',
                              '+200',
                              '1h ago',
                              isDark,
                            ),
                            const SizedBox(height: 12),
                            _buildTransactionRow(
                              'Gauze Pads',
                              'OUT',
                              '-50',
                              '3h ago',
                              isDark,
                            ),
                            const SizedBox(height: 12),
                            _buildTransactionRow(
                              'Latex Gloves',
                              'IN',
                              '+100',
                              'Yesterday',
                              isDark,
                            ),
                            const SizedBox(height: 12),
                            _buildTransactionRow(
                              'Saline Solution',
                              'IN',
                              '+20',
                              '2 days ago',
                              isDark,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Alerts
              Expanded(
                child: Container(
                  height: 280,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1A2332) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF2A3F5F)
                          : Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'Alerts',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          children: [
                            _buildAlertItem(
                              isDark,
                              'Material Expired',
                              'Saline Solution has expired.',
                              'Created: 2024-05-21 09:00',
                              const Color(0xFFDC3545),
                              Icons.error_outline,
                            ),
                            const SizedBox(height: 12),
                            _buildAlertItem(
                              isDark,
                              'Low Stock Warning',
                              'Latex Gloves (M) quantity is low (45 left).',
                              'Created: 2024-05-20 14:30',
                              const Color(0xFFFFA500),
                              Icons.warning_amber_rounded,
                            ),
                            const SizedBox(height: 12),
                            _buildAlertItem(
                              isDark,
                              'Reorder Suggestion',
                              'Consider reordering Sterile Gauze Pads.',
                              'Created: 2024-05-18 11:00',
                              const Color(0xFF0D6EFD),
                              Icons.info_outline,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(
    String title,
    String value,
    bool isDark,
    Color? highlightColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2332) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color:
              highlightColor?.withOpacity(0.3) ??
              (isDark ? const Color(0xFF2A3F5F) : Colors.grey.shade200),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: highlightColor ?? (isDark ? Colors.white : Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownButton(
    bool isDark,
    String value,
    List<String> items,
    void Function(String?) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2332) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF2A3F5F) : Colors.grey.shade300,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: isDark ? const Color(0xFF1A2332) : Colors.white,
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: isDark ? Colors.white70 : Colors.black54,
            size: 20,
          ),
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 13,
          ),
          items: items.map((item) {
            return DropdownMenuItem(value: item, child: Text(item));
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, bool isDark) {
    Color backgroundColor;
    Color textColor;

    switch (status) {
      case 'In Stock':
        backgroundColor = const Color(0xFF28A745).withOpacity(0.15);
        textColor = const Color(0xFF28A745);
        break;
      case 'Expiring Soon':
        backgroundColor = const Color(0xFFFFA500).withOpacity(0.15);
        textColor = const Color(0xFFFFA500);
        break;
      case 'Out of Stock':
        backgroundColor = const Color(0xFFDC3545).withOpacity(0.15);
        textColor = const Color(0xFFDC3545);
        break;
      default:
        backgroundColor = Colors.grey.withOpacity(0.15);
        textColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildTransactionRow(
    String material,
    String type,
    String qty,
    String date,
    bool isDark,
  ) {
    final isIn = type == 'IN';
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            material,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: isIn
                  ? const Color(0xFF28A745).withOpacity(0.15)
                  : const Color(0xFFDC3545).withOpacity(0.15),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              type,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isIn ? const Color(0xFF28A745) : const Color(0xFFDC3545),
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Text(
            qty,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            date,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white60 : Colors.black45,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAlertItem(
    bool isDark,
    String title,
    String message,
    String timestamp,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: color,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(message, style: TextStyle(color: color, fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  timestamp,
                  style: TextStyle(
                    color: isDark ? Colors.white38 : Colors.black38,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
