import 'package:flutter/material.dart';
import 'package:graduation_project/Models/ProductProvider.dart';
import 'package:graduation_project/Models/materialModel.dart';

class ExportMaterialResult {
  final MaterialModel product;
  final int quantity;
  final Map<String, dynamic> body;

  const ExportMaterialResult({
    required this.product,
    required this.quantity,
    required this.body,
  });
}

class ExportMaterialDialog extends StatefulWidget {
  final ProductProvider provider;

  const ExportMaterialDialog({super.key, required this.provider});

  @override
  State<ExportMaterialDialog> createState() => _ExportMaterialDialogState();
}

class _ExportMaterialDialogState extends State<ExportMaterialDialog> {
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitController = TextEditingController();
  final _logNumberController = TextEditingController();
  final _categoryIdController = TextEditingController();

  MaterialModel? _selectedProduct;
  String _query = '';
  String? _inlineError;

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _skuController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _logNumberController.dispose();
    _categoryIdController.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() => _inlineError = null);
    if (!_formKey.currentState!.validate()) return;

    final selectedProduct = _selectedProduct;
    final product = selectedProduct == null
        ? widget.provider.findByNameOrSku(_skuController.text.trim()) ??
              widget.provider.findByNameOrSku(_nameController.text.trim())
        : widget.provider.findById(selectedProduct.id) ?? selectedProduct;
    if (product == null) {
      setState(() => _inlineError = 'Product not found in inventory');
      return;
    }

    final quantity = int.parse(_quantityController.text.trim());
    final nextQuantity = product.quantity - quantity;
    if (nextQuantity < 0) {
      setState(() => _inlineError = 'Export quantity exceeds available stock');
      return;
    }

    final body = product.toApiBody();
    body['quantity'] = nextQuantity;
    Navigator.pop(
      context,
      ExportMaterialResult(product: product, quantity: quantity, body: body),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selected = _selectedProduct != null;
    final results = _matchingProducts();

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      backgroundColor: isDark ? const Color(0xFF1B2430) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Container(
        width: 620,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Export Product',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Record product leaving warehouse inventory.',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _field(
                  controller: _searchController,
                  label: 'Search by Name or SKU',
                  hintText: 'Type material name or SKU',
                  icon: Icons.search,
                  isDark: isDark,
                  validator: (_) => null,
                  readOnly: selected,
                  width: 576,
                  onChanged: (value) => setState(() => _query = value),
                ),
                if (!selected && results.isNotEmpty)
                  _resultsList(results, isDark),
                if (selected)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _clearSelection,
                      icon: const Icon(Icons.clear),
                      label: const Text('Clear'),
                    ),
                  ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _field(
                      controller: _nameController,
                      label: 'Material Name',
                      hintText: 'e.g. Paracetamol',
                      icon: Icons.medication_outlined,
                      isDark: isDark,
                      readOnly: selected,
                      onChanged: _syncQuery,
                    ),
                    _field(
                      controller: _skuController,
                      label: 'Material SKU',
                      hintText: 'e.g. MED-1001',
                      icon: Icons.qr_code_2_outlined,
                      isDark: isDark,
                      readOnly: selected,
                      onChanged: _syncQuery,
                    ),
                    _field(
                      controller: _quantityController,
                      label: 'Quantity',
                      hintText: '1',
                      icon: Icons.inventory_2_outlined,
                      keyboardType: TextInputType.number,
                      isDark: isDark,
                      validator: _validatePositiveInteger,
                    ),
                    _field(
                      controller: _unitController,
                      label: 'Unit',
                      hintText: 'box / bottle / strip',
                      icon: Icons.straighten_outlined,
                      isDark: isDark,
                      readOnly: selected,
                    ),
                    _field(
                      controller: _logNumberController,
                      label: 'Log Number',
                      hintText: 'LOT-2026-01',
                      icon: Icons.badge_outlined,
                      isDark: isDark,
                      readOnly: selected,
                    ),
                    _field(
                      controller: _categoryIdController,
                      label: 'Category ID',
                      hintText: '1',
                      icon: Icons.category_outlined,
                      keyboardType: TextInputType.number,
                      isDark: isDark,
                      readOnly: selected,
                      validator: _validatePositiveInteger,
                    ),
                  ],
                ),
                if (_inlineError != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _inlineError!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.upload_outlined),
                      label: const Text('Export Product'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1CA0A5),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _resultsList(List<MaterialModel> results, bool isDark) {
    return Container(
      width: 576,
      constraints: const BoxConstraints(maxHeight: 190),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A3441) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: results.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final product = results[index];
          return ListTile(
            dense: true,
            title: Text(product.name),
            subtitle: Text('SKU: ${product.sku} | Stock: ${product.quantity}'),
            onTap: () => _selectProduct(product),
          );
        },
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData icon,
    required bool isDark,
    double width = 280,
    bool readOnly = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
  }) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            readOnly: readOnly,
            onChanged: onChanged,
            validator: readOnly ? (_) => null : validator ?? _required,
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            decoration: InputDecoration(
              hintText: hintText,
              prefixIcon: Icon(icon),
              suffixIcon: readOnly ? const Icon(Icons.lock_outline) : null,
              filled: true,
              fillColor: isDark ? const Color(0xFF2A3441) : Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<MaterialModel> _matchingProducts() {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return const [];
    return widget.provider.products
        .where(
          (product) =>
              product.name.toLowerCase().contains(query) ||
              product.sku.toLowerCase().contains(query),
        )
        .take(6)
        .toList();
  }

  void _selectProduct(MaterialModel product) {
    setState(() {
      _selectedProduct = product;
      _searchController.text = '${product.name} (${product.sku})';
      _nameController.text = product.name;
      _skuController.text = product.sku;
      _quantityController.clear();
      _unitController.text = product.unit;
      _logNumberController.text = product.lot;
      _categoryIdController.text = product.categoryId.toString();
      _query = '';
      _inlineError = null;
    });
  }

  void _syncQuery(String value) {
    if (_selectedProduct != null) return;
    setState(() {
      _query = value;
      _searchController.text = value;
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedProduct = null;
      _inlineError = null;
      _query = '';
      _searchController.clear();
      _nameController.clear();
      _skuController.clear();
      _quantityController.clear();
      _unitController.clear();
      _logNumberController.clear();
      _categoryIdController.clear();
    });
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    return null;
  }

  String? _validatePositiveInteger(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    final parsed = int.tryParse(value.trim());
    if (parsed == null || parsed <= 0) return 'Enter a positive number';
    return null;
  }
}
