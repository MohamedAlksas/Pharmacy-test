import 'package:flutter/material.dart';

// Add Material Dialog with Multi-Step Flow
class AddMaterialDialog extends StatefulWidget {
  const AddMaterialDialog({super.key});

  @override
  State<AddMaterialDialog> createState() => _AddMaterialDialogState();
}

class _AddMaterialDialogState extends State<AddMaterialDialog> {
  int _currentStep = 0;
  final _invoiceController = TextEditingController();
  String? _selectedMaterialType;

  // Existing Material fields
  String? _selectedExistingMaterial;
  final _existingQuantityController = TextEditingController();
  final _existingExpiryController = TextEditingController();

  // New Material fields
  final _newNameController = TextEditingController();
  final _newSerialController = TextEditingController();
  final _newQuantityController = TextEditingController();
  final _newExpiryController = TextEditingController();

  // Session materials
  final List<Map<String, dynamic>> _sessionMaterials = [];

  final List<String> _existingMaterials = [
    'Steel Pipes (SP-2024-001)',
    'Cement Bags (CB-2024-002)',
    'Paint Cans (PC-2024-003)',
  ];

  @override
  void initState() {
    super.initState();
    // Add listener to rebuild when invoice text changes
    _invoiceController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _invoiceController.dispose();
    _existingQuantityController.dispose();
    _existingExpiryController.dispose();
    _newNameController.dispose();
    _newSerialController.dispose();
    _newQuantityController.dispose();
    _newExpiryController.dispose();
    super.dispose();
  }

  void _nextStep() {
    setState(() {
      if (_currentStep < 3) _currentStep++;
    });
  }

  void _previousStep() {
    setState(() {
      if (_currentStep > 0) _currentStep--;
    });
  }

  void _saveMaterial() {
    if (_selectedMaterialType == 'existing') {
      if (_selectedExistingMaterial != null &&
          _existingQuantityController.text.isNotEmpty &&
          _existingExpiryController.text.isNotEmpty) {
        _sessionMaterials.add({
          'name': _selectedExistingMaterial!.split(' (')[0],
          'serial': _selectedExistingMaterial!
              .split('(')[1]
              .replaceAll(')', ''),
          'quantity': _existingQuantityController.text,
          'expiry': _existingExpiryController.text,
          'type': 'existing',
        });
        _clearExistingFields();
        setState(() => _currentStep = 3);
      }
    } else if (_selectedMaterialType == 'new') {
      if (_newNameController.text.isNotEmpty &&
          _newSerialController.text.isNotEmpty &&
          _newQuantityController.text.isNotEmpty &&
          _newExpiryController.text.isNotEmpty) {
        _sessionMaterials.add({
          'name': _newNameController.text,
          'serial': _newSerialController.text,
          'quantity': _newQuantityController.text,
          'expiry': _newExpiryController.text,
          'type': 'new',
        });
        _clearNewFields();
        setState(() => _currentStep = 3);
      }
    }
  }

  void _clearExistingFields() {
    _selectedExistingMaterial = null;
    _existingQuantityController.clear();
    _existingExpiryController.clear();
  }

  void _clearNewFields() {
    _newNameController.clear();
    _newSerialController.clear();
    _newQuantityController.clear();
    _newExpiryController.clear();
  }

