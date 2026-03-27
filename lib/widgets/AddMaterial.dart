import 'package:flutter/material.dart';
import 'package:graduation_project/Models/materialModel.dart';

class AddMaterialDialog extends StatefulWidget {
  final MaterialModel? initialProduct;

  const AddMaterialDialog({super.key, this.initialProduct});

  bool get isEditing => initialProduct != null;

  @override
  State<AddMaterialDialog> createState() => _AddMaterialDialogState();
}

class _AddMaterialDialogState extends State<AddMaterialDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitController = TextEditingController();
  final _logNumberController = TextEditingController();
  final _storageLocationController = TextEditingController();
  final _categoryIdController = TextEditingController();

  DateTime? _expiryDate;
  bool _isAvailable = true;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    final product = widget.initialProduct;
    if (product != null) {
      _nameController.text = product.name;
      _skuController.text = product.sku;
      _quantityController.text = product.quantity.toString();
      _unitController.text = product.unit;
      _logNumberController.text = product.lot;
      _storageLocationController.text = product.location;
      _categoryIdController.text = product.categoryId.toString();
      _expiryDate = product.expiryDateValue;
      _isAvailable = product.isAvailable;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _logNumberController.dispose();
    _storageLocationController.dispose();
    _categoryIdController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final initialDate = _expiryDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() => _expiryDate = picked);
    }
  }

  void _submit() {
    setState(() => _submitted = true);

    if (!_formKey.currentState!.validate() || _expiryDate == null) {
      return;
    }

    Navigator.pop(context, {
      'materialName': _nameController.text.trim(),
      'material_SKU': _skuController.text.trim(),
      'quantity': int.parse(_quantityController.text.trim()),
      'unit': _unitController.text.trim(),
      'logNumber': _logNumberController.text.trim(),
      'expiryDate': _expiryDate!.toUtc().toIso8601String(),
      'storageLocation': _storageLocationController.text.trim(),
      'isAvailable': _isAvailable,
      'categoryId': int.parse(_categoryIdController.text.trim()),
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                            widget.isEditing ? 'Edit Product' : 'Add Product',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Fill in the pharmacy inventory product details.',
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
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _buildField(
                      controller: _nameController,
                      label: 'Material Name',
                      hintText: 'e.g. Paracetamol',
                      icon: Icons.medication_outlined,
                      isDark: isDark,
                    ),
                    _buildField(
                      controller: _skuController,
                      label: 'Material SKU',
                      hintText: 'e.g. MED-1001',
                      icon: Icons.qr_code_2_outlined,
                      isDark: isDark,
                    ),
                    _buildField(
                      controller: _quantityController,
                      label: 'Quantity',
                      hintText: '0',
                      icon: Icons.inventory_2_outlined,
                      keyboardType: TextInputType.number,
                      isDark: isDark,
                      validator: _validateNonNegativeInteger,
                    ),
                    _buildField(
                      controller: _unitController,
                      label: 'Unit',
                      hintText: 'box / bottle / strip',
                      icon: Icons.straighten_outlined,
                      isDark: isDark,
                    ),
                    _buildField(
                      controller: _logNumberController,
                      label: 'Log Number',
                      hintText: 'LOT-2026-01',
                      icon: Icons.badge_outlined,
                      isDark: isDark,
                    ),
                    _buildField(
                      controller: _storageLocationController,
                      label: 'Storage Location',
                      hintText: 'Rack A - Shelf 2',
                      icon: Icons.location_on_outlined,
                      isDark: isDark,
                    ),
                    _buildField(
                      controller: _categoryIdController,
                      label: 'Category ID',
                      hintText: '1',
                      icon: Icons.category_outlined,
                      keyboardType: TextInputType.number,
                      isDark: isDark,
                      validator: _validateNonNegativeInteger,
                    ),
                    SizedBox(
                      width: 280,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Expiry Date',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: _pickDate,
                            borderRadius: BorderRadius.circular(12),
                            child: InputDecorator(
                              decoration: InputDecoration(
                                prefixIcon: const Icon(
                                  Icons.calendar_today_outlined,
                                ),
                                filled: true,
                                fillColor: isDark
                                    ? const Color(0xFF2A3441)
                                    : Colors.grey[100],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                errorText: _submitted && _expiryDate == null
                                    ? 'Please select an expiry date'
                                    : null,
                              ),
                              child: Text(
                                _expiryDate == null
                                    ? 'Select date'
                                    : _formatDate(_expiryDate!),
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Available for use',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    'Toggle product availability in stock views.',
                    style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                  value: _isAvailable,
                  onChanged: (value) => setState(() => _isAvailable = value),
                ),
                const SizedBox(height: 20),
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
                      icon: Icon(widget.isEditing ? Icons.save : Icons.add),
                      label: Text(
                        widget.isEditing ? 'Save Changes' : 'Add Product',
                      ),
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

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData icon,
    required bool isDark,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return SizedBox(
      width: 280,
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
            validator:
                validator ??
                (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            decoration: InputDecoration(
              hintText: hintText,
              prefixIcon: Icon(icon),
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

  String? _validateNonNegativeInteger(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }

    final parsed = int.tryParse(value.trim());
    if (parsed == null || parsed < 0) {
      return 'Enter a valid number';
    }
    return null;
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
