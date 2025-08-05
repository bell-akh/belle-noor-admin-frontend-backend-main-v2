import 'dart:async';
import 'package:flutter/foundation.dart';

class DataChangeService extends ChangeNotifier {
  // Stream controllers for different types of changes
  final StreamController<Map<String, dynamic>> _productChangeController = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _categoryChangeController = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _bannerChangeController = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _orderChangeController = StreamController<Map<String, dynamic>>.broadcast();

  // Streams for listening to changes
  Stream<Map<String, dynamic>> get productChanges => _productChangeController.stream;
  Stream<Map<String, dynamic>> get categoryChanges => _categoryChangeController.stream;
  Stream<Map<String, dynamic>> get bannerChanges => _bannerChangeController.stream;
  Stream<Map<String, dynamic>> get orderChanges => _orderChangeController.stream;

  // Change counters
  int _productChangeCount = 0;
  int _categoryChangeCount = 0;
  int _bannerChangeCount = 0;
  int _orderChangeCount = 0;

  int get productChangeCount => _productChangeCount;
  int get categoryChangeCount => _categoryChangeCount;
  int get bannerChangeCount => _bannerChangeCount;
  int get orderChangeCount => _orderChangeCount;

  // Handle real-time events from SSE
  void notifyProductChange(Map<String, dynamic> event) {
    _productChangeCount++;
    _productChangeController.add(event);
    notifyListeners();
    
    if (kDebugMode) {
      print('📡 Product change notified: ${event['type']}');
    }
  }

  void notifyCategoryChange(Map<String, dynamic> event) {
    _categoryChangeCount++;
    _categoryChangeController.add(event);
    
    if (kDebugMode) {
      print('📡 Category change notified: ${event['type']}');
      print('📡 Category change count: $_categoryChangeCount');
      print('📡 DataChangeService instance: ${hashCode}');
      print('📡 Notifying listeners...');
    }
    
    notifyListeners();
    
    if (kDebugMode) {
      print('📡 Listeners notified successfully');
    }
  }

  void notifyBannerChange(Map<String, dynamic> event) {
    _bannerChangeCount++;
    _bannerChangeController.add(event);
    notifyListeners();
    
    if (kDebugMode) {
      print('📡 Banner change notified: ${event['type']}');
    }
  }

    void notifyOrderChange(Map<String, dynamic> event) {
    _orderChangeCount++;
    _orderChangeController.add(event);
    notifyListeners();

    if (kDebugMode) {
      print('📡 Order change notified: ${event['type']}');
    }
  }

  // Likes change stream
  final StreamController<Map<String, dynamic>> _likesChangeController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get likesChanges => _likesChangeController.stream;

  int _likesChangeCount = 0;
  int get likesChangeCount => _likesChangeCount;

  void notifyLikesChange(Map<String, dynamic> event) {
    _likesChangeCount++;
    _likesChangeController.add(event);
    notifyListeners();

    if (kDebugMode) {
      print('📡 Likes change notified: ${event['type']}');
    }
  }

  // Legacy methods for backward compatibility
  void notifyProductAdded() {
    _productChangeCount++;
    _productChangeController.add({
      'type': 'product_added',
      'timestamp': DateTime.now().toIso8601String(),
    });
    notifyListeners();
  }

  void notifyProductUpdated() {
    _productChangeCount++;
    _productChangeController.add({
      'type': 'product_updated',
      'timestamp': DateTime.now().toIso8601String(),
    });
    notifyListeners();
  }

  void notifyProductRemoved() {
    _productChangeCount++;
    _productChangeController.add({
      'type': 'product_removed',
      'timestamp': DateTime.now().toIso8601String(),
    });
    notifyListeners();
  }

  void notifyCategoryAdded() {
    _categoryChangeCount++;
    _categoryChangeController.add({
      'type': 'category_added',
      'timestamp': DateTime.now().toIso8601String(),
    });
    notifyListeners();
  }

  void notifyCategoryUpdated() {
    _categoryChangeCount++;
    _categoryChangeController.add({
      'type': 'category_updated',
      'timestamp': DateTime.now().toIso8601String(),
    });
    notifyListeners();
  }

  void notifyCategoryRemoved() {
    _categoryChangeCount++;
    _categoryChangeController.add({
      'type': 'category_removed',
      'timestamp': DateTime.now().toIso8601String(),
    });
    notifyListeners();
  }

  void notifyBannerAdded() {
    _bannerChangeCount++;
    _bannerChangeController.add({
      'type': 'banner_added',
      'timestamp': DateTime.now().toIso8601String(),
    });
    notifyListeners();
  }

  void notifyBannerUpdated() {
    _bannerChangeCount++;
    _bannerChangeController.add({
      'type': 'banner_updated',
      'timestamp': DateTime.now().toIso8601String(),
    });
    notifyListeners();
  }

  void notifyBannerRemoved() {
    _bannerChangeCount++;
    _bannerChangeController.add({
      'type': 'banner_removed',
      'timestamp': DateTime.now().toIso8601String(),
    });
    notifyListeners();
  }

  // Alias methods for compatibility
  void productAdded([String? id, Map<String, dynamic>? data]) => notifyProductAdded();
  void productUpdated([String? id, Map<String, dynamic>? data]) => notifyProductUpdated();
  void productRemoved([String? id]) => notifyProductRemoved();
  void categoryAdded([String? id, Map<String, dynamic>? data]) => notifyCategoryAdded();
  void categoryUpdated([String? id, Map<String, dynamic>? data]) => notifyCategoryUpdated();
  void categoryRemoved([String? id]) => notifyCategoryRemoved();
  void bannerAdded([String? id, Map<String, dynamic>? data]) => notifyBannerAdded();
  void bannerUpdated([String? id, Map<String, dynamic>? data]) => notifyBannerUpdated();
  void bannerRemoved([String? id]) => notifyBannerRemoved();

  // Reset change counters
  void resetCounters() {
    _productChangeCount = 0;
    _categoryChangeCount = 0;
    _bannerChangeCount = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _productChangeController.close();
    _categoryChangeController.close();
    _bannerChangeController.close();
    super.dispose();
  }
} 