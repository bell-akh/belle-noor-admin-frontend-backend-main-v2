import 'package:flutter/foundation.dart';

class WishlistService extends ChangeNotifier {
  static final WishlistService _instance = WishlistService._internal();
  factory WishlistService() => _instance;
  WishlistService._internal();

  final Set<String> _wishlistItems = {};

  Set<String> get wishlistItems => _wishlistItems;

  bool isInWishlist(String productId) {
    return _wishlistItems.contains(productId);
  }

  void toggleWishlist(String productId) {
    if (_wishlistItems.contains(productId)) {
      _wishlistItems.remove(productId);
    } else {
      _wishlistItems.add(productId);
    }
    notifyListeners();
  }

  void addToWishlist(String productId) {
    if (!_wishlistItems.contains(productId)) {
      _wishlistItems.add(productId);
      notifyListeners();
    }
  }

  void removeFromWishlist(String productId) {
    if (_wishlistItems.contains(productId)) {
      _wishlistItems.remove(productId);
      notifyListeners();
    }
  }

  void clearWishlist() {
    _wishlistItems.clear();
    notifyListeners();
  }

  int get wishlistCount => _wishlistItems.length;
} 