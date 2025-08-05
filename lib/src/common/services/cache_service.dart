import 'dart:async';
import 'package:flutter/foundation.dart';

class CacheService extends ChangeNotifier {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  final Map<String, CacheEntry> _cache = {};
  final Map<String, Timer> _timers = {};

  // Cache TTL durations
  static const Duration _defaultTtl = Duration(minutes: 5);
  static const Duration _shortTtl = Duration(minutes: 2);
  static const Duration _longTtl = Duration(minutes: 15);

  // Cache keys
  static const String _productsKey = 'products';
  static const String _categoriesKey = 'categories';
  static const String _bannersKey = 'banners';
  static const String _smallBannersKey = 'small_banners';
  static const String _videosKey = 'videos';
  static const String _bannerSectionsKey = 'banner_sections';

  // Get cached data
  T? get<T>(String key) {
    final entry = _cache[key];
    if (entry == null) return null;

    if (DateTime.now().isAfter(entry.expiryTime)) {
      _remove(key);
      return null;
    }

    if (kDebugMode) {
      print('📦 Cache hit for key: $key');
    }
    return entry.data as T;
  }

  // Set cached data
  void set<T>(String key, T data, {Duration? ttl}) {
    final expiryTime = DateTime.now().add(ttl ?? _defaultTtl);
    _cache[key] = CacheEntry(data: data, expiryTime: expiryTime);

    // Set up automatic cleanup
    _timers[key]?.cancel();
    _timers[key] = Timer(ttl ?? _defaultTtl, () {
      _remove(key);
    });

    if (kDebugMode) {
      print('📦 Cached data for key: $key (expires: $expiryTime)');
    }
    notifyListeners();
  }

  // Remove cached data
  void _remove(String key) {
    _cache.remove(key);
    _timers[key]?.cancel();
    _timers.remove(key);
    
    if (kDebugMode) {
      print('🗑️ Removed cache for key: $key');
    }
  }

  // Invalidate specific cache
  void invalidate(String key) {
    _remove(key);
    if (kDebugMode) {
      print('🔄 Invalidated cache for key: $key');
    }
  }

  // Invalidate all cache
  void invalidateAll() {
    _cache.clear();
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    
    if (kDebugMode) {
      print('🔄 Invalidated all cache');
    }
    notifyListeners();
  }

  // Check if data is cached and valid
  bool hasValid(String key) {
    final entry = _cache[key];
    if (entry == null) return false;
    return DateTime.now().isBefore(entry.expiryTime);
  }

  // Get cache statistics
  Map<String, dynamic> getStats() {
    final now = DateTime.now();
    final validEntries = _cache.entries.where((entry) => 
      now.isBefore(entry.value.expiryTime)
    ).length;
    
    return {
      'totalEntries': _cache.length,
      'validEntries': validEntries,
      'expiredEntries': _cache.length - validEntries,
    };
  }

  // Specific cache methods for different data types
  List<Map<String, dynamic>>? getProducts() => get<List<Map<String, dynamic>>>(_productsKey);
  void setProducts(List<Map<String, dynamic>> products) => set(_productsKey, products, ttl: _shortTtl);

  List<Map<String, dynamic>>? getCategories() => get<List<Map<String, dynamic>>>(_categoriesKey);
  void setCategories(List<Map<String, dynamic>> categories) => set(_categoriesKey, categories, ttl: _longTtl);

  List<Map<String, dynamic>>? getBanners() => get<List<Map<String, dynamic>>>(_bannersKey);
  void setBanners(List<Map<String, dynamic>> banners) => set(_bannersKey, banners, ttl: _shortTtl);

  List<Map<String, dynamic>>? getSmallBanners() => get<List<Map<String, dynamic>>>(_smallBannersKey);
  void setSmallBanners(List<Map<String, dynamic>> banners) => set(_smallBannersKey, banners, ttl: _shortTtl);

  List<Map<String, dynamic>>? getVideos() => get<List<Map<String, dynamic>>>(_videosKey);
  void setVideos(List<Map<String, dynamic>> videos) => set(_videosKey, videos, ttl: _shortTtl);

  Map<String, dynamic>? getBannerSections() => get<Map<String, dynamic>>(_bannerSectionsKey);
  void setBannerSections(Map<String, dynamic> sections) => set(_bannerSectionsKey, sections, ttl: _shortTtl);

  // Invalidate specific data types
  void invalidateProducts() {
    if (kDebugMode) {
      print('🗑️ CacheService: Invalidating products cache');
    }
    invalidate(_productsKey);
  }
  
  void invalidateCategories() {
    if (kDebugMode) {
      print('🗑️ CacheService: Invalidating categories cache');
    }
    invalidate(_categoriesKey);
  }
  
  void invalidateBanners() {
    if (kDebugMode) {
      print('🗑️ CacheService: Invalidating banners cache');
    }
    invalidate(_bannersKey);
  }
  
  void invalidateVideos() {
    if (kDebugMode) {
      print('🗑️ CacheService: Invalidating videos cache');
    }
    invalidate(_videosKey);
  }

  void invalidateBannerSections() {
    if (kDebugMode) {
      print('🗑️ CacheService: Invalidating banner sections cache');
    }
    invalidate(_bannerSectionsKey);
  }

  @override
  void dispose() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    _cache.clear();
    super.dispose();
  }
}

class CacheEntry {
  final dynamic data;
  final DateTime expiryTime;

  CacheEntry({required this.data, required this.expiryTime});
} 