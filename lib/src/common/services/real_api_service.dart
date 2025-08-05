import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;
import 'package:libas_app/src/common/services/data_change_service.dart';
import 'package:libas_app/src/common/services/cache_service.dart';
import 'package:libas_app/src/common/services/auth_service.dart';

class RealApiService {
  static final RealApiService _instance = RealApiService._internal();
  factory RealApiService() => _instance;
  RealApiService._internal();

  final String _baseUrl = 'http://BelleN-NodeS-htzjq6lxvVlw-908287247.ap-south-1.elb.amazonaws.com/api';
  final String _wsUrl = 'ws://BelleN-NodeS-htzjq6lxvVlw-908287247.ap-south-1.elb.amazonaws.com/ws';
  
  WebSocketChannel? _channel;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  bool _isConnected = false;
  int _reconnectAttempts = 0;
  final int _maxReconnectAttempts = 5;
  
  DataChangeService? _dataChangeService;
  final CacheService _cacheService = CacheService();

  // Initialize with shared DataChangeService
  void initialize(DataChangeService dataChangeService) {
    _dataChangeService = dataChangeService;
      print('🏗️ RealApiService: Initialized with shared DataChangeService instance: ${_dataChangeService.hashCode}');
    if (kDebugMode) {
      print('🏗️ RealApiService: Initialized with shared DataChangeService instance: ${_dataChangeService.hashCode}');
    }
  }

  // Real-time update methods
  Future<void> connectToRealtimeUpdates() async {
    if (_isConnected) return;
    
    try {
      if (kDebugMode) {
        print('🔌 Connecting to WebSocket: $_wsUrl');
      }
      
      _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));
      _channel!.stream.listen(
        _handleWebSocketMessage,
        onError: _handleWebSocketError,
        onDone: _handleWebSocketClosed,
      );
      
      _isConnected = true;
      _reconnectAttempts = 0;
      
      if (kDebugMode) {
        print('📡 Connected to real-time updates via WebSocket');
      }
      