  void _finishAndSave() {
    Navigator.pop(context, _sessionMaterials);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1B2430) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 800,
        constraints: const BoxConstraints(maxHeight: 700),
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(isDark),
            const SizedBox(height: 24),
            Expanded(child: _buildStepContent(isDark)),
            const SizedBox(height: 24),
            _buildActions(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    String title;
    String subtitle = '';

    switch (_currentStep) {
      case 0:
        title = 'Add Material - Invoice Information';
        break;
      case 1:
        title = 'Add Material - Select Type';
        subtitle = 'Invoice: ${_invoiceController.text}';
        break;
      case 2:
        title =
            'Add Material - ${_selectedMaterialType == 'existing' ? 'Existing Material' : 'New Material'}';
        subtitle = 'Invoice: ${_invoiceController.text}';
        break;
      case 3:
        title = 'Add Material - Session Summary';
        subtitle = 'Invoice: ${_invoiceController.text}';
        break;
      default:
        title = 'Add Material';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
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
      ],
    );
  }

  Widget _buildStepContent(bool isDark) {
    switch (_currentStep) {
      case 0:
        return _buildInvoiceStep(isDark);
      case 1:
        return _buildTypeSelectionStep(isDark);
      case 2:
        return _selectedMaterialType == 'existing'
            ? _buildExistingMaterialStep(isDark)
            : _buildNewMaterialStep(isDark);
      case 3:
        return _buildSessionSummaryStep(isDark);
      default:
        return Container();
    }
  }

  Widget _buildInvoiceStep(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Invoice Number',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _invoiceController,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(
            hintText: 'Enter invoice number',
            prefixIcon: const Icon(Icons.receipt_long),
            filled: true,
            fillColor: isDark ? const Color(0xFF2A3441) : Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeSelectionStep(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose how you want to add the material:',
          style: TextStyle(
            fontSize: 16,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _buildTypeCard(
                isDark: isDark,
                icon: Icons.inventory_2,
                title: 'Add to Existing Material',
                subtitle:
                    'Update quantity of a material already in the warehouse',
                color: Colors.blue,
                isSelected: _selectedMaterialType == 'existing',
                onTap: () => setState(() => _selectedMaterialType = 'existing'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTypeCard(
                isDark: isDark,
                icon: Icons.add_box,
                title: 'Add New Material',
                subtitle: 'Add a material not currently in the warehouse',
                color: Colors.green,
                isSelected: _selectedMaterialType == 'new',
                onTap: () => setState(() => _selectedMaterialType = 'new'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeCard({
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A3441) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExistingMaterialStep(bool isDark) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Material',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedExistingMaterial,
            dropdownColor: isDark ? const Color(0xFF2A3441) : Colors.white,
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
            decoration: InputDecoration(
              hintText: '-- Select a material --',
              filled: true,
              fillColor: isDark ? const Color(0xFF2A3441) : Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
            items: _existingMaterials.map((material) {
              return DropdownMenuItem(value: material, child: Text(material));
            }).toList(),
            onChanged: (value) =>
                setState(() => _selectedExistingMaterial = value),
          ),
          const SizedBox(height: 20),
          Text(
            'Quantity to Add',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _existingQuantityController,
            keyboardType: TextInputType.number,
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
            decoration: InputDecoration(
              hintText: 'Enter quantity',
              prefixIcon: const Icon(Icons.inventory),
              filled: true,
              fillColor: isDark ? const Color(0xFF2A3441) : Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Expiration Date',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _existingExpiryController,
            readOnly: true,
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
            decoration: InputDecoration(
              hintText: 'mm/dd/yyyy',
              prefixIcon: const Icon(Icons.calendar_today),
              filled: true,
              fillColor: isDark ? const Color(0xFF2A3441) : Colors.grey[100],
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
                _existingExpiryController.text =
                    "${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}";
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNewMaterialStep(bool isDark) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField(
            isDark: isDark,
            label: 'Material Name',
            controller: _newNameController,
            hintText: 'Enter material name',
            icon: Icons.label,
          ),
          const SizedBox(height: 20),
          _buildTextField(
            isDark: isDark,
            label: 'Serial Number',
            controller: _newSerialController,
            hintText: 'Enter serial number',
            icon: Icons.tag,
          ),
          const SizedBox(height: 20),
          _buildTextField(
            isDark: isDark,
            label: 'Quantity',
            controller: _newQuantityController,
            hintText: 'Enter quantity',
            icon: Icons.inventory,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 20),
          Text(
            'Expiration Date',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _newExpiryController,
            readOnly: true,
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
            decoration: InputDecoration(
              hintText: 'mm/dd/yyyy',
              prefixIcon: const Icon(Icons.calendar_today),
              filled: true,
              fillColor: isDark ? const Color(0xFF2A3441) : Colors.grey[100],
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
                _newExpiryController.text =
                    "${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}";
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required bool isDark,
    required String label,
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: Icon(icon),
            filled: true,
            fillColor: isDark ? const Color(0xFF2A3441) : Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSessionSummaryStep(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose how you want to add the material:',
          style: TextStyle(
            fontSize: 16,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _buildTypeCard(
                
                isDark: isDark,
                icon: Icons.inventory_2,
                title: 'Add to Existing Material',
                subtitle:
                    'Update quantity of a material already in the warehouse',
                color: Colors.blue,
                isSelected: false,
                onTap: () => setState(() {
                  _selectedMaterialType = 'existing';
                  _currentStep = 2;
                }),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTypeCard(
                isDark: isDark,
                icon: Icons.add_box,
                title: 'Add New Material',
                subtitle: 'Add a material not currently in the warehouse',
                color: Colors.green,
                isSelected: false,
                onTap: () => setState(() {
                  _selectedMaterialType = 'new';
                  _currentStep = 2;
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Text(
          'Materials Added in This Session (${_sessionMaterials.length})',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        if (_sessionMaterials.isEmpty)
          Center(
            child: Text(
              'No materials added yet',
              style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
            ),
          )
        else
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A3441) : Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1A2332)
                          : Colors.grey[200],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(10),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Material Name',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Serial Number',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Quantity',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Expiration Date',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _sessionMaterials.length,
                      itemBuilder: (context, index) {
                        final material = _sessionMaterials[index];
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: isDark
                                    ? const Color(0xFF1A2332)
                                    : Colors.grey[300]!,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.inventory,
                                      size: 16,
                                      color: Colors.blue,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      material['name'],
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  material['serial'],
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    material['quantity'],
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  material['expiry'],
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black87,
                                  ),
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
      ],
    );
  }

  Widget _buildActions(bool isDark) {
    if (_currentStep == 0) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _invoiceController.text.isNotEmpty ? _nextStep : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Continue'),
          ),
        ],
      );
    } else if (_currentStep == 1) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed: _previousStep,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back'),
          ),
          ElevatedButton(
            onPressed: _selectedMaterialType != null
                ? () => setState(() => _currentStep = 2)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Continue'),
          ),
        ],
      );
    } else if (_currentStep == 2) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed: _previousStep,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back'),
          ),
          Row(
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _saveMaterial,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text('Save Material'),
              ),
            ],
          ),
        ],
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed: _previousStep,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back'),
          ),
          ElevatedButton.icon(
            onPressed: _sessionMaterials.isNotEmpty ? _finishAndSave : null,
            icon: const Icon(Icons.check),
            label: const Text('Finish & Save All Materials'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      );
    }
  }
}
