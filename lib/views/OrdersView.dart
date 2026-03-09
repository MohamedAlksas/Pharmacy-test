import 'package:flutter/material.dart';
import 'package:graduation_project/Models/UserRoleModel.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  String _selectedDateFilter = 'Filter by Date';
  String _selectedStatusFilter = 'Filter by Status';

  final List<Map<String, String>> orders = [
    {
      'id': 'ORD-2024-101',
      'user': 'Shalaby',
      'date': 'May 21, 2024',
      'status': 'Completed',
      'items': '5 items',
    },
    {
      'id': 'ORD-2024-102',
      'user': 'Alksas',
      'date': 'May 20, 2024',
      'status': 'Pending',
      'items': '3 items',
    },
    {
      'id': 'ORD-2024-103',
      'user': 'Alsais',
      'date': 'May 19, 2024',
      'status': 'Canceled',
      'items': '2 items',
    },
    {
      'id': 'ORD-2024-104',
      'user': 'Magdy',
      'date': 'May 18, 2024',
      'status': 'Completed',
      'items': '7 items',
    },
    {
      'id': 'ORD-2024-105',
      'user': 'Hashad',
      'date': 'May 17, 2024',
      'status': 'Pending',
      'items': '4 items',
    },
    {
      'id': 'ORD-2024-106',
      'user': 'Jovany',
      'date': 'May 16, 2024',
      'status': 'Pending',
      'items': '6 items',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0E1621)
          : const Color(0xFFF5F5F5),
      body: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
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
              ],
            ),
            const SizedBox(height: 28),

            // Search and Filters Row
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1A2332) : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF2A3F5F)
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: TextField(
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search orders by ID, customer...',
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
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _buildDropdownButton(
                  isDark,
                  _selectedDateFilter,
                  [
                    'Filter by Date',
                    'Today',
                    'This Week',
                    'This Month',
                    'This Year',
                  ],
                  (value) => setState(() => _selectedDateFilter = value!),
                ),
                const SizedBox(width: 12),
                _buildDropdownButton(
                  isDark,
                  _selectedStatusFilter,
                  ['Filter by Status', 'Completed', 'Pending', 'Canceled'],
                  (value) => setState(() => _selectedStatusFilter = value!),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Orders List
            Expanded(
              child: ListView.builder(
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildOrderCard(
                      order['id']!,
                      order['user']!,
                      order['date']!,
                      order['status']!,
                      order['items']!,
                      isDark,
                      order,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
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

  Widget _buildOrderCard(
    String orderId,
    String customer,
    String date,
    String status,
    String items,
    bool isDark,
    Map<String, String> order,
  ) {
    final isPending = status == 'Pending';
    final canManage = AuthService.isWarehouseManager;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2332) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF2A3F5F) : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order #$orderId',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$customer - $date',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  items,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _buildStatusBadge(status, isDark),

          // Action buttons for Warehouse Manager
          if (canManage && isPending) ...[
            const SizedBox(width: 12),
            IconButton(
              onPressed: () => _acceptOrder(order),
              icon: const Icon(Icons.check_circle, color: Colors.green),
              tooltip: 'Accept Order',
            ),
            IconButton(
              onPressed: () => _rejectOrder(order),
              icon: const Icon(Icons.cancel, color: Colors.red),
              tooltip: 'Reject Order',
            ),
          ],

          // View details button
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

  Widget _buildStatusBadge(String status, bool isDark) {
    Color backgroundColor;
    Color textColor;

    switch (status) {
      case 'Completed':
        backgroundColor = const Color(0xFF28A745).withOpacity(0.15);
        textColor = const Color(0xFF28A745);
        break;
      case 'Pending':
        backgroundColor = const Color(0xFFFFA500).withOpacity(0.15);
        textColor = const Color(0xFFFFA500);
        break;
      case 'Canceled':
        backgroundColor = const Color(0xFFDC3545).withOpacity(0.15);
        textColor = const Color(0xFFDC3545);
        break;
      default:
        backgroundColor = Colors.grey.withOpacity(0.15);
        textColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  void _acceptOrder(Map<String, String> order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Accept Order'),
        content: Text('Are you sure you want to accept order ${order['id']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
              setState(() {
                order['status'] = 'Completed';
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Order ${order['id']} accepted')),
              );
            },
            child: const Text('Accept'),
          ),
        ],
      ),
    );
  }

  void _rejectOrder(Map<String, String> order) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Are you sure you want to reject order ${order['id']}?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for rejection',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() {
                order['status'] = 'Canceled';
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Order ${order['id']} rejected')),
              );
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _viewOrderDetails(Map<String, String> order, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Container(
          width: 600,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A2332) : Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Order Details',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildDetailRow('Order ID', order['id']!, isDark),
              _buildDetailRow('Customer', order['user']!, isDark),
              _buildDetailRow('Date', order['date']!, isDark),
              _buildDetailRow('Status', order['status']!, isDark),
              _buildDetailRow('Items', order['items']!, isDark),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 16),
              Text(
                'Order Items',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              _buildOrderItem('Paracetamol 500mg', '2 boxes', isDark),
              _buildOrderItem('Ibuprofen 400mg', '1 box', isDark),
              _buildOrderItem('Saline Solution', '3 bottles', isDark),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(String name, String quantity, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A3441) : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.medication,
            color: isDark ? Colors.white70 : Colors.black54,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
            ),
          ),
          Text(
            quantity,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