      // Start heartbeat
      _startHeartbeat();
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to connect to WebSocket: $e');
      }
      _scheduleReconnect();
    }
  }

  void _handleWebSocketMessage(dynamic message) {
    try {
      if (kDebugMode) {
        print('📨 Received WebSocket message: $message');
      }
      
      final data = jsonDecode(message.toString());
      _handleRealtimeEvent(data);
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error parsing WebSocket message: $e');
      }
    }
  }

  void _handleRealtimeEvent(Map<String, dynamic> event) {
    if (kDebugMode) {
      print('📡 Received real-time event: ${event['type']}');
    }

    switch (event['type']) {
      case 'connection_established':
        if (kDebugMode) {
          print('📡 Real-time connection established');
        }
        break;
      case 'heartbeat_ack':
        if (kDebugMode) {
          print('💓 Heartbeat acknowledged');
        }
        break;
      case 'dynamodb_change':
        if (kDebugMode) {
          print('🔄 DynamoDB change detected: ${event['table']} - ${event['changeType']}');
          print('📊 Change details: ${event['message']}');
        }
        _invalidateCacheByTable(event['table']);
        _notifyDataChangeByTable(event);
        break;
      case 'data_change':
        if (kDebugMode) {
          print('🔄 Data change detected: ${event['table']} - ${event['changeType']}');
        }
        _invalidateCacheByTable(event['table']);
        _notifyDataChangeByTable(event);
        break;
              case 'product_created':
        case 'product_updated':
        case 'product_deleted':
          if (kDebugMode) {
            print('🔄 Product change detected: ${event['type']}');
          }
          _cacheService.invalidateProducts(); // 🗑️ Invalidate products cache
          _dataChangeService?.notifyProductChange(event);
          break;
        case 'category_created':
        case 'category_updated':
        case 'category_deleted':
          if (kDebugMode) {
            print('🔄 Category change detected: ${event['type']}');
          }
          _cacheService.invalidateCategories(); // 🗑️ Invalidate categories cache
          _dataChangeService?.notifyCategoryChange(event);
          break;
        case 'banner_created':
        case 'banner_updated':
        case 'banner_deleted':
          if (kDebugMode) {
            print('🔄 Banner change detected: ${event['type']}');
          }
          _cacheService.invalidateBanners(); // 🗑️ Invalidate banners cache
          _dataChangeService?.notifyBannerChange(event);
          break;
      default:
        if (kDebugMode) {
          print('📡 Unknown event type: ${event['type']}');
        }
    }
  }

  void _invalidateCacheByTable(String? table) {
    if (table == null) {
      if (kDebugMode) {
        print('❌ Table is null, cannot invalidate cache');
      }
      return;
    }
    
    final tableName = table.toLowerCase();
    if (kDebugMode) {
      print('🗑️ Invalidating cache for table: $tableName');
    }
    
    switch (tableName) {
      case 'shop_products':
      case 'products':
        if (kDebugMode) {
          print('🗑️ Invalidating products cache for table: $tableName');
        }
        _cacheService.invalidateProducts();
        break;
      case 'shop_category':
      case 'categories':
        if (kDebugMode) {
          print('🗑️ Invalidating categories cache for table: $tableName');
        }
        _cacheService.invalidateCategories();
        break;
      case 'shop_banners':
      case 'banners':
        if (kDebugMode) {
          print('🗑️ Invalidating banners cache for table: $tableName');
        }
        _cacheService.invalidateBanners();
        _cacheService.invalidateBannerSections();
        break;
      default:
        if (kDebugMode) {
          print('🗑️ Unknown table for cache invalidation: $tableName');
        }
    }
  }

  void _notifyDataChangeByTable(Map<String, dynamic> event) {
    if (_dataChangeService == null) {
      if (kDebugMode) {
        print('❌ DataChangeService not initialized, cannot notify changes');
      }
      return;
    }
    
    final table = event['table']?.toString().toLowerCase() ?? '';
    final changeType = event['changeType']?.toString().toLowerCase() ?? '';
    
    if (kDebugMode) {
      print('📡 Notifying change for table: $table, changeType: $changeType');
    }
    
    switch (table) {
      case 'shop_products':
      case 'products':
        if (kDebugMode) {
          print('📡 Calling notifyProductChange for table: $table');
        }
        _dataChangeService?.notifyProductChange(event);
        break;
      case 'shop_category':
      case 'categories':
        if (kDebugMode) {
          print('📡 Calling notifyCategoryChange for table: $table');
        }
        _dataChangeService?.notifyCategoryChange(event);
        break;
      case 'shop_banners':
      case 'banners':
        if (kDebugMode) {
          print('📡 Calling notifyBannerChange for table: $table');
        }
        _dataChangeService?.notifyBannerChange(event);
        break;
      case 'shop_orders':
      case 'orders':
        if (kDebugMode) {
          print('📡 Calling notifyOrderChange for table: $table');
        }
        _dataChangeService?.notifyOrderChange(event);
        break;
      case 'shop_likes':
      case 'likes':
        if (kDebugMode) {
          print('📡 Calling notifyLikesChange for table: $table');
        }
        _dataChangeService?.notifyLikesChange(event);
        break;
      default:
        if (kDebugMode) {
          print('📡 Unknown table type: $table, notifying all listeners');
        }
        _dataChangeService?.notifyListeners();
    }
  }

  void _handleWebSocketError(error) {
    if (kDebugMode) {
      print('❌ WebSocket error: $error');
    }
    _isConnected = false;
    _scheduleReconnect();
  }

  void _handleWebSocketClosed() {
    if (kDebugMode) {
      print('📡 WebSocket connection closed');
    }
    _isConnected = false;
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      if (kDebugMode) {
        print('❌ Max reconnection attempts reached');
      }
      return;
    }

    _reconnectAttempts++;
    final delay = Duration(seconds: _reconnectAttempts * 2);
    
    if (kDebugMode) {
      print('📡 Attempting to reconnect to WebSocket...');
    }
    
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      connectToRealtimeUpdates();
    });
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      if (_isConnected && _channel != null) {
        _channel!.sink.add(jsonEncode({
          'type': 'heartbeat',
          'timestamp': DateTime.now().toIso8601String(),
        }));
      }
    });
  }

  void disconnectFromRealtimeUpdates() {
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
    if (kDebugMode) {
      print('📡 Disconnected from real-time updates');
    }
  }



  // API Methods
    Future<Map<String, dynamic>> _getRequest(String endpoint) async {
    try {
      // Get auth token
      final authService = AuthService();
      final token = authService.authToken;

      final headers = {
        'Content-Type': 'application/json',
      };

      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
        if (kDebugMode) {
          print('🔐 Adding auth token to GET request');
        }
      } else {
        if (kDebugMode) {
          print('❌ No auth token available for GET request');
        }
      }

      final url = '$_baseUrl$endpoint';
      if (kDebugMode) {
        print('🌐 RealApiService: Making HTTP GET request to: $url');
        print('🌐 RealApiService: Headers: $headers');
      }

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      if (kDebugMode) {
        print('🌐 RealApiService: HTTP Response Status: ${response.statusCode}');
        print('🌐 RealApiService: HTTP Response Body: ${response.body}');
      }

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 429) {
        if (kDebugMode) {
          print('⚠️ API Rate Limited: ${response.statusCode} - ${response.body}');
          print('⏳ Waiting before retry...');
        }
        // Wait a bit and retry once
        await Future.delayed(Duration(seconds: 2));
        final retryResponse = await http.get(
          Uri.parse('$_baseUrl$endpoint'),
          headers: headers, // Fixed: now includes auth token
        );
        if (retryResponse.statusCode == 200) {
          return jsonDecode(retryResponse.body);
        }
      }
      
      if (kDebugMode) {
        print('❌ API Error: ${response.statusCode} - ${response.body}');
      }
      return {};
    } catch (e) {
      if (kDebugMode) {
        print('❌ Network Error: $e');
      }
      return {};
    }
  }

  Future<Map<String, dynamic>> _postRequest(String endpoint, Map<String, dynamic> body) async {
    try {
      // Get auth token
      final authService = AuthService();
      final token = authService.authToken;
      
      final headers = {
        'Content-Type': 'application/json',
      };
      
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
        if (kDebugMode) {
          print('🔐 Adding auth token to POST request');
        }
      } else {
        if (kDebugMode) {
          print('❌ No auth token available for POST request');
        }
      }

      final response = await http.post(
        Uri.parse('$_baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 429) {
        if (kDebugMode) {
          print('⚠️ API Rate Limited: ${response.statusCode} - ${response.body}');
          print('⏳ Waiting before retry...');
        }
        await Future.delayed(Duration(seconds: 2));
        final retryResponse = await http.post(
          Uri.parse('$_baseUrl$endpoint'),
          headers: headers, // Fixed: now includes headers
          body: jsonEncode(body),
        );
        if (retryResponse.statusCode == 200 || retryResponse.statusCode == 201) {
          return jsonDecode(retryResponse.body);
        }
      }
      
      if (kDebugMode) {
        print('❌ API Error: ${response.statusCode} - ${response.body}');
      }
      return {};
    } catch (e) {
      if (kDebugMode) {
        print('❌ Network Error: $e');
      }
      return {};
    }
  }

  Future<Map<String, dynamic>> _putRequest(String endpoint, Map<String, dynamic> body) async {
    try {
      // Get auth token
      final authService = AuthService();
      final token = authService.authToken;
      
      final headers = {
        'Content-Type': 'application/json',
      };
      
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.put(
        Uri.parse('$_baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 429) {
        if (kDebugMode) {
          print('⚠️ API Rate Limited: ${response.statusCode} - ${response.body}');
          print('⏳ Waiting before retry...');
        }
        await Future.delayed(Duration(seconds: 2));
        final retryResponse = await http.put(
          Uri.parse('$_baseUrl$endpoint'),
          headers: headers, // Fixed: now includes headers
          body: jsonEncode(body),
        );
        if (retryResponse.statusCode == 200) {
          return jsonDecode(retryResponse.body);
        }
      }
      
      if (kDebugMode) {
        print('❌ API Error: ${response.statusCode} - ${response.body}');
      }
      return {};
    } catch (e) {
      if (kDebugMode) {
        print('❌ Network Error: $e');
      }
      return {};
    }
  }

  Future<void> _simulateDelay() async {
    await Future.delayed(Duration(milliseconds: 500));
  }

  Future<void> _deleteRequest(String endpoint) async {
    try {
      // Get auth token
      final authService = AuthService();
      final token = authService.authToken;
      
      final headers = {
        'Content-Type': 'application/json',
      };
      
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
        if (kDebugMode) {
          print('🔐 Adding auth token to DELETE request');
        }
      } else {
        if (kDebugMode) {
          print('❌ No auth token available for DELETE request');
        }
      }

      final url = '$_baseUrl$endpoint';
      if (kDebugMode) {
        print('🌐 RealApiService: Making HTTP DELETE request to: $url');
        print('🌐 RealApiService: Headers: $headers');
      }

      final response = await http.delete(
        Uri.parse(url),
        headers: headers,
      );

      if (kDebugMode) {
        print('🌐 RealApiService: HTTP Response Status: ${response.statusCode}');
        print('🌐 RealApiService: HTTP Response Body: ${response.body}');
      }

      if (response.statusCode == 200 || response.statusCode == 204) {
        return;
      } else if (response.statusCode == 429) {
        if (kDebugMode) {
          print('⚠️ API Rate Limited: ${response.statusCode} - ${response.body}');
          print('⏳ Waiting before retry...');
        }
        await Future.delayed(Duration(seconds: 2));
        final retryResponse = await http.delete(
          Uri.parse('$_baseUrl$endpoint'),
          headers: headers, // Fixed: now includes headers
        );
        if (retryResponse.statusCode == 200 || retryResponse.statusCode == 204) {
          return;
        }
      }
      
      if (kDebugMode) {
        print('❌ API Error: ${response.statusCode} - ${response.body}');
      }
      throw Exception('DELETE request failed: ${response.statusCode}');
    } catch (e) {
      if (kDebugMode) {
        print('❌ Network Error: $e');
      }
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAllProducts({bool forceRefresh = false}) async {
    if (kDebugMode) {
      print('🌐 RealApiService: getAllProducts called (forceRefresh: $forceRefresh)');
    }
    
    // Check cache first (unless force refresh is requested)
    if (!forceRefresh) {
      final cachedProducts = _cacheService.getProducts();
      if (cachedProducts != null) {
        if (kDebugMode) {
          print('📦 RealApiService: Using cached products (${cachedProducts.length} items)');
        }
        return cachedProducts;
      } else {
        if (kDebugMode) {
          print('📦 RealApiService: No cached products found, will fetch from API');
        }
      }
    }

    await _simulateDelay();
    try {
      if (kDebugMode) {
        print('🌐 RealApiService: Fetching all products from API...');
      }
      final response = await _getRequest('/products?limit=50');
      
      // Handle the response structure
      if (response == null || response.isEmpty) {
        if (kDebugMode) {
          print('❌ RealApiService: Response is null or empty for all products');
        }
        return _getMockProducts();
      }
      
      // Check if response is a list directly
      if (response is List) {
        final result = (response as List).map((item) => item as Map<String, dynamic>).toList();
        if (kDebugMode) {
          print('🌐 RealApiService: Fetched ${result.length} products (direct list)');
        }
        final enrichedProducts = await _enrichProductsWithCategoryNames(result);
        _cacheService.setProducts(enrichedProducts);
        return enrichedProducts;
      }
      
      // Handle the actual API response structure: { "products": [...], "total": X }
      final List<dynamic> productsData = response['products'];
      if (productsData == null) {
        if (kDebugMode) {
          print('❌ RealApiService: Products field is null in response');
          print('📊 Response structure: $response');
        }
        return _getMockProducts();
      }
      
      final result = (productsData as List).map((item) => item as Map<String, dynamic>).toList();
      if (kDebugMode) {
        print('🌐 RealApiService: Fetched ${result.length} products');
      }
      final enrichedProducts = await _enrichProductsWithCategoryNames(result);
      _cacheService.setProducts(enrichedProducts);
      return enrichedProducts;
    } catch (e) {
      if (kDebugMode) {
        print('❌ RealApiService: Error fetching all products: $e');
      }
      return _getMockProducts();
    }
  }

  List<Map<String, dynamic>> _getMockProducts() {
    if (kDebugMode) {
      print('🔄 RealApiService: Using mock products data');
    }
    return [
      {
        'id': '1',
        'name': 'iPhone 15 Pro',
        'description': 'Latest iPhone with advanced features',
        'image': 'https://images.unsplash.com/photo-1592750475338-74b7b21085ab?w=300&h=300&fit=crop&crop=center',
        'images': ['https://images.unsplash.com/photo-1592750475338-74b7b21085ab?w=300&h=300&fit=crop&crop=center'],
        'new_price': 999.99,
        'old_price': 1099.99,
        'categoryId': '1',
        'category': 'Electronics',
        'type': 'smartphone',
        'quantity': 50,
        'rating': 4.5,
        'reviews': 120,
        'isActive': true,
      },
      {
        'id': '2',
        'name': 'Samsung Galaxy S24',
        'description': 'Premium Android smartphone',
        'image': 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=300&h=300&fit=crop&crop=center',
        'images': ['https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=300&h=300&fit=crop&crop=center'],
        'new_price': 899.99,
        'old_price': 999.99,
        'categoryId': '1',
        'category': 'Electronics',
        'type': 'smartphone',
        'quantity': 30,
        'rating': 4.3,
        'reviews': 85,
        'isActive': true,
      },
      {
        'id': '3',
        'name': 'Nike Air Max',
        'description': 'Comfortable running shoes',
        'image': 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=300&h=300&fit=crop&crop=center',
        'images': ['https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=300&h=300&fit=crop&crop=center'],
        'new_price': 129.99,
        'old_price': 159.99,
        'categoryId': '2',
        'category': 'Fashion',
        'type': 'shoes',
        'quantity': 100,
        'rating': 4.7,
        'reviews': 200,
        'isActive': true,
      },
    ];
  }

  Future<List<Map<String, dynamic>>> getProductsByCategory(String categoryId) async {
    await _simulateDelay();
    try {
      if (kDebugMode) {
        print('🌐 RealApiService: Fetching products for category: $categoryId');
        print('🌐 RealApiService: Making request to: /products/category/$categoryId?limit=50');
      }
      final response = await _getRequest('/products/category/$categoryId?limit=50');
      
      // Handle null response
      if (response == null || response.isEmpty) {
        if (kDebugMode) {
          print('❌ RealApiService: Response is null or empty for category: $categoryId');
        }
        return [];
      }
      
      // Check if response is a list directly
      if (response is List) {
        final result = (response as List).map((item) => item as Map<String, dynamic>).toList();
        if (kDebugMode) {
          print('🌐 RealApiService: Fetched ${result.length} products for category: $categoryId (direct list)');
        }
        return result;
      }
      
      // Handle the nested data structure
      final data = response['data'];
      if (data == null) {
        if (kDebugMode) {
          print('❌ RealApiService: Data field is null for category: $categoryId');
          print('📊 Response: $response');
        }
        return [];
      }
      
      // Handle null products field
      final productsData = data['products'] ?? data;
      if (productsData == null) {
        if (kDebugMode) {
          print('❌ RealApiService: Products field is null for category: $categoryId');
          print('📊 Data: $data');
        }
        return [];
      }
      
      // Ensure it's a list
      if (productsData is! List) {
        if (kDebugMode) {
          print('❌ RealApiService: Products is not a list for category: $categoryId');
          print('📊 Products data type: ${productsData.runtimeType}');
          print('📊 Products data: $productsData');
        }
        return [];
      }
      
      final result = (productsData as List).map((item) => item as Map<String, dynamic>).toList();
      if (kDebugMode) {
        print('🌐 RealApiService: Fetched ${result.length} products for category: $categoryId');
      }
      return await _enrichProductsWithCategoryNames(result);
    } catch (e) {
      if (kDebugMode) {
        print('❌ RealApiService: Error fetching products by category: $e');
      }
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getCategories({bool forceRefresh = false}) async {
    if (kDebugMode) {
      print('🌐 RealApiService: getCategories called (forceRefresh: $forceRefresh)');
    }
    
    // Check cache first (unless force refresh is requested)
    if (!forceRefresh) {
      final cachedCategories = _cacheService.getCategories();
      if (cachedCategories != null) {
        if (kDebugMode) {
          print('📦 RealApiService: Using cached categories (${cachedCategories.length} items)');
        }
        return cachedCategories;
      }
    }

    if (kDebugMode) {
      print('🌐 RealApiService: Cache miss or force refresh, fetching from API...');
    }
    
    await _simulateDelay();
    try {
      if (kDebugMode) {
        print('🌐 RealApiService: Fetching categories from API...');
      }
      final response = await _getRequest('/categories?limit=50');
      
      // Handle null response
      if (response == null || response.isEmpty) {
        if (kDebugMode) {
          print('❌ RealApiService: Response is null or empty for categories');
        }
        return _getMockCategories();
      }
      
      // Check if response is a list directly
      if (response is List) {
        final result = (response as List).map((item) => item as Map<String, dynamic>).toList();
        if (kDebugMode) {
          print('🌐 RealApiService: Fetched ${result.length} categories (direct list)');
        }
        _cacheService.setCategories(result);
        return result;
      }
      
      // Handle the actual API response structure: { "categories": [...], "total": 3 }
      final List<dynamic> categoriesData = response['categories'];
      if (categoriesData == null) {
        if (kDebugMode) {
          print('❌ RealApiService: Categories field is null in response');
          print('📊 Response structure: $response');
        }
        return _getMockCategories();
      }
      
      final result = (categoriesData as List).map((item) => item as Map<String, dynamic>).toList();
      if (kDebugMode) {
        print('🌐 RealApiService: Fetched ${result.length} categories');
        print('📊 First category: ${result.isNotEmpty ? result.first : 'empty'}');
      }
      _cacheService.setCategories(result);
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('❌ RealApiService: Error fetching categories: $e');
      }
      return _getMockCategories();
    }
  }

  List<Map<String, dynamic>> _getMockCategories() {
    if (kDebugMode) {
      print('🔄 RealApiService: Using mock categories data');
    }
    return [
      {
        'id': '1',
        'name': 'Electronics',
        'description': 'Electronic devices and gadgets',
        'image': ['https://images.unsplash.com/photo-1498049794561-7780e7231661?w=300&h=300&fit=crop&crop=center'],
        'isActive': true,
        'priority': 1,
      },
      {
        'id': '2',
        'name': 'Fashion',
        'description': 'Clothing and accessories',
        'image': ['https://images.unsplash.com/photo-1445205170230-053b83016050?w=300&h=300&fit=crop&crop=center'],
        'isActive': true,
        'priority': 2,
      },
      {
        'id': '3',
        'name': 'Home & Garden',
        'description': 'Home decor and garden items',
        'image': ['https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=300&h=300&fit=crop&crop=center'],
        'isActive': true,
        'priority': 3,
      },
    ];
  }

  Future<List<Map<String, dynamic>>> getBanners({bool forceRefresh = false}) async {
    if (kDebugMode) {
      print('🌐 RealApiService: getBanners called (forceRefresh: $forceRefresh)');
    }
    
    // Check cache first (unless force refresh is requested)
    if (!forceRefresh) {
      final cachedBanners = _cacheService.getBanners();
      if (cachedBanners != null) {
        if (kDebugMode) {
          print('📦 RealApiService: Using cached banners (${cachedBanners.length} items)');
        }
        return cachedBanners;
      }
    }

    await _simulateDelay();
    try {
      if (kDebugMode) {
        print('🌐 RealApiService: Fetching banners from API...');
      }
      final response = await _getRequest('/banners?limit=50');
      
      // Handle null response
      if (response == null || response.isEmpty) {
        if (kDebugMode) {
          print('❌ RealApiService: Response is null or empty for banners');
        }
        return _getMockBanners();
      }
      
      // Check if response is a list directly
      if (response is List) {
        final result = (response as List).map((item) => item as Map<String, dynamic>).toList();
        if (kDebugMode) {
          print('🌐 RealApiService: Fetched ${result.length} banners (direct list)');
        }
        _cacheService.setBanners(result);
        return result;
      }
      
      // Handle the actual API response structure: { "banners": [...], "total": 3 }
      final List<dynamic> bannersData = response['banners'];
      if (bannersData == null) {
        if (kDebugMode) {
          print('❌ RealApiService: Banners field is null in response');
          print('📊 Response structure: $response');
        }
        return _getMockBanners();
      }
      
      final result = (bannersData as List).map((item) => item as Map<String, dynamic>).toList();
      if (kDebugMode) {
        print('🌐 RealApiService: Fetched ${result.length} banners');
        print('📊 First banner: ${result.isNotEmpty ? result.first : 'empty'}');
      }
      _cacheService.setBanners(result);
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('❌ RealApiService: Error fetching banners: $e');
      }
      return _getMockBanners();
    }
  }

  List<Map<String, dynamic>> _getMockBanners() {
    if (kDebugMode) {
      print('🔄 RealApiService: Using mock banners data');
    }
    return [
      {
        'id': '1',
        'title': 'New Arrival',
        'subtitle': 'Check out the latest products',
        'image': 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=800&h=400&fit=crop&crop=center',
        'link': '/new-arrivals',
        'isActive': true,
        'priority': 1,
      },
      {
        'id': '2',
        'title': 'Summer Sale',
        'subtitle': 'Get up to 50% off on summer collection',
        'image': 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=800&h=400&fit=crop&crop=center',
        'link': '/sale',
        'isActive': true,
        'priority': 2,
      },
      {
        'id': '3',
        'title': 'Electronics Deals',
        'subtitle': 'Best deals on electronics',
        'image': 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=800&h=400&fit=crop&crop=center',
        'link': '/electronics',
        'isActive': true,
        'priority': 3,
      },
    ];
  }

  Future<List<Map<String, dynamic>>> getSmallBanners({bool forceRefresh = false}) async {
    // Check cache first (unless force refresh is requested)
    if (!forceRefresh) {
      final cachedSmallBanners = _cacheService.getSmallBanners();
      if (cachedSmallBanners != null) {
        if (kDebugMode) {
          print('📦 RealApiService: Using cached small banners (${cachedSmallBanners.length} items)');
        }
        return cachedSmallBanners;
      }
    }

    await _simulateDelay();
    try {
      if (kDebugMode) {
        print('🌐 RealApiService: Fetching small banners from API...');
      }
      // Use the same endpoint as regular banners but with a filter
      final response = await _getRequest('/banners?limit=50');
      
      // Handle null response
      if (response == null || response.isEmpty) {
        if (kDebugMode) {
          print('❌ RealApiService: Response is null or empty for small banners');
        }
        return [];
      }
      
      // Check if response is a list directly
      if (response is List) {
        final result = (response as List).map((item) => item as Map<String, dynamic>).toList();
        if (kDebugMode) {
          print('🌐 RealApiService: Fetched ${result.length} small banners (direct list)');
        }
        _cacheService.setSmallBanners(result);
        return result;
      }
      
      // Handle the actual API response structure: { "banners": [...], "total": 3 }
      final List<dynamic> bannersData = response['banners'];
      if (bannersData == null) {
        if (kDebugMode) {
          print('❌ RealApiService: Small banners field is null in response');
          print('📊 Response structure: $response');
        }
        return [];
      }
      
      final result = (bannersData as List).map((item) => item as Map<String, dynamic>).toList();
      if (kDebugMode) {
        print('🌐 RealApiService: Fetched ${result.length} small banners');
      }
      _cacheService.setSmallBanners(result);
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('❌ RealApiService: Error fetching small banners: $e');
      }
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    await _simulateDelay();
    try {
      if (kDebugMode) {
        print('🌐 RealApiService: Searching products with query: $query');
      }
      final response = await _getRequest('/products?search=$query&limit=50');
      
      final data = response['data'];
      if (data == null) {
        if (kDebugMode) {
          print('❌ RealApiService: Data field is null for search');
        }
        return [];
      }
      
      final List<dynamic> productsData = data['products'];
      final result = (productsData as List).map((item) => item as Map<String, dynamic>).toList();
      if (kDebugMode) {
        print('🌐 RealApiService: Found ${result.length} products for query: $query');
      }
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('❌ RealApiService: Error searching products: $e');
      }
      return [];
    }
  }

  // Enrich products with category names
  Future<List<Map<String, dynamic>>> _enrichProductsWithCategoryNames(List<Map<String, dynamic>> products) async {
    try {
      // Get categories to create a mapping
      final categories = await getCategories();
      final categoryMap = <String, String>{};
      
      for (final category in categories) {
        categoryMap[category['id'].toString()] = category['name'] ?? 'Unknown Category';
      }
      
      // Enrich each product with category name
      for (final product in products) {
        final categoryId = product['category']?.toString();
        if (categoryId != null && categoryMap.containsKey(categoryId)) {
          product['category'] = categoryMap[categoryId];
        } else {
          product['category'] = 'Unknown Category';
        }
      }
      
      if (kDebugMode) {
        print('🔄 RealApiService: Enriched ${products.length} products with category names');
      }
      
      return products;
    } catch (e) {
      if (kDebugMode) {
        print('❌ RealApiService: Error enriching products with category names: $e');
      }
      return products;
    }
  }

  // ==================== ORDERS ====================

  // Create new order
  Future<Map<String, dynamic>> createOrder({
    required List<Map<String, dynamic>> products,
    required Map<String, dynamic> shippingAddress,
    required String paymentMethod,
    double discount = 0,
    String? couponCode,
  }) async {
    try {
      if (kDebugMode) {
        print('🌐 RealApiService: Creating order with ${products.length} products');
      }

      final response = await _postRequest('/orders', {
        'products': products,
        'shippingAddress': shippingAddress,
        'paymentMethod': paymentMethod,
        'discount': discount,
        if (couponCode != null) 'couponCode': couponCode,
      });

      if (kDebugMode) {
        print('📊 RealApiService: Order creation response: $response');
      }

      // Check if response is empty (indicating an error)
      if (response.isEmpty) {
        return {
          'success': false,
          'message': 'Failed to create order - server error',
        };
      }

      // Check if response has success field
      if (response.containsKey('success') && response['success'] == false) {
        return {
          'success': false,
          'message': response['error'] ?? 'Failed to create order',
        };
      }

      if (kDebugMode) {
        print('✅ RealApiService: Order created successfully');
      }

      return {
        'success': true,
        'message': response['message'] ?? 'Order created successfully',
        'data': response['data'],
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ RealApiService: Error creating order: $e');
      }
      return {
        'success': false,
        'message': 'Error creating order: ${e.toString()}',
      };
    }
  }

  // Get user's orders
  Future<List<Map<String, dynamic>>> getUserOrders({String? status, bool forceRefresh = false}) async {
    try {
      if (kDebugMode) {
        print('🌐 RealApiService: Fetching user orders${status != null ? ' with status: $status' : ''}${forceRefresh ? ' (force refresh)' : ''}');
      }

      String endpoint = '/orders';
      if (status != null) {
        endpoint += '?status=$status';
      }
      
      // Add timestamp to force fresh data
      if (forceRefresh) {
        endpoint += '${endpoint.contains('?') ? '&' : '?'}forceRefresh=true&t=${DateTime.now().millisecondsSinceEpoch}';
      }

      if (kDebugMode) {
        print('🌐 RealApiService: Making GET request to endpoint: $endpoint');
      }

      final response = await _getRequest(endpoint);
      
      if (kDebugMode) {
        print('🌐 RealApiService: Raw API response: $response');
      }
      
      final data = response['data'];
      if (data == null) {
        if (kDebugMode) {
          print('❌ RealApiService: Data field is null for orders');
        }
        return [];
      }

      final List<dynamic> ordersData = data['orders'] ?? data;
      final result = (ordersData as List).map((item) => item as Map<String, dynamic>).toList();
      
      if (kDebugMode) {
        print('🌐 RealApiService: Fetched ${result.length} orders');
      }
      
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('❌ RealApiService: Error fetching user orders: $e');
      }
      return [];
    }
  }

  // Get order by ID
  Future<Map<String, dynamic>?> getOrderById(String orderId) async {
    try {
      if (kDebugMode) {
        print('🌐 RealApiService: Fetching order with ID: $orderId');
      }

      final response = await _getRequest('/orders/$orderId');
      
      final data = response['data'];
      if (data == null) {
        if (kDebugMode) {
          print('❌ RealApiService: Data field is null for order');
        }
        return null;
      }

      if (kDebugMode) {
        print('✅ RealApiService: Fetched order successfully');
      }
      
      return data as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) {
        print('❌ RealApiService: Error fetching order: $e');
      }
      return null;
    }
  }

  // Cancel order
  Future<Map<String, dynamic>> cancelOrder(String orderId) async {
    try {
      if (kDebugMode) {
        print('🌐 RealApiService: Cancelling order with ID: $orderId');
      }

      final response = await _putRequest('/orders/$orderId/cancel', {});

      if (kDebugMode) {
        print('✅ RealApiService: Order cancelled successfully');
      }

      return {
        'success': true,
        'message': response['message'] ?? 'Order cancelled successfully',
        'data': response['data'],
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ RealApiService: Error cancelling order: $e');
      }
      return {
        'success': false,
        'message': 'Error cancelling order: ${e.toString()}',
      };
    }
  }

  // Request refund
  Future<Map<String, dynamic>> requestRefund(String orderId, {String? reason}) async {
    try {
      if (kDebugMode) {
        print('🌐 RealApiService: Requesting refund for order with ID: $orderId');
      }

      final response = await _putRequest('/orders/$orderId/refund', {
        'reason': reason,
      });

      if (kDebugMode) {
        print('✅ RealApiService: Refund requested successfully');
      }

      return {
        'success': true,
        'message': response['message'] ?? 'Refund requested successfully',
        'data': response['data'],
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ RealApiService: Error requesting refund: $e');
      }
      return {
        'success': false,
        'message': 'Error requesting refund: ${e.toString()}',
      };
    }
  }

  // ==================== LIKES METHODS ====================

  // Toggle like for a video
  Future<Map<String, dynamic>> toggleLike({
    required String videoId,
    required bool isLiked,
    String? comments,
  }) async {
    try {
      if (kDebugMode) {
        print('❤️ RealApiService: Toggle like for videoId: $videoId, isLiked: $isLiked');
      }

      final response = await _postRequest('/likes/toggle', {
        'videoId': videoId,
        'isLiked': isLiked,
        if (comments != null) 'comments': comments,
      });

      if (kDebugMode) {
        print('❤️ RealApiService: Like toggled successfully');
      }

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('❌ RealApiService: Error toggling like: $e');
      }
      rethrow;
    }
  }

  // Get user's like status for a specific video
  Future<Map<String, dynamic>> getUserLikeStatus(String videoId) async {
    try {
      if (kDebugMode) {
        print('❤️ RealApiService: Get user like status for videoId: $videoId');
      }

      final response = await _getRequest('/likes/user/video/$videoId');
      
      if (kDebugMode) {
        print('❤️ RealApiService: User like status: ${response['data']}');
      }

      return response['data'];
    } catch (e) {
      if (kDebugMode) {
        print('❌ RealApiService: Error getting user like status: $e');
      }
      rethrow;
    }
  }

  // Get likes for a specific video
  Future<Map<String, dynamic>> getVideoLikes(String videoId, {int limit = 50, int offset = 0}) async {
    try {
      if (kDebugMode) {
        print('❤️ RealApiService: Get video likes for videoId: $videoId');
      }

      String endpoint = '/likes/video/$videoId?limit=$limit&offset=$offset';
      final response = await _getRequest(endpoint);
      
      if (kDebugMode) {
        print('❤️ RealApiService: Video likes: ${response['data']}');
      }

      return response['data'];
    } catch (e) {
      if (kDebugMode) {
        print('❌ RealApiService: Error getting video likes: $e');
      }
      rethrow;
    }
  }

  // Get all videos
  Future<List<Map<String, dynamic>>> getVideos() async {
    try {
      if (kDebugMode) {
        print('🎬 RealApiService: Getting all videos');
      }

      final response = await _getRequest('/videos');
      
      if (kDebugMode) {
        print('🎬 RealApiService: Videos response: ${response['data']}');
      }

      final List<dynamic> videosData = response['data'] ?? [];
      return videosData.cast<Map<String, dynamic>>();
    } catch (e) {
      if (kDebugMode) {
        print('❌ RealApiService: Error getting videos: $e');
      }
      return [];
    }
  }

  // Update comment for a like
  Future<Map<String, dynamic>> updateComment(String likeId, String comments) async {
    try {
      if (kDebugMode) {
        print('💬 RealApiService: Update comment for likeId: $likeId');
      }

      final response = await _putRequest('/likes/$likeId/comment', {
        'comments': comments,
      });

      if (kDebugMode) {
        print('💬 RealApiService: Comment updated successfully');
      }

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('❌ RealApiService: Error updating comment: $e');
      }
      rethrow;
    }
  }

  // Delete a like
  Future<void> deleteLike(String likeId) async {
    try {
      if (kDebugMode) {
        print('🗑️ RealApiService: Delete like with likeId: $likeId');
      }

      await _deleteRequest('/likes/$likeId');

      if (kDebugMode) {
        print('🗑️ RealApiService: Like deleted successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ RealApiService: Error deleting like: $e');
      }
      rethrow;
    }
  }

  // Get banner sections from API
  Future<Map<String, dynamic>> getBannerSections({bool forceRefresh = false}) async {
    try {
      if (kDebugMode) {
        print('🌐 RealApiService: getBannerSections called (forceRefresh: $forceRefresh)');
      }

      // Check cache first
      if (!forceRefresh) {
        final cachedData = _cacheService.getBannerSections();
        if (cachedData != null) {
          print('🌐 cache hit');
          return cachedData;
        }
      }

      if (kDebugMode) {
        print('🌐 RealApiService: Cache miss or force refresh, fetching from API...');
      }

      // Make API call
      final response = await _getRequest('/banners/sections');
      print('🌐 #######################API call made######################');
      if (response['success'] == true) {
        final data = response['data'];
        
        // Cache the result
        _cacheService.setBannerSections(data);
        
        if (kDebugMode) {
          print('📊 RealApiService: Fetched ${data['sections']?.length ?? 0} banner sections');
        }
        
        return data;
      } else {
        throw Exception('Failed to fetch banner sections: ${response['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ RealApiService: Error fetching banner sections: $e');
      }
      rethrow;
    }
  }

  // Getters
  bool get isConnected => _isConnected;
  DataChangeService? get dataChangeService => _dataChangeService;
} 