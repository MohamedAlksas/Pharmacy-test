import 'package:flutter/material.dart';
import 'package:graduation_project/Models/ProductProvider.dart';
import 'package:graduation_project/Services/alertService.dart';
import 'package:graduation_project/Models/UserRoleModel.dart';
import 'package:graduation_project/Services/MaterialSerivce.dart';
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

  bool get isSupervisor => AuthService.isSupervisor;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _printReport(ProductProvider provider) async {
    try {
      final pdf = pw.Document();
      final materials = provider.products;

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Materials Inventory Report',
                    style: pw.TextStyle(
                        fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.Text(
                    'Generated: ${DateTime.now().toString().substring(0, 16)}',
                    style: const pw.TextStyle(fontSize: 12)),
                pw.SizedBox(height: 20),
                pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      _buildPdfKpi(
                          'Total Materials', materials.length.toString()),
                      _buildPdfKpi('Expiring Soon',
                          provider.expiringSoonCount.toString()),
                      _buildPdfKpi(
                          'Low Stock', provider.lowStockCount.toString()),
                      _buildPdfKpi(
                          'Expired', provider.expiredCount.toString()),
                    ]),
                pw.SizedBox(height: 30),
                pw.Text('Materials List',
                    style: pw.TextStyle(
                        fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.Table.fromTextArray(
                  headers: [
                    'Name',
                    'Category',
                    'Quantity',
                    'Expiry',
                    'Status'
                  ],
                  data: materials.map((m) {
                    return [
                      m.name,
                      m.category,
                      m.quantity.toString(),
                      m.expiryDate,
                      MaterialService.getMaterialStatus(m),
                    ];
                  }).toList(),
                  headerStyle: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 10),
                  cellStyle: const pw.TextStyle(fontSize: 9),
                  headerDecoration:
                      const pw.BoxDecoration(color: PdfColors.grey300),
                ),
              ],
            );
          },
        ),
      );

      if (mounted) _showPrintOptionsDialog(pdf);
    } catch (e) {
      if (mounted) _showErrorDialog('Error generating report: $e');
    }
  }

  void _showPrintOptionsDialog(pw.Document pdf) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Report'),
        content:
            const Text('Choose how you would like to export the report:'),
        actions: [
          TextButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                await _printPdf(pdf);
              },
              icon: const Icon(Icons.print),
              label: const Text('Print')),
          TextButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                await _sharePdf(pdf);
              },
              icon: const Icon(Icons.share),
              label: const Text('Share')),
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
        ],
      ),
    );
  }

  Future<void> _printPdf(pw.Document pdf) async {
    try {
      await Printing.layoutPdf(
          onLayout: (PdfPageFormat fmt) async => pdf.save());
    } catch (e) {
      if (mounted) _showErrorDialog('Error printing: $e');
    }
  }

  Future<void> _sharePdf(pw.Document pdf) async {
    try {
      await Printing.sharePdf(
          bytes: await pdf.save(),
          filename:
              'inventory_report_${DateTime.now().millisecondsSinceEpoch}.pdf');
    } catch (e) {
      if (mounted) _showErrorDialog('Error sharing PDF: $e');
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
              child: const Text('OK'))
        ],
      ),
    );
  }

  pw.Widget _buildPdfKpi(String title, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey),
          borderRadius: pw.BorderRadius.circular(5)),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
        pw.Text(title, style: const pw.TextStyle(fontSize: 10)),
        pw.SizedBox(height: 5),
        pw.Text(value,
            style: pw.TextStyle(
                fontSize: 16, fontWeight: pw.FontWeight.bold)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = ProductProvider.of(context);
    final allMaterials = provider.products;

    // Build unique category list
    final categories =
        allMaterials.map((m) => m.category).toSet().toList()..sort();
    final categoryItems = [
      'All Categories',
      ...categories,
    ];

    // Filter
    final filtered = allMaterials.where((m) {
      final matchSearch = m.name
          .toLowerCase()
          .contains(_searchCtrl.text.toLowerCase());
      final matchCat = _selectedCategory == 'All Categories' ||
          m.category == _selectedCategory;
      final status = MaterialService.getMaterialStatus(m);
      final matchStatus =
          _selectedStatus == 'All Statuses' || status == _selectedStatus;
      return matchSearch && matchCat && matchStatus;
    }).toList();

    return Container(
      padding: const EdgeInsets.all(18),
      color: isDark ? const Color(0xFF0E1621) : const Color(0xFFF5F5F5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Reports & Analytics',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black)),
              if (isSupervisor)
                ElevatedButton.icon(
                  onPressed: () => _printReport(provider),
                  icon: const Icon(Icons.print, size: 18),
                  label: const Text('Export Report'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D6EFD),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // KPI Cards – live from provider
          if (provider.loading)
            const Center(child: CircularProgressIndicator())
          else
            Row(
              children: [
                Expanded(
                    child: _buildKpiCard('Total Materials',
                        provider.totalProducts.toString(), isDark, null)),
                const SizedBox(width: 16),
                Expanded(
                    child: _buildKpiCard(
                        'Total Categories',
                        categories.length.toString(),
                        isDark,
                        null)),
                const SizedBox(width: 16),
                Expanded(
                    child: _buildKpiCard(
                        'Expiring Soon',
                        provider.expiringSoonCount.toString(),
                        isDark,
                        const Color(0xFFFFA500))),
                const SizedBox(width: 16),
                Expanded(
                    child: _buildKpiCard(
                        'Low Stock',
                        provider.lowStockCount.toString(),
                        isDark,
                        const Color(0xFFDC3545))),
              ],
            ),
          const SizedBox(height: 20),

          // Search and Filters
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    color:
                        isDark ? const Color(0xFF1A2332) : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (value) => setState(() {}),
                    style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search materials...',
                      hintStyle: TextStyle(
                          color: isDark ? Colors.white38 : Colors.black38,
                          fontSize: 14),
                      prefixIcon: Icon(Icons.search,
                          color:
                              isDark ? Colors.white54 : Colors.black54,
                          size: 20),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _buildDropdownButton(isDark, _selectedCategory, categoryItems,
                  (v) => setState(() => _selectedCategory = v!)),
              const SizedBox(width: 12),
              _buildDropdownButton(
                  isDark,
                  _selectedStatus,
                  [
                    'All Statuses',
                    'Good',
                    'Expiring Soon',
                    'Expired',
                    'Low Stock'
                  ],
                  (v) => setState(() => _selectedStatus = v!)),
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
                        : Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text('Materials',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color:
                                isDark ? Colors.white : Colors.black)),
                  ),
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF233044)
                          : const Color(0xFFF8F9FA),
                      border: Border(
                        top: BorderSide(
                            color: isDark
                                ? const Color(0xFF2A3F5F)
                                : Colors.grey.shade200),
                        bottom: BorderSide(
                            color: isDark
                                ? const Color(0xFF2A3F5F)
                                : Colors.grey.shade200),
                      ),
                    ),
                    child: Row(
                      children: [
                        _headerCell('Name', flex: 3, isDark: isDark),
                        _headerCell('Category', flex: 2, isDark: isDark),
                        _headerCell('Quantity', flex: 1, isDark: isDark),
                        _headerCell('Expiry Date', flex: 2, isDark: isDark),
                        _headerCell('Status', flex: 1, isDark: isDark),
                      ],
                    ),
                  ),
                  // Rows
                  Expanded(
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final m = filtered[index];
                        final status = MaterialService.getMaterialStatus(m);
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                  color: isDark
                                      ? const Color(0xFF2A3F5F)
                                      : Colors.grey.shade200),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                  flex: 3,
                                  child: Text(m.name,
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black))),
                              Expanded(
                                  flex: 2,
                                  child: Text(m.category,
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: isDark
                                              ? Colors.white60
                                              : Colors.black54))),
                              Expanded(
                                  flex: 1,
                                  child: Text(m.quantity.toString(),
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black))),
                              Expanded(
                                  flex: 2,
                                  child: Text(m.expiryDate,
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: isDark
                                              ? Colors.white60
                                              : Colors.black54))),
                              Expanded(
                                  flex: 1,
                                  child: _buildStatusBadge(status, isDark)),
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

          // Bottom: Alerts panel
          Container(
            height: 280,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A2332) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: isDark
                      ? const Color(0xFF2A3F5F)
                      : Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text('Alerts',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black)),
                ),
                Expanded(
                  child: ListView(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20),
                    children:
                        AlertService.getAllAlerts().take(5).map((alert) {
                      Color color;
                      IconData icon;
                      switch (alert.alertType) {
                        case 'expired':
                          color = const Color(0xFFDC3545);
                          icon = Icons.error_outline;
                          break;
                        case 'expiring_soon':
                          color = const Color(0xFFFFA500);
                          icon = Icons.warning_amber_rounded;
                          break;
                        default:
                          color = const Color(0xFF0D6EFD);
                          icon = Icons.inventory_2_outlined;
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildAlertItem(
                            isDark,
                            alert.material?.name ?? 'Alert',
                            alert.message,
                            'Created: ${alert.createdAt.toLocal().toString().substring(0, 16)}',
                            color,
                            icon),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerCell(String text, {required int flex, required bool isDark}) {
    return Expanded(
      flex: flex,
      child: Text(text,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black87)),
    );
  }

  Widget _buildKpiCard(
      String title, String value, bool isDark, Color? highlightColor) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2332) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: highlightColor?.withOpacity(0.3) ??
                (isDark
                    ? const Color(0xFF2A3F5F)
                    : Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : Colors.black54)),
          const SizedBox(height: 10),
          Text(value,
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: highlightColor ??
                      (isDark ? Colors.white : Colors.black))),
        ],
      ),
    );
  }

  Widget _buildDropdownButton(bool isDark, String value, List<String> items,
      void Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2332) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color:
                isDark ? const Color(0xFF2A3F5F) : Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(value) ? value : items.first,
          dropdownColor:
              isDark ? const Color(0xFF1A2332) : Colors.white,
          icon: Icon(Icons.keyboard_arrow_down,
              color: isDark ? Colors.white70 : Colors.black54, size: 20),
          style: TextStyle(
              color: isDark ? Colors.white : Colors.black, fontSize: 13),
          items: items
              .map((i) => DropdownMenuItem(value: i, child: Text(i)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, bool isDark) {
    Color bg, text;
    switch (status) {
      case 'Good':
        bg = const Color(0xFF28A745).withOpacity(0.15);
        text = const Color(0xFF28A745);
        break;
      case 'Expiring Soon':
        bg = const Color(0xFFFFA500).withOpacity(0.15);
        text = const Color(0xFFFFA500);
        break;
      case 'Expired':
        bg = const Color(0xFFDC3545).withOpacity(0.15);
        text = const Color(0xFFDC3545);
        break;
      case 'Low Stock':
        bg = Colors.orange.withOpacity(0.15);
        text = Colors.orange;
        break;
      default:
        bg = Colors.grey.withOpacity(0.15);
        text = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(status,
          style: TextStyle(
              color: text, fontWeight: FontWeight.w600, fontSize: 11)),
    );
  }

  Widget _buildAlertItem(bool isDark, String title, String message,
      String timestamp, Color color, IconData icon) {
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
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: color,
                        fontSize: 13)),
                const SizedBox(height: 4),
                Text(message,
                    style: TextStyle(color: color, fontSize: 12)),
                const SizedBox(height: 4),
                Text(timestamp,
                    style: TextStyle(
                        color: isDark ? Colors.white38 : Colors.black38,
                        fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}