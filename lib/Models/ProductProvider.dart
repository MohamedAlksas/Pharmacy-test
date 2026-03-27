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

  List<MaterialModel> get products => List.unmodifiable(_products);
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
      _products = AuthService.isWarehouseManager
          ? await ProductService.getAdminProducts()
          : await ProductService.getAllProducts();
      _syncDerivedState();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }

    _loading = false;
    notifyListeners();
  }

  Future<String?> addProduct(Map<String, dynamic> body) async {
    try {
      final newProduct = await ProductService.addProduct(body);
      if (newProduct.id.isEmpty) {
        await loadProducts();
      } else {
        _products = [..._products, newProduct];
        _syncDerivedState();
        notifyListeners();
      }
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<String?> updateProduct(String id, Map<String, dynamic> body) async {
    try {
      final updatedProduct = await ProductService.updateProduct(id, body);
      if (updatedProduct.id.isEmpty) {
        await loadProducts();
      } else {
        final index = _products.indexWhere((product) => product.id == id);
        if (index != -1) {
          _products[index] = updatedProduct;
        }
        _syncDerivedState();
        notifyListeners();
      }
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<String?> deleteProduct(String id) async {
    final error = await ProductService.deleteProduct(id);
    if (error == null) {
      _products = _products.where((product) => product.id != id).toList();
      _syncDerivedState();
      notifyListeners();
    }
    return error;
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
