import 'dart:async';
import 'dart:math';
import 'package:libas_app/src/common/services/data_change_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Mutable data storage for real-time updates
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _banners = [];
  List<Map<String, dynamic>> _smallBanners = [];
  
  bool _isInitialized = false;

  // Simulate network delay
  Future<void> _simulateDelay() async {
    await Future.delayed(Duration(milliseconds: 500 + Random().nextInt(1000)));
  }

  // Initialize data if not already done
  Future<void> _initializeData() async {
    if (_isInitialized) return;
    
    _banners = [
      {
        'id': '1',
        'title': 'New Collection',
        'subtitle': 'Up to 50% off on selected items',
        'image': 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=400&h=200&fit=crop&crop=center',
        'actionText': 'Shop Now',
        'actionType': 'category',
        'actionData': 'dresses',
        'gradientColors': ['#6f016b', '#8a1f85'],
      },
      {
        'id': '2',
        'title': 'Summer Sale',
        'subtitle': 'Fresh styles for the season',
        'image': 'https://images.unsplash.com/photo-1469334031218-e382a71b716b?w=400&h=200&fit=crop&crop=center',
        'actionText': 'Explore',
        'actionType': 'category',
        'actionData': 'summer',
        'gradientColors': ['#ff6b6b', '#ff8e8e'],
      },
      {
        'id': '3',
        'title': 'Premium Collection',
        'subtitle': 'Luxury fashion at affordable prices',
        'image': 'https://images.unsplash.com/photo-1445205170230-053b83016050?w=400&h=200&fit=crop&crop=center',
        'actionText': 'Discover',
        'actionType': 'category',
        'actionData': 'premium',
        'gradientColors': ['#2c3e50', '#34495e'],
      },
    ];

    _smallBanners = [
      {
        'id': '1',
        'title': 'Free Shipping',
        'subtitle': 'On orders above \$50',
        'image': 'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=150&h=100&fit=crop&crop=center',
        'gradientColors': ['#ffa726', '#ff9800'],
      },
      {
        'id': '2',
        'title': 'Easy Returns',
        'subtitle': '30-day return policy',
        'image': 'https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?w=150&h=100&fit=crop&crop=center',
        'gradientColors': ['#66bb6a', '#4caf50'],
      },
      {
        'id': '3',
        'title': 'Secure Payment',
        'subtitle': '100% secure checkout',
        'image': 'https://images.unsplash.com/photo-1563013544-824ae1b704d3?w=150&h=100&fit=crop&crop=center',
        'gradientColors': ['#42a5f5', '#2196f3'],
      },
    ];

    _categories = [
      {
        'id': '1',
        'name': 'Dresses',
        'image': 'https://images.unsplash.com/photo-1515372039744-b8f02a3ae446?w=200&h=200&fit=crop&crop=center',
        'productCount': 45,
        'description': 'Elegant dresses for every occasion',
      },
      {
        'id': '2',
        'name': 'Tops',
        'image': 'https://images.unsplash.com/photo-1434389677669-e08b4cac3105?w=200&h=200&fit=crop&crop=center',
        'productCount': 32,
        'description': 'Stylish tops and blouses',
      },
      {
        'id': '3',
        'name': 'Bottoms',
        'image': 'https://images.unsplash.com/photo-1542272604-787c3835535d?w=200&h=200&fit=crop&crop=center',
        'productCount': 28,
        'description': 'Comfortable pants and skirts',
      },
      {
        'id': '4',
        'name': 'Outerwear',
        'image': 'https://images.unsplash.com/photo-1551489186-cf8726f514f8?w=200&h=200&fit=crop&crop=center',
        'productCount': 18,
        'description': 'Coats, jackets, and cardigans',
      },
      {
        'id': '5',
        'name': 'Accessories',
        'image': 'https://images.unsplash.com/photo-1523170335258-f5ed11844a49?w=200&h=200&fit=crop&crop=center',
        'productCount': 56,
        'description': 'Jewelry, bags, and more',
      },
    ];

    _products = [
      {
        'id': '1',
        'name': 'Elegant Evening Dress',
        'price': 89.99,
        'originalPrice': 120.00,
        'image': 'https://images.unsplash.com/photo-1515372039744-b8f02a3ae446?w=300&h=400&fit=crop&crop=center',
        'rating': 4.5,
        'reviews': 128,
        'category': 'Dresses',
        'categoryId': '1',
        'description': 'A stunning evening dress perfect for special occasions',
        'sizes': ['XS', 'S', 'M', 'L', 'XL'],
        'colors': ['Black', 'Navy', 'Red'],
        'inStock': true,
        'discount': 25,
      },
      {
        'id': '2',
        'name': 'Casual Summer Top',
        'price': 45.99,
        'originalPrice': 65.00,
        'image': 'https://images.unsplash.com/photo-1434389677669-e08b4cac3105?w=300&h=400&fit=crop&crop=center',
        'rating': 4.2,
        'reviews': 95,
        'category': 'Tops',
        'categoryId': '2',
        'description': 'Comfortable and stylish summer top',
        'sizes': ['S', 'M', 'L'],
        'colors': ['White', 'Blue', 'Pink'],
        'inStock': true,
        'discount': 29,
      },
      {
        'id': '3',
        'name': 'Summer Floral Dress',
        'price': 67.99,
        'originalPrice': 89.00,
        'image': 'https://images.unsplash.com/photo-1542272604-787c3835535d?w=300&h=400&fit=crop&crop=center',
        'rating': 4.7,
        'reviews': 156,
        'category': 'Dresses',
        'categoryId': '1',
        'description': 'Beautiful floral print dress for summer',
        'sizes': ['XS', 'S', 'M', 'L'],
        'colors': ['Floral', 'Blue Floral'],
        'inStock': true,
        'discount': 24,
      },
      {
        'id': '4',
        'name': 'Luxury Evening Gown',
        'price': 129.99,
        'originalPrice': 180.00,
        'image': 'https://images.unsplash.com/photo-1551489186-cf8726f514f8?w=300&h=400&fit=crop&crop=center',
        'rating': 4.8,
        'reviews': 203,
        'category': 'Dresses',
        'categoryId': '1',
        'description': 'Exquisite evening gown for formal events',
        'sizes': ['S', 'M', 'L', 'XL'],
        'colors': ['Black', 'Red', 'Gold'],
        'inStock': true,
        'discount': 28,
      },
      {
        'id': '5',
        'name': 'Party Dress',
        'price': 78.99,
        'originalPrice': 110.00,
        'image': 'https://images.unsplash.com/photo-1523170335258-f5ed11844a49?w=300&h=400&fit=crop&crop=center',
        'rating': 4.3,
        'reviews': 87,
        'category': 'Dresses',
        'categoryId': '1',
        'description': 'Perfect dress for parties and celebrations',
        'sizes': ['XS', 'S', 'M', 'L'],
        'colors': ['Silver', 'Black', 'Blue'],
        'inStock': true,
        'discount': 28,
      },
      {
        'id': '6',
        'name': 'Formal Business Dress',
        'price': 95.99,
        'originalPrice': 130.00,
        'image': 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=300&h=400&fit=crop&crop=center',
        'rating': 4.6,
        'reviews': 134,
        'category': 'Dresses',
        'categoryId': '1',
        'description': 'Professional dress for business meetings',
        'sizes': ['S', 'M', 'L'],
        'colors': ['Navy', 'Black', 'Grey'],
        'inStock': true,
        'discount': 26,
      },
      {
        'id': '7',
        'name': 'Casual Blouse',
        'price': 35.99,
        'originalPrice': 50.00,
        'image': 'https://images.unsplash.com/photo-1434389677669-e08b4cac3105?w=300&h=400&fit=crop&crop=center',
        'rating': 4.1,
        'reviews': 78,
        'category': 'Tops',
        'categoryId': '2',
        'description': 'Comfortable casual blouse for everyday wear',
        'sizes': ['XS', 'S', 'M', 'L', 'XL'],
        'colors': ['White', 'Light Blue', 'Pink'],
        'inStock': true,
        'discount': 28,
      },
      {
        'id': '8',
        'name': 'High-Waisted Jeans',
        'price': 65.99,
        'originalPrice': 85.00,
        'image': 'https://images.unsplash.com/photo-1542272604-787c3835535d?w=300&h=400&fit=crop&crop=center',
        'rating': 4.4,
        'reviews': 112,
        'category': 'Bottoms',
        'categoryId': '3',
        'description': 'Stylish high-waisted jeans with perfect fit',
        'sizes': ['26', '28', '30', '32', '34'],
        'colors': ['Blue', 'Black', 'Light Blue'],
        'inStock': true,
        'discount': 22,
      },
      {
        'id': '9',
        'name': 'Winter Coat',
        'price': 89.99,
        'originalPrice': 120.00,
        'image': 'https://images.unsplash.com/photo-1551489186-cf8726f514f8?w=300&h=400&fit=crop&crop=center',
        'rating': 4.7,
        'reviews': 145,
        'category': 'Outerwear',
        'categoryId': '4',
        'description': 'Warm and stylish winter coat',
        'sizes': ['S', 'M', 'L', 'XL'],
        'colors': ['Black', 'Grey', 'Navy'],
        'inStock': true,
        'discount': 25,
      },
      {
        'id': '10',
        'name': 'Statement Necklace',
        'price': 25.99,
        'originalPrice': 35.00,
        'image': 'https://images.unsplash.com/photo-1523170335258-f5ed11844a49?w=300&h=400&fit=crop&crop=center',
        'rating': 4.2,
        'reviews': 67,
        'category': 'Accessories',
        'categoryId': '5',
        'description': 'Beautiful statement necklace to complete any look',
        'sizes': ['One Size'],
        'colors': ['Gold', 'Silver', 'Rose Gold'],
        'inStock': true,
        'discount': 26,
      },
    ];
    
    _isInitialized = true;
  }

  // Mock banner data
  Future<List<Map<String, dynamic>>> getBanners() async {
    await _simulateDelay();
    await _initializeData();
    return List.from(_banners);
  }

  // Mock small banner data
  Future<List<Map<String, dynamic>>> getSmallBanners() async {
    await _simulateDelay();
    await _initializeData();
    return List.from(_smallBanners);
  }

  // Mock categories data
  Future<List<Map<String, dynamic>>> getCategories() async {
    await _simulateDelay();
    await _initializeData();
    return List.from(_categories);
  }

  // Mock products data
  Future<List<Map<String, dynamic>>> getAllProducts() async {
    await _simulateDelay();
    
    return [
      {
        'id': '1',
        'name': 'Elegant Evening Dress',
        'price': 89.99,
        'originalPrice': 120.00,
        'image': 'https://images.unsplash.com/photo-1515372039744-b8f02a3ae446?w=300&h=400&fit=crop&crop=center',
        'rating': 4.5,
        'reviews': 128,
        'category': 'Dresses',
        'categoryId': '1',
        'description': 'A stunning evening dress perfect for special occasions',
        'sizes': ['XS', 'S', 'M', 'L', 'XL'],
        'colors': ['Black', 'Navy', 'Red'],
        'inStock': true,
        'discount': 25,
      },
      {
        'id': '2',
        'name': 'Casual Summer Top',
        'price': 45.99,
        'originalPrice': 65.00,
        'image': 'https://images.unsplash.com/photo-1434389677669-e08b4cac3105?w=300&h=400&fit=crop&crop=center',
        'rating': 4.2,
        'reviews': 95,
        'category': 'Tops',
        'categoryId': '2',
        'description': 'Comfortable and stylish summer top',
        'sizes': ['S', 'M', 'L'],
        'colors': ['White', 'Blue', 'Pink'],
        'inStock': true,
        'discount': 29,
      },
      {
        'id': '3',
        'name': 'Summer Floral Dress',
        'price': 67.99,
        'originalPrice': 89.00,
        'image': 'https://images.unsplash.com/photo-1542272604-787c3835535d?w=300&h=400&fit=crop&crop=center',
        'rating': 4.7,
        'reviews': 156,
        'category': 'Dresses',
        'categoryId': '1',
        'description': 'Beautiful floral print dress for summer',
        'sizes': ['XS', 'S', 'M', 'L'],
        'colors': ['Floral', 'Blue Floral'],
        'inStock': true,
        'discount': 24,
      },
      {
        'id': '4',
        'name': 'Luxury Evening Gown',
        'price': 129.99,
        'originalPrice': 180.00,
        'image': 'https://images.unsplash.com/photo-1551489186-cf8726f514f8?w=300&h=400&fit=crop&crop=center',
        'rating': 4.8,
        'reviews': 203,
        'category': 'Dresses',
        'categoryId': '1',
        'description': 'Exquisite evening gown for formal events',
        'sizes': ['S', 'M', 'L', 'XL'],
        'colors': ['Black', 'Red', 'Gold'],
        'inStock': true,
        'discount': 28,
      },
      {
        'id': '5',
        'name': 'Party Dress',
        'price': 78.99,
        'originalPrice': 110.00,
        'image': 'https://images.unsplash.com/photo-1523170335258-f5ed11844a49?w=300&h=400&fit=crop&crop=center',
        'rating': 4.3,
        'reviews': 87,
        'category': 'Dresses',
        'categoryId': '1',
        'description': 'Perfect dress for parties and celebrations',
        'sizes': ['XS', 'S', 'M', 'L'],
        'colors': ['Silver', 'Black', 'Blue'],
        'inStock': true,
        'discount': 28,
      },
      {
        'id': '6',
        'name': 'Formal Business Dress',
        'price': 95.99,
        'originalPrice': 130.00,
        'image': 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=300&h=400&fit=crop&crop=center',
        'rating': 4.6,
        'reviews': 134,
        'category': 'Dresses',
        'categoryId': '1',
        'description': 'Professional dress for business meetings',
        'sizes': ['S', 'M', 'L', 'XL'],
        'colors': ['Navy', 'Black', 'Grey'],
        'inStock': true,
        'discount': 26,
      },
      {
        'id': '7',
        'name': 'Casual Blouse',
        'price': 35.99,
        'originalPrice': 50.00,
        'image': 'https://images.unsplash.com/photo-1564257631407-3deb25e91d1b?w=300&h=400&fit=crop&crop=center',
        'rating': 4.1,
        'reviews': 72,
        'category': 'Tops',
        'categoryId': '2',
        'description': 'Comfortable casual blouse for everyday wear',
        'sizes': ['XS', 'S', 'M', 'L'],
        'colors': ['White', 'Light Blue', 'Pink'],
        'inStock': true,
        'discount': 28,
      },
      {
        'id': '8',
        'name': 'High-Waist Jeans',
        'price': 55.99,
        'originalPrice': 75.00,
        'image': 'https://images.unsplash.com/photo-1542272604-787c3835535d?w=300&h=400&fit=crop&crop=center',
        'rating': 4.4,
        'reviews': 98,
        'category': 'Bottoms',
        'categoryId': '3',
        'description': 'Stylish high-waist jeans with perfect fit',
        'sizes': ['26', '28', '30', '32', '34'],
        'colors': ['Blue', 'Black', 'Light Blue'],
        'inStock': true,
        'discount': 25,
      },
      {
        'id': '9',
        'name': 'Winter Coat',
        'price': 89.99,
        'originalPrice': 120.00,
        'image': 'https://images.unsplash.com/photo-1551489186-cf8726f514f8?w=300&h=400&fit=crop&crop=center',
        'rating': 4.7,
        'reviews': 145,
        'category': 'Outerwear',
        'categoryId': '4',
        'description': 'Warm and stylish winter coat',
        'sizes': ['S', 'M', 'L', 'XL'],
        'colors': ['Black', 'Grey', 'Navy'],
        'inStock': true,
        'discount': 25,
      },
      {
        'id': '10',
        'name': 'Statement Necklace',
        'price': 25.99,
        'originalPrice': 35.00,
        'image': 'https://images.unsplash.com/photo-1523170335258-f5ed11844a49?w=300&h=400&fit=crop&crop=center',
        'rating': 4.2,
        'reviews': 67,
        'category': 'Accessories',
        'categoryId': '5',
        'description': 'Beautiful statement necklace to complete any look',
        'sizes': ['One Size'],
        'colors': ['Gold', 'Silver', 'Rose Gold'],
        'inStock': true,
        'discount': 26,
      },
    ];
  }

  // Get products by category
  Future<List<Map<String, dynamic>>> getProductsByCategory(String categoryId) async {
    await _simulateDelay();
    
    final allProducts = await getAllProducts();
    return allProducts.where((product) => product['categoryId'] == categoryId).toList();
  }

  // Search products
  Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    await _simulateDelay();
    
    final allProducts = await getAllProducts();
    return allProducts.where((product) => 
      product['name'].toLowerCase().contains(query.toLowerCase()) ||
      product['category'].toLowerCase().contains(query.toLowerCase())
    ).toList();
  }

  // Get product by ID
  Future<Map<String, dynamic>?> getProductById(String productId) async {
    await _simulateDelay();
    
    final allProducts = await getAllProducts();
    try {
      return allProducts.firstWhere((product) => product['id'] == productId);
    } catch (e) {
      return null;
    }
  }

  // Get category by ID
  Future<Map<String, dynamic>?> getCategoryById(String categoryId) async {
    await _simulateDelay();
    
    final categories = await getCategories();
    try {
      return categories.firstWhere((category) => category['id'] == categoryId);
    } catch (e) {
      return null;
    }
  }

  // Real-time data management methods
  final DataChangeService _dataChangeService = DataChangeService();

  // Add new category
  Future<bool> addCategory(Map<String, dynamic> categoryData) async {
    await _simulateDelay();
    await _initializeData();
    
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    final newCategory = {
      'id': newId,
      ...categoryData,
    };
    
    _categories.add(newCategory);
    _dataChangeService.categoryAdded(newId, newCategory);
    return true;
  }

  // Update existing category
  Future<bool> updateCategory(String categoryId, Map<String, dynamic> updates) async {
    await _simulateDelay();
    await _initializeData();
    
    final categoryIndex = _categories.indexWhere((cat) => cat['id'] == categoryId);
    if (categoryIndex != -1) {
      _categories[categoryIndex] = {
        ..._categories[categoryIndex],
        ...updates,
      };
      
      _dataChangeService.categoryUpdated(categoryId, _categories[categoryIndex]);
      return true;
    }
    return false;
  }

  // Remove category
  Future<bool> removeCategory(String categoryId) async {
    await _simulateDelay();
    await _initializeData();
    
    final categoryIndex = _categories.indexWhere((cat) => cat['id'] == categoryId);
    if (categoryIndex != -1) {
      _categories.removeAt(categoryIndex);
      _dataChangeService.categoryRemoved(categoryId);
      return true;
    }
    return false;
  }

  // Add new product
  Future<bool> addProduct(Map<String, dynamic> productData) async {
    await _simulateDelay();
    await _initializeData();
    
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    final newProduct = {
      'id': newId,
      ...productData,
    };
    
    _products.add(newProduct);
    _dataChangeService.productAdded(newId, newProduct);
    return true;
  }

  // Update existing product
  Future<bool> updateProduct(String productId, Map<String, dynamic> updates) async {
    await _simulateDelay();
    await _initializeData();
    
    final productIndex = _products.indexWhere((prod) => prod['id'] == productId);
    if (productIndex != -1) {
      _products[productIndex] = {
        ..._products[productIndex],
        ...updates,
      };
      
      _dataChangeService.productUpdated(productId, _products[productIndex]);
      return true;
    }
    return false;
  }

  // Remove product
  Future<bool> removeProduct(String productId) async {
    await _simulateDelay();
    await _initializeData();
    
    final productIndex = _products.indexWhere((prod) => prod['id'] == productId);
    if (productIndex != -1) {
      _products.removeAt(productIndex);
      _dataChangeService.productRemoved(productId);
      return true;
    }
    return false;
  }

  // Add new banner
  Future<bool> addBanner(Map<String, dynamic> bannerData) async {
    await _simulateDelay();
    await _initializeData();
    
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    final newBanner = {
      'id': newId,
      ...bannerData,
    };
    
    _banners.add(newBanner);
    _dataChangeService.bannerAdded(newId, newBanner);
    return true;
  }

  // Update existing banner
  Future<bool> updateBanner(String bannerId, Map<String, dynamic> updates) async {
    await _simulateDelay();
    await _initializeData();
    
    final bannerIndex = _banners.indexWhere((banner) => banner['id'] == bannerId);
    if (bannerIndex != -1) {
      _banners[bannerIndex] = {
        ..._banners[bannerIndex],
        ...updates,
      };
      
      _dataChangeService.bannerUpdated(bannerId, _banners[bannerIndex]);
      return true;
    }
    return false;
  }

  // Remove banner
  Future<bool> removeBanner(String bannerId) async {
    await _simulateDelay();
    await _initializeData();
    
    final bannerIndex = _banners.indexWhere((banner) => banner['id'] == bannerId);
    if (bannerIndex != -1) {
      _banners.removeAt(bannerIndex);
      _dataChangeService.bannerRemoved(bannerId);
      return true;
    }
    return false;
  }

  // Get data change service
  DataChangeService get dataChangeService => _dataChangeService;
} 