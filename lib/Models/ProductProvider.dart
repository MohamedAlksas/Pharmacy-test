import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:graduation_project/Models/UserRoleModel.dart';
import 'package:graduation_project/Models/materialModel.dart';
import 'package:graduation_project/Services/MaterialSerivce.dart';
import 'package:graduation_project/Services/ProductService.dart';
import 'package:graduation_project/Services/alertService.dart';

class ProductProvider extends ChangeNotifier {
  List<MaterialModel> _products = [];
  bool _loading = false;
  String? _error;

  List<MaterialModel> get products => UnmodifiableListView(_products);
  bool get loading => _loading;
  String? get error => _error;

  int get totalProducts => _products.length;

  int get expiredCount => _products.where((product) {
    final expiry = product.expiryDateValue;
    return expiry != null && expiry.isBefore(DateTime.now());
  }).length;

  int get expiringSoonCount => _products.where((product) {
    final expiry = product.expiryDateValue;
    if (expiry == null) {
      return false;
    }

    final days = expiry.difference(DateTime.now()).inDays;
    return days > 0 && days <= 30;
  }).length;

  int get lowStockCount =>
      _products.where((product) => product.quantity < 100).length;

  Future<void> loadProducts() async {
    if (!AuthService.isAuthenticated) {
      clear(notify: true);
      return;
    }

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _replaceProductsFromApi();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }

    _loading = false;
    notifyListeners();
  }

  Future<String?> addProduct(Map<String, dynamic> body) async {
    try {
      await ProductService.addProduct(body);
      await _refreshProductsAfterMutation();
      return null;
    } catch (e) {
      return _handleMutationError(e);
    }
  }

  Future<String?> updateProduct(String id, Map<String, dynamic> body) async {
    try {
      await ProductService.updateProduct(id, body);
      await _refreshProductsAfterMutation();
      return null;
    } catch (e) {
      return _handleMutationError(e);
    }
  }

  Future<String?> deleteProduct(String id) async {
    try {
      final error = await ProductService.deleteProduct(id);
      if (error != null) {
        return error;
      }

      await _refreshProductsAfterMutation();
      return null;
    } catch (e) {
      return _handleMutationError(e);
    }
  }

  MaterialModel? findBySku(String sku) {
    try {
      return _products.firstWhere(
        (product) => product.sku.toLowerCase() == sku.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  MaterialModel? findById(String id) {
    try {
      return _products.firstWhere((product) => product.id == id);
    } catch (_) {
      return null;
    }
  }

  MaterialModel? findByNameOrSku(String value) {
    final query = value.trim().toLowerCase();
    if (query.isEmpty) return null;
    try {
      return _products.firstWhere(
        (product) =>
            product.sku.toLowerCase() == query ||
            product.name.toLowerCase() == query,
      );
    } catch (_) {
      return null;
    }
  }

  void clear({bool notify = false}) {
    _products = [];
    _loading = false;
    _error = null;
    _syncDerivedState();
    if (notify) {
      notifyListeners();
    }
  }

  void _syncDerivedState() {
    MaterialService.updateCache(_products);
    AlertService.initializeAlertsFromModels(_products);
  }

  Future<List<MaterialModel>> _fetchProductsFromApi() {
    return ProductService.getAllProducts();
  }

  Future<void> _replaceProductsFromApi() async {
    _products = await _fetchProductsFromApi();
    _syncDerivedState();
  }

  Future<void> _refreshProductsAfterMutation() async {
    _error = null;
    await _replaceProductsFromApi();
    notifyListeners();
  }

  String _handleMutationError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '');
    _error = message;
    notifyListeners();
    return message;
  }

  static ProductProvider of(BuildContext context, {bool listen = true}) {
    if (listen) {
      final inherited = context
          .dependOnInheritedWidgetOfExactType<_ProductProviderInherited>();
      assert(
        inherited != null,
        'ProductProviderScope is missing above this widget.',
      );
      return inherited!.provider;
    }

    final element = context
        .getElementForInheritedWidgetOfExactType<_ProductProviderInherited>();
    final widget = element?.widget;
    assert(
      widget != null,
      'ProductProviderScope is missing above this widget.',
    );
    return (widget as _ProductProviderInherited).provider;
  }
}

class ProductProviderScope extends StatefulWidget {
  final Widget child;

  const ProductProviderScope({super.key, required this.child});

  @override
  State<ProductProviderScope> createState() => _ProductProviderScopeState();
}

class _ProductProviderScopeState extends State<ProductProviderScope> {
  final ProductProvider _provider = ProductProvider();

  @override
  void initState() {
    super.initState();
    AuthService.sessionChanges.addListener(_handleSessionChange);
    _handleSessionChange();
  }

  @override
  void dispose() {
    AuthService.sessionChanges.removeListener(_handleSessionChange);
    _provider.dispose();
    super.dispose();
  }

  void _handleSessionChange() {
    if (AuthService.isAuthenticated) {
      _provider.loadProducts();
    } else {
      _provider.clear(notify: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _provider,
      builder: (context, _) {
        return _ProductProviderInherited(
          provider: _provider,
          child: widget.child,
        );
      },
    );
  }
}

class _ProductProviderInherited extends InheritedWidget {
  final ProductProvider provider;

  const _ProductProviderInherited({
    required this.provider,
    required super.child,
  });

  @override
  bool updateShouldNotify(_ProductProviderInherited oldWidget) => true;
}
