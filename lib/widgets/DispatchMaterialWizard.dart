import 'package:flutter/material.dart';
import 'package:graduation_project/Models/ProductProvider.dart';
import 'package:graduation_project/Models/app_localizations.dart';
import 'package:graduation_project/Models/materialModel.dart';
import 'package:graduation_project/Models/orderModel.dart';
import 'package:graduation_project/Models/UserRoleModel.dart';
import 'package:graduation_project/Services/orderService.dart';
import 'package:graduation_project/widgets/toast.dart';

class DispatchMaterialWizard extends StatefulWidget {
  final ProductProvider provider;

  const DispatchMaterialWizard({super.key, required this.provider});

  @override
  State<DispatchMaterialWizard> createState() => _DispatchMaterialWizardState();
}

class _DispatchMaterialWizardState extends State<DispatchMaterialWizard> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();

  final _invoiceController = TextEditingController();

  final _searchController = TextEditingController();
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _qtyController = TextEditingController();
  final _unitController = TextEditingController();
  final _lotController = TextEditingController();
  final _categoryIdController = TextEditingController();

  MaterialModel? _selectedProduct;
  String _query = '';
  String? _inlineError;

  @override
  void dispose() {
    _invoiceController.dispose();
    _searchController.dispose();
    _nameController.dispose();
    _skuController.dispose();
    _qtyController.dispose();
    _unitController.dispose();
    _lotController.dispose();
    _categoryIdController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final tr = context.tr;
    setState(() => _inlineError = null);
    if (!_formKey.currentState!.validate()) return;

    final selected = _selectedProduct;
    final product = selected == null
        ? widget.provider.findByNameOrSku(_skuController.text.trim()) ??
              widget.provider.findByNameOrSku(_nameController.text.trim())
        : widget.provider.findById(selected.id) ?? selected;
    if (product == null) {
      setState(() => _inlineError = tr.productNotFound);
      return;
    }

    final qty = int.parse(_qtyController.text.trim());

    if (product.quantity == 0) {
      setState(() => _inlineError = tr.outOfStock);
      return;
    }

    if (qty > product.quantity) {
      setState(() => _inlineError = tr.exceedsStock);
      return;
    }

    final nextQty = product.quantity - qty;
    final nextAvail = nextQty > 0;

    final body = <String, dynamic>{
      'materialName': product.name,
      'material_SKU': product.sku,
      'quantity': nextQty,
      'unit': product.unit,
      'logNumber': product.lot,
      'expiryDate': product.expiryDate,
      'storageLocation': product.location,
      'isAvailable': nextAvail,
      if (product.categoryId > 0) 'categoryId': product.categoryId,
      if (product.category.isNotEmpty &&
          product.category != 'Uncategorized')
        'categoryName': product.category,
    };

    final error = await widget.provider.updateProduct(product.id, body);
    if (!context.mounted) return;

    if (error != null) {
      showToast(context, error, backgroundColor: Colors.red);
      return;
    }

    OrderService.addOrder(
      OrderModel(
        productId: product.id,
        productName: product.name,
        productSku: product.sku,
        quantity: qty,
        unit: product.unit,
        logNumber: product.lot,
        categoryId: product.categoryId,
        type: OrderType.export,
        status: OrderStatus.completed,
        createdBy: AuthService.currentUser?.fullName ?? tr.unknownUser,
        notes: _invoiceController.text.trim().isEmpty
            ? null
            : 'Invoice: ${_invoiceController.text.trim()}',
      ),
    );

    final outOfStock = nextQty == 0;
    showToast(
      context,
      outOfStock
          ? tr.outOfStockWarning(qty, product.name)
          : tr.unitsDispatched(qty, product.name),
      backgroundColor: outOfStock ? Colors.orange : null,
    );

    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(tr, isDark),
              const SizedBox(height: 20),
              _buildStepIndicator(isDark),
              const SizedBox(height: 24),
              if (_currentStep == 0)
                _buildInvoiceStep(tr, isDark)
              else
                Expanded(
                  child: SingleChildScrollView(
                    child: _buildDispatchStep(tr, isDark, selected, results),
                  ),
                ),
              const SizedBox(height: 24),
              _buildActions(tr, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations tr, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr.exportProductTitle,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                tr.exportProductSubtitle,
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
          icon: Icon(Icons.close,
              color: isDark ? Colors.white70 : Colors.black54),
        ),
      ],
    );
  }

  Widget _buildStepIndicator(bool isDark) {
    return Row(
      children: [
        _stepDot(0, '1', isDark),
        _stepLine(isDark),
        _stepDot(1, '2', isDark),
      ],
    );
  }

  Widget _stepDot(int index, String label, bool isDark) {
    final active = _currentStep >= index;
    final current = _currentStep == index;
    final color = const Color(0xFF1CA0A5);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? color : Colors.transparent,
            border: active ? null : Border.all(color: isDark ? Colors.white38 : Colors.black26),
          ),
          child: Center(
            child: active
                ? const Icon(Icons.check, size: 20, color: Colors.white)
                : Text(
                    label,
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black45,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          index == 0 ? _tr(context).invoiceNumber : _tr(context).exportProductBtn,
          style: TextStyle(
            fontSize: 11,
            color: current
                ? color
                : isDark
                    ? Colors.white54
                    : Colors.black45,
            fontWeight: current ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  AppLocalizations _tr(BuildContext context) => context.tr;

  Widget _stepLine(bool isDark) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 24),
        color: _currentStep >= 1
            ? const Color(0xFF1CA0A5)
            : isDark
                ? Colors.white12
                : Colors.black12,
      ),
    );
  }

  Widget _buildInvoiceStep(AppLocalizations tr, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: _field(
        controller: _invoiceController,
        label: tr.invoiceNumber,
        hintText: 'e.g. INV-2025-001',
        icon: Icons.description,
        isDark: isDark,
        width: 572,
        validator: _required,
      ),
    );
  }

  Widget _buildDispatchStep(
    AppLocalizations tr,
    bool isDark,
    bool selected,
    List<MaterialModel> results,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _field(
          controller: _searchController,
          label: tr.searchByNameOrSku,
          hintText: tr.typeHintSearch,
          icon: Icons.search,
          isDark: isDark,
          validator: (_) => null,
          readOnly: selected,
          width: 572,
          onChanged: (value) => setState(() => _query = value),
        ),
        if (!selected && results.isNotEmpty) _resultsList(results, isDark),
        if (selected)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _clearSelection,
              icon: const Icon(Icons.clear),
              label: Text(tr.clear),
            ),
          ),
        const SizedBox(height: 14),
        if (selected) _buildProductInfoBox(tr, isDark),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _field(
              controller: _nameController,
              label: tr.materialName,
              hintText: 'e.g. Paracetamol',
              icon: Icons.medication_outlined,
              isDark: isDark,
              readOnly: selected,
              onChanged: _syncQuery,
            ),
            _field(
              controller: _skuController,
              label: tr.materialSku,
              hintText: 'e.g. MED-1001',
              icon: Icons.qr_code_2_outlined,
              isDark: isDark,
              readOnly: selected,
              onChanged: _syncQuery,
            ),
            _field(
              controller: _qtyController,
              label: tr.quantity,
              hintText: '1',
              icon: Icons.inventory_2_outlined,
              keyboardType: TextInputType.number,
              isDark: isDark,
              validator: _validatePositiveInteger,
            ),
            _field(
              controller: _unitController,
              label: tr.unit,
              hintText: 'box / bottle / strip',
              icon: Icons.straighten_outlined,
              isDark: isDark,
              readOnly: selected,
            ),
            _field(
              controller: _lotController,
              label: tr.logNumber,
              hintText: 'LOT-2026-01',
              icon: Icons.badge_outlined,
              isDark: isDark,
              readOnly: selected,
            ),
            _field(
              controller: _categoryIdController,
              label: tr.categoryId,
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _inlineError!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProductInfoBox(AppLocalizations tr, bool isDark) {
    final product = _selectedProduct!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A3441) : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.orange.shade800.withOpacity(0.3)
              : Colors.orange.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline,
                  color: Colors.orange.shade400, size: 18),
              const SizedBox(width: 8),
              Text(
                'Selected Material Details',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _infoRow(tr.materialName, product.name, isDark),
          _infoRow(tr.materialSku, product.sku, isDark),
          _infoRow('Current Stock', product.quantity.toString(), isDark),
          _infoRow(tr.unit, product.unit, isDark),
          _infoRow(tr.expiryDate, product.expiryDate, isDark),
          _infoRow(tr.storageLocation, product.location, isDark),
          _infoRow(tr.logNumber, product.lot, isDark),
          if (product.category.isNotEmpty)
            _infoRow(tr.category, product.category, isDark),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                product.isAvailable
                    ? Icons.check_circle_outline
                    : Icons.cancel_outlined,
                size: 16,
                color: product.isAvailable ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 6),
              Text(
                product.isAvailable ? tr.available : tr.unavailable,
                style: TextStyle(
                  fontSize: 13,
                  color: product.isAvailable ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                '${tr.quantity}: ${product.quantity}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(AppLocalizations tr, bool isDark) {
    return Row(
      mainAxisAlignment: _currentStep == 0
          ? MainAxisAlignment.end
          : MainAxisAlignment.spaceBetween,
      children: [
        if (_currentStep == 1)
          TextButton.icon(
            onPressed: () => setState(() {
              _currentStep = 0;
              _inlineError = null;
            }),
            icon: Icon(Icons.arrow_back,
                size: 18,
                color: isDark ? Colors.white70 : Colors.black54),
            label: Text(
              tr.back,
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
        Row(
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(tr.cancel),
            ),
            const SizedBox(width: 12),
            if (_currentStep == 0)
              ElevatedButton.icon(
                onPressed: _goToNextStep,
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text('Next'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1CA0A5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 14),
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.upload_outlined),
                label: Text(tr.exportProductBtn),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1CA0A5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 14),
                ),
              ),
          ],
        ),
      ],
    );
  }

  void _goToNextStep() {
    final tr = context.tr;
    final invoice = _invoiceController.text.trim();
    if (invoice.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr.required)),
      );
      return;
    }
    setState(() => _currentStep = 1);
  }

  Widget _resultsList(List<MaterialModel> results, bool isDark) {
    final tr = context.tr;
    return Container(
      width: 572,
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
            subtitle: Text(
                '${tr.sku}: ${product.sku} | ${tr.quantity}: ${product.quantity}'),
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
            style:
                TextStyle(color: isDark ? Colors.white : Colors.black87),
            decoration: InputDecoration(
              hintText: hintText,
              prefixIcon: Icon(icon),
              suffixIcon:
                  readOnly ? const Icon(Icons.lock_outline) : null,
              filled: true,
              fillColor:
                  isDark ? const Color(0xFF2A3441) : Colors.grey[100],
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
      _qtyController.clear();
      _unitController.text = product.unit;
      _lotController.text = product.lot;
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
      _qtyController.clear();
      _unitController.clear();
      _lotController.clear();
      _categoryIdController.clear();
    });
  }

  String? _required(String? value) {
    final tr = context.tr;
    if (value == null || value.trim().isEmpty) return tr.required;
    return null;
  }

  String? _validatePositiveInteger(String? value) {
    final tr = context.tr;
    if (value == null || value.trim().isEmpty) return tr.required;
    final parsed = int.tryParse(value.trim());
    if (parsed == null || parsed <= 0) return tr.positiveNumber;
    return null;
  }
}
