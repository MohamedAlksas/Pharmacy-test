import 'package:flutter/material.dart';
import 'package:graduation_project/widgets/AddMaterial.dart';
// Import the AddMaterialDialog from the previous artifact

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final TextEditingController _searchCtrl = TextEditingController();

  List<Map<String, dynamic>> materials = [
    {
      "name": "Paracetamol 500mg",
      "sku": "SKU-PARA500",
      "lot": "LOT-0001",
      "location": "Shelf A-1",
      "qty": 620,
      "expiry": "2026-01-20",
      "cat": "Analgesic",
    },
    {
      "name": "Ibuprofen 400mg",
      "sku": "SKU-IBU400",
      "lot": "LOT-0002",
      "location": "Shelf A-2",
      "qty": 185,
      "expiry": "2025-05-11",
      "cat": "Analgesic",
    },
    {
      "name": "Amoxicillin 250mg",
      "sku": "SKU-AMX250",
      "lot": "LOT-0003",
      "location": "Shelf A-3",
      "qty": 90,
      "expiry": "2025-10-01",
      "cat": "Antibiotic",
    },
    {
      "name": "Saline Solution 0.9%",
      "sku": "SKU-SAL090",
      "lot": "LOT-0004",
      "location": "Shelf B-1",
      "qty": 52,
      "expiry": "2027-02-15",
      "cat": "IV Fluids",
    },
    {
      "name": "Vitamin C 500mg",
      "sku": "SKU-VIT500",
      "lot": "LOT-0005",
      "location": "Shelf B-2",
      "qty": 330,
      "expiry": "2026-09-10",
      "cat": "Supplements",
    },
  ];

  String? _filterCategory;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filtered = materials.where((item) {
      final matchesSearch = item["name"].toString().toLowerCase().contains(
        _searchCtrl.text.toLowerCase(),
      );
      final matchesFilter = _filterCategory == null
          ? true
          : item["cat"] == _filterCategory;
      return matchesSearch && matchesFilter;
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: "Search by material name...",
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              DropdownButton<String>(
                hint: const Text("Category"),
                value: _filterCategory,
                items: ["Analgesic", "Antibiotic", "IV Fluids", "Supplements"]
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _filterCategory = v),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () => _openAddMaterialDialog(context),
                icon: const Icon(Icons.add),
                label: const Text("Add Material"),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Theme.of(context).cardColor,
              ),
              child: SingleChildScrollView(
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text("Material")),
                    DataColumn(label: Text("Category")),
                    DataColumn(label: Text("Quantity")),
                    DataColumn(label: Text("Expiry Date")),
                    DataColumn(label: Text("Actions")),
                  ],
                  rows: filtered.map((item) {
                    return DataRow(
                      cells: [
                        DataCell(Text(item["name"])),
                        DataCell(Text(item["cat"])),
                        DataCell(Text(item["qty"].toString())),
                        DataCell(Text(item["expiry"])),
                        DataCell(
                          Row(
                            children: [
                              Tooltip(
                                message: "Edit Material",
                                child: IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () {},
                                ),
                              ),
                              Tooltip(
                                message: "Update Expiry",
                                child: IconButton(
                                  icon: const Icon(Icons.change_circle),
                                  color: Colors.blue,
                                  onPressed: () =>
                                      _openUpdateExpiry(context, item),
                                ),
                              ),
                              Tooltip(
                                message: "Delete",
                                child: IconButton(
                                  icon: const Icon(Icons.delete_forever),
                                  color: Colors.red,
                                  onPressed: () => _deleteMaterial(item),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Open the new multi-step Add Material Dialog
  void _openAddMaterialDialog(BuildContext context) async {
    final result = await showDialog<List<Map<String, dynamic>>>(
      context: context,
      builder: (ctx) => const AddMaterialDialog(),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        for (var material in result) {
          materials.add({
            "name": material['name'],
            "sku": material['serial'],
            "lot": "LOT-NEW",
            "location": "Shelf NEW",
            "qty": int.tryParse(material['quantity']) ?? 0,
            "expiry": material['expiry'],
            "cat": "New Category",
          });
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${result.length} material(s) added successfully'),
        ),
      );
    }
  }

  // Delete material
  void _deleteMaterial(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Material'),
        content: Text('Are you sure you want to delete "${item["name"]}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() {
                materials.remove(item);
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${item["name"]} deleted successfully')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Update expiry (keeping existing implementation)
  void _openUpdateExpiry(BuildContext context, Map<String, dynamic> item) {
    final TextEditingController newExpiryCtrl = TextEditingController();
    final TextEditingController reasonCtrl = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(40),
        backgroundColor: isDark ? const Color(0xFF1B2430) : Colors.white,
        child: Container(
          width: 650,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Update Expiry Date",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Material Name:",
                          style: TextStyle(
                            color: isDark ? Colors.grey[400] : Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "SKU:",
                          style: TextStyle(
                            color: isDark ? Colors.grey[400] : Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Current Expiration Date:",
                          style: TextStyle(
                            color: isDark ? Colors.grey[400] : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          item["name"],
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item["sku"],
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item["expiry"],
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Text(
                "New Expiration Date",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: newExpiryCtrl,
                readOnly: true,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  hintText: "Select new date...",
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                  suffixIcon: const Icon(Icons.calendar_today),
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF2A3441)
                      : Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    newExpiryCtrl.text =
                        "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                  }
                },
              ),
              const SizedBox(height: 20),
              Text(
                "Reason for Update",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: reasonCtrl,
                maxLines: 2,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  hintText: "Enter reason...",
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF2A3441)
                      : Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(
                      "Cancel",
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () {
                      if (newExpiryCtrl.text.isNotEmpty) {
                        item["expiry"] = newExpiryCtrl.text;
                        setState(() {});
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Expiry date updated for ${item["name"]}',
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please select a new expiry date'),
                          ),
                        );
                      }
                    },
                    child: const Text("Update Expiry Date"),
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
