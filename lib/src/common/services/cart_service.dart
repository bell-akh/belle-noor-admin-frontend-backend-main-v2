import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'auth_service.dart';

class CartService extends ChangeNotifier {
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  List<Map<String, dynamic>> _cartItems = [];
  bool _isLoading = false;
  String _baseUrl = 'http://BelleN-NodeS-htzjq6lxvVlw-908287247.ap-south-1.elb.amazonaws.com/api';

  List<Map<String, dynamic>> get cartItems => _cartItems;
  bool get isLoading => _isLoading;
  int get itemCount => _cartItems.length;
  int get totalQuantity => _cartItems.fold(0, (sum, item) => sum + ((item['quantity'] ?? 0) as int));
  
  double get totalAmount {
    return _cartItems.fold(0.0, (sum, item) {
      final price = (item['product']?['price'] ?? 0).toDouble();
      final quantity = (item['quantity'] ?? 0);
      return sum + (price * quantity);
    });
  }

  // Get cart items from API
  Future<Map<String, dynamic>> getCart() async {
    try {
      _isLoading = true;
      notifyListeners();

      final authService = AuthService();
      if (!authService.isAuthenticated) {
        return {'success': false, 'error': 'User not authenticated'};
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/cart'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authService.authToken}',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _cartItems = List<Map<String, dynamic>>.from(data['data']['cart'] ?? []);
        notifyListeners();
        return {'success': true, 'data': data};
      } else {
        final error = json.decode(response.body);
        return {'success': false, 'error': error['error'] ?? 'Failed to fetch cart'};
      }
    } catch (e) {
      if (kDebugMode) {
        print('Get cart error: $e');
      }
      return {'success': false, 'error': 'Network error: $e'};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add item to cart
  Future<Map<String, dynamic>> addToCart({
    required String productId,
    required int quantity,
    String size = 'M',
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final authService = AuthService();
      if (!authService.isAuthenticated) {
        print('CartService: User not authenticated');
        return {'success': false, 'error': 'User not authenticated'};
      }

      print('CartService: Adding to cart - Product ID: $productId, Quantity: $quantity, Size: $size');
      print('CartService: Auth token: ${authService.authToken}');
      print('CartService: Base URL: $_baseUrl');

      final requestBody = {
        'productId': productId,
        'quantity': quantity,
        'size': size,
      };
      print('CartService: Request body: $requestBody');

      final response = await http.post(
        Uri.parse('$_baseUrl/cart'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authService.authToken}',
        },
        body: json.encode(requestBody),
      );

      print('CartService: Response status: ${response.statusCode}');
      print('CartService: Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        await getCart(); // Refresh cart
        return {'success': true, 'data': data};
      } else {
        final error = json.decode(response.body);
        print('CartService: Error response: $error');
        return {'success': false, 'error': error['error'] ?? 'Failed to add item to cart'};
      }
    } catch (e) {
      print('CartService: Exception caught: $e');
      if (kDebugMode) {
        print('Add to cart error: $e');
      }
      return {'success': false, 'error': 'Network error: $e'};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update cart item
  Future<Map<String, dynamic>> updateCartItem({
    required String itemId,
    int? quantity,
    String? size,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final authService = AuthService();
      if (!authService.isAuthenticated) {
        return {'success': false, 'error': 'User not authenticated'};
      }

      final body = <String, dynamic>{};
      if (quantity != null) body['quantity'] = quantity;
      if (size != null) body['size'] = size;

      final response = await http.put(
        Uri.parse('$_baseUrl/cart/$itemId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authService.authToken}',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await getCart(); // Refresh cart
        return {'success': true, 'data': data};
      } else {
        final error = json.decode(response.body);
        return {'success': false, 'error': error['error'] ?? 'Failed to update cart item'};
      }
    } catch (e) {
      if (kDebugMode) {
        print('Update cart item error: $e');
      }
      return {'success': false, 'error': 'Network error: $e'};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Remove item from cart
  Future<Map<String, dynamic>> removeFromCart(String itemId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final authService = AuthService();
      if (!authService.isAuthenticated) {
        return {'success': false, 'error': 'User not authenticated'};
      }

      final response = await http.delete(
        Uri.parse('$_baseUrl/cart/$itemId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authService.authToken}',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await getCart(); // Refresh cart
        return {'success': true, 'data': data};
      } else {
        final error = json.decode(response.body);
        return {'success': false, 'error': error['error'] ?? 'Failed to remove item from cart'};
      }
    } catch (e) {
      if (kDebugMode) {
        print('Remove from cart error: $e');
      }
      return {'success': false, 'error': 'Network error: $e'};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear cart
  Future<Map<String, dynamic>> clearCart() async {
    try {
      _isLoading = true;
      notifyListeners();

      final authService = AuthService();
      if (!authService.isAuthenticated) {
        return {'success': false, 'error': 'User not authenticated'};
      }

      final response = await http.delete(
        Uri.parse('$_baseUrl/cart'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authService.authToken}',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _cartItems = [];
        notifyListeners();
        return {'success': true, 'data': data};
      } else {
        final error = json.decode(response.body);
        return {'success': false, 'error': error['error'] ?? 'Failed to clear cart'};
      }
    } catch (e) {
      if (kDebugMode) {
        print('Clear cart error: $e');
      }
      return {'success': false, 'error': 'Network error: $e'};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Increase quantity
  Future<Map<String, dynamic>> increaseQuantity(String itemId) async {
    final item = _cartItems.firstWhere(
      (item) => item['id'] == itemId,
      orElse: () => throw Exception('Item not found'),
    );
    
    final currentQuantity = item['quantity'] ?? 0;
    return await updateCartItem(itemId: itemId, quantity: currentQuantity + 1);
  }

  // Decrease quantity
  Future<Map<String, dynamic>> decreaseQuantity(String itemId) async {
    final item = _cartItems.firstWhere(
      (item) => item['id'] == itemId,
      orElse: () => throw Exception('Item not found'),
    );
    
    final currentQuantity = item['quantity'] ?? 0;
    if (currentQuantity <= 1) {
      return await removeFromCart(itemId);
    } else {
      return await updateCartItem(itemId: itemId, quantity: currentQuantity - 1);
    }
  }

  // Check if product is in cart
  bool isInCart(String productId) {
    return _cartItems.any((item) => item['productId'] == productId);
  }

  // Get cart item by product ID
  Map<String, dynamic>? getCartItem(String productId) {
    try {
      return _cartItems.firstWhere((item) => item['productId'] == productId);
    } catch (e) {
      return null;
    }
  }
} 