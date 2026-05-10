import 'package:flutter/material.dart';
import 'package:graduation_project/Models/ProductProvider.dart';
import 'package:graduation_project/Models/UserRoleModel.dart';
import 'package:graduation_project/Models/orderModel.dart';
import 'package:graduation_project/Services/notificationService.dart';
import 'package:graduation_project/Services/orderService.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class OrdersPage extends StatefulWidget {
  final VoidCallback? onGoToOrders;

  const OrdersPage({super.key, this.onGoToOrders});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedDateFilter = 'Filter by Date';
  String _selectedStatusFilter = 'Filter by Status';
  List<OrderModel> _orders = [];

  @override
  void initState() {
    super.initState();
    _loadOrders();
    OrderService.changes.addListener(_loadOrders);
    NotificationService.changes.addListener(_handleNotificationChange);
  }

  @override
  void dispose() {
    OrderService.changes.removeListener(_loadOrders);
    NotificationService.changes.removeListener(_handleNotificationChange);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _loadOrders() {
    if (!mounted) return;
    setState(() => _orders = OrderService.getAllOrders());
  }

  void _handleNotificationChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filteredOrders = _filteredOrders();

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0E1621)
          : const Color(0xFFF5F5F5),
      body: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E90FF).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.history,
                    color: Color(0xFF1E90FF),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Orders History',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const Spacer(),
                if (AuthService.isSupervisor) ...[
                  _notificationBell(),
                  const SizedBox(width: 10),
                ],
                ElevatedButton.icon(
                  onPressed: _printOrders,
                  icon: const Icon(Icons.print, size: 18),
                  label: const Text('Export Orders'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D6EFD),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(flex: 3, child: _searchBox(isDark)),
                const SizedBox(width: 12),
                _dropdown(
                  isDark,
                  _selectedDateFilter,
                  const [
                    'Filter by Date',
                    'Today',
                    'This Week',
                    'This Month',
                    'This Year',
                  ],
                  (value) => setState(() => _selectedDateFilter = value!),
                ),
                const SizedBox(width: 12),
                _dropdown(
                  isDark,
                  _selectedStatusFilter,
                  const [
                    'Filter by Status',
                    'Completed',
                    'Pending',
                    'Canceled',
                  ],
                  (value) => setState(() => _selectedStatusFilter = value!),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: filteredOrders.isEmpty
                  ? Center(
                      child: Text(
                        'No orders found.',
                        style: TextStyle(
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredOrders.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _orderCard(filteredOrders[index], isDark),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _notificationBell() {
    final unreadCount = NotificationService.getUnread().length;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          tooltip: 'Edit request notifications',
          onPressed: _showOrderNotifications,
          icon: const Icon(Icons.notifications_none),
        ),
        if (unreadCount > 0)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                unreadCount.toString(),
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
  }

  void _showOrderNotifications() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final notifications = NotificationService.getAll();
          return AlertDialog(
            title: Text(
              'Edit Requests (${NotificationService.getUnread().length})',
            ),
            content: SizedBox(
              width: 520,
              child: notifications.isEmpty
                  ? const Text('No edit request notifications')
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: notifications.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        final item = notifications[index];
                        return ListTile(
                          leading: Icon(
                            item.isRead
                                ? Icons.mark_email_read_outlined
                                : Icons.mark_email_unread_outlined,
                            color: item.isRead ? Colors.grey : Colors.green,
                          ),
                          title: Text(item.materialName ?? item.title),
                          subtitle: Text(
                            'SKU: ${item.productSku ?? '-'}\n'
                            'Proposed expiry: ${_formatRawDate(item.proposedExpiry ?? '')}\n'
                            'Manager: ${item.managerName ?? '-'}',
                          ),
                          isThreeLine: true,
                          trailing: TextButton(
                            onPressed: () {
                              NotificationService.markRead(item.id);
                              setState(() {});
                              setDialogState(() {});
                              Navigator.pop(ctx);
                              widget.onGoToOrders?.call();
                            },
                            child: const Text('Go to Orders'),
                          ),
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  NotificationService.markAllRead();
                  setState(() {});
                  Navigator.pop(ctx);
                },
                child: const Text('Mark All Read'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _searchBox(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2332) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF2A3F5F) : Colors.grey.shade300,
        ),
      ),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (_) => setState(() {}),
        style: TextStyle(color: isDark ? Colors.white : Colors.black),
        decoration: InputDecoration(
          hintText: 'Search by order ID, product, SKU, or user...',
          hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
          prefixIcon: Icon(
            Icons.search,
            color: isDark ? Colors.white54 : Colors.black54,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _dropdown(
    bool isDark,
    String value,
    List<String> items,
    void Function(String?) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          items: items
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _orderCard(OrderModel order, bool isDark) {
    final canApprove =
        AuthService.isSupervisor &&
        order.type == OrderType.edit &&
        order.status == OrderStatus.pending;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2332) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF2A3F5F) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order #${order.id}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${order.productName} - SKU: ${order.productSku}',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${order.quantity} ${order.unit} | ${order.createdBy} | ${_formatDateTime(order.createdAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                ),
              ],
            ),
          ),
          _typeBadge(order.type),
          const SizedBox(width: 10),
          _statusBadge(order.status),
          if (canApprove) ...[
            const SizedBox(width: 12),
            IconButton(
              onPressed: () => _acceptEdit(order),
              icon: const Icon(Icons.check_circle, color: Colors.green),
              tooltip: 'Accept Edit',
            ),
            IconButton(
              onPressed: () => _rejectEdit(order),
              icon: const Icon(Icons.cancel, color: Colors.red),
              tooltip: 'Reject Edit',
            ),
          ],
          IconButton(
            onPressed: () => _viewOrderDetails(order, isDark),
            icon: Icon(
              Icons.visibility,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            tooltip: 'View Details',
          ),
        ],
      ),
    );
  }

  Widget _typeBadge(OrderType type) {
    final (label, color) = switch (type) {
      OrderType.add => ('Added', Colors.green),
      OrderType.export => ('Exported', Colors.blue),
      OrderType.edit => ('Edit Request', Colors.orange),
    };
    return _badge(label, color);
  }

  Widget _statusBadge(OrderStatus status) {
    final (label, color) = switch (status) {
      OrderStatus.completed => ('Completed', const Color(0xFF28A745)),
      OrderStatus.pending => ('Pending', const Color(0xFFFFA500)),
      OrderStatus.canceled => ('Canceled', const Color(0xFFDC3545)),
    };
    return _badge(label, color);
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  List<OrderModel> _filteredOrders() {
    final query = _searchCtrl.text.trim().toLowerCase();
    return _orders.where((order) {
      final matchesSearch =
          query.isEmpty ||
          order.id.toLowerCase().contains(query) ||
          order.productName.toLowerCase().contains(query) ||
          order.productSku.toLowerCase().contains(query) ||
          order.createdBy.toLowerCase().contains(query);
      final matchesStatus = switch (_selectedStatusFilter) {
        'Completed' => order.status == OrderStatus.completed,
        'Pending' => order.status == OrderStatus.pending,
        'Canceled' => order.status == OrderStatus.canceled,
        _ => true,
      };
      final now = DateTime.now();
      final matchesDate = switch (_selectedDateFilter) {
        'Today' =>
          order.createdAt.year == now.year &&
              order.createdAt.month == now.month &&
              order.createdAt.day == now.day,
        'This Week' => now.difference(order.createdAt).inDays <= 7,
        'This Month' =>
          order.createdAt.year == now.year &&
              order.createdAt.month == now.month,
        'This Year' => order.createdAt.year == now.year,
        _ => true,
      };
      return matchesSearch && matchesStatus && matchesDate;
    }).toList();
  }

  Future<void> _acceptEdit(OrderModel order) async {
    if (order.productId == null || order.notes == null) return;
    final provider = ProductProvider.of(context, listen: false);
    final matches = provider.products.where(
      (item) => item.id == order.productId,
    );
    final product = matches.isEmpty ? null : matches.first;
    if (product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product not found in inventory.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final body = product.toApiBody();
    body['expiryDate'] = order.notes;
    final error = await provider.updateProduct(order.productId!, body);
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
      return;
    }

    OrderService.updateOrderStatus(order.id, OrderStatus.completed);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Edit approved and applied.')));
  }

  Future<void> _rejectEdit(OrderModel order) async {
    final reasonController = TextEditingController();
    final rejected = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Edit Request'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Reason for rejection',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    reasonController.dispose();
    if (rejected != true) return;

    OrderService.updateOrderStatus(order.id, OrderStatus.canceled);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Edit rejected.')));
  }

  void _viewOrderDetails(OrderModel order, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Order Details'),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow('Order ID', order.id),
              _detailRow('Product', order.productName),
              _detailRow('SKU', order.productSku),
              _detailRow('Quantity', '${order.quantity} ${order.unit}'),
              _detailRow('Log Number', order.logNumber),
              _detailRow('Category ID', order.categoryId.toString()),
              _detailRow('Type', _typeLabel(order.type)),
              _detailRow('Status', _statusLabel(order.status)),
              _detailRow('Created By', order.createdBy),
              _detailRow('Date', _formatDateTime(order.createdAt)),
              if (order.notes != null)
                _detailRow('Requested Expiry', _formatRawDate(order.notes!)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value.isEmpty ? '-' : value)),
        ],
      ),
    );
  }

  Future<void> _printOrders() async {
    final pdf = pw.Document();
    final orders = OrderService.getAllOrders();
    final completed = orders
        .where((order) => order.status == OrderStatus.completed)
        .length;
    final pending = orders
        .where((order) => order.status == OrderStatus.pending)
        .length;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (_) => [
          pw.Text(
            'Orders Report',
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Generated: ${_formatDateTime(DateTime.now())}'),
          pw.SizedBox(height: 18),
          pw.Text(
            'Total orders: ${orders.length} | Completed: $completed | Pending: $pending',
          ),
          pw.SizedBox(height: 18),
          pw.Table.fromTextArray(
            headers: const [
              'Order ID',
              'Product',
              'SKU',
              'Qty',
              'Type',
              'Status',
              'Created By',
              'Date',
            ],
            data: orders
                .map(
                  (order) => [
                    order.id,
                    order.productName,
                    order.productSku,
                    '${order.quantity} ${order.unit}',
                    _typeLabel(order.type),
                    _statusLabel(order.status),
                    order.createdBy,
                    _formatDateTime(order.createdAt),
                  ],
                )
                .toList(),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 9,
            ),
            cellStyle: const pw.TextStyle(fontSize: 8),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          ),
        ],
      ),
    );

    if (mounted) _showPrintOptionsDialog(pdf);
  }

  void _showPrintOptionsDialog(pw.Document pdf) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Orders'),
        content: const Text('Choose how you would like to export the report:'),
        actions: [
          TextButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await Printing.layoutPdf(
                onLayout: (PdfPageFormat format) async => pdf.save(),
              );
            },
            icon: const Icon(Icons.print),
            label: const Text('Print'),
          ),
          TextButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await Printing.sharePdf(
                bytes: await pdf.save(),
                filename:
                    'orders_report_${DateTime.now().millisecondsSinceEpoch}.pdf',
              );
            },
            icon: const Icon(Icons.share),
            label: const Text('Share / Save PDF'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  String _typeLabel(OrderType type) => switch (type) {
    OrderType.add => 'Added',
    OrderType.export => 'Exported',
    OrderType.edit => 'Edit Request',
  };

  String _statusLabel(OrderStatus status) => switch (status) {
    OrderStatus.completed => 'Completed',
    OrderStatus.pending => 'Pending',
    OrderStatus.canceled => 'Canceled',
  };

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.year}-$month-$day $hour:$minute';
  }

  String _formatRawDate(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    final month = parsed.month.toString().padLeft(2, '0');
    final day = parsed.day.toString().padLeft(2, '0');
    return '${parsed.year}-$month-$day';
  }
}
