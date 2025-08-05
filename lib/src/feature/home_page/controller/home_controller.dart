import 'package:flutter/foundation.dart';
import 'package:libas_app/src/common/services/real_api_service.dart';
import 'package:libas_app/src/common/services/data_change_service.dart';

class HomeController extends ChangeNotifier {
  final RealApiService _apiService = RealApiService();
  DataChangeService? _dataChangeService;
  
  // Banner sections structure
  Map<String, dynamic> _bannerSections = {};
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = false; // Start as not loading
  String? _error;

  // Getters
  Map<String, dynamic> get bannerSections => _bannerSections;
  List<Map<String, dynamic>> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Helper getters for banner sections
  List<Map<String, dynamic>> get homeFirstBanners {
    if (_bannerSections == null || _bannerSections['sections'] == null) {
      return [];
    }
    final section = _bannerSections['sections'].firstWhere(
      (s) => s['id'] == 'home_first',
      orElse: () => {'banners': []},
    );
    return List<Map<String, dynamic>>.from(section['banners'] ?? []);
  }

  List<Map<String, dynamic>> get homeSecondBanners {
    if (_bannerSections == null || _bannerSections['sections'] == null) {
      return [];
    }
    final section = _bannerSections['sections'].firstWhere(
      (s) => s['id'] == 'home_second',
      orElse: () => {'banners': []},
    );
    return List<Map<String, dynamic>>.from(section['banners'] ?? []);
  }

  HomeController() {
    if (kDebugMode) {
      print('🏗️ HomeController: Initialized');
    }
  }

  // Initialize the controller with the shared DataChangeService
  void initialize(DataChangeService dataChangeService) {
    if (kDebugMode) {
      print('🏗️ HomeController: Initializing with shared DataChangeService...');
    }
    _dataChangeService = dataChangeService;
    // Listen to data changes and automatically refresh
    _dataChangeService!.addListener(_onDataChanged);
    if (kDebugMode) {
      print('🏗️ HomeController: Successfully initialized with shared DataChangeService');
      print('🏗️ HomeController: DataChangeService instance: ${_dataChangeService.hashCode}');
    }
  }

  void _onDataChanged() {
    if (kDebugMode) {
      print('🔄 HomeController: Data change detected, refreshing...');
      print('🔄 HomeController: Current categories count: ${_categories.length}');
      print('🔄 HomeController: DataChangeService instance: ${_dataChangeService?.hashCode}');
      print('🔄 HomeController: About to call loadData(forceRefresh: true)...');
    }
    // Force refresh data when changes occur
    loadData(forceRefresh: true);
    if (kDebugMode) {
      print('🔄 HomeController: loadData(forceRefresh: true) called successfully');
    }
  }

  // Load all data for the home page
  Future<void> loadData({bool forceRefresh = false}) async {
    try {
      if (kDebugMode) {
        print('🔄 HomeController: Starting to load data (forceRefresh: $forceRefresh)...');
      }
      
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Load data with caching (no delays needed since we're using cache)
      if (kDebugMode) {
        print('🔄 HomeController: Loading data with caching...');
      }
      
      // Load all data in parallel since we have caching
      final results = await Future.wait([
        _apiService.getBannerSections(forceRefresh: forceRefresh),
        _apiService.getCategories(forceRefresh: forceRefresh),
      ]);

      _bannerSections = results[0] as Map<String, dynamic>;
      _categories = results[1] as List<Map<String, dynamic>>;

      if (kDebugMode) {
        print('📊 HomeController: Loaded ${_bannerSections['sections']?.length ?? 0} banner sections, ${_categories.length} categories');
        print('📊 HomeController: Home first banners: ${homeFirstBanners.length}, Home second banners: ${homeSecondBanners.length}');
        print('📊 HomeController: Category data: ${_categories.isNotEmpty ? _categories.first : 'empty'}');
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('❌ HomeController: Error loading home page data: $e');
      }
    } finally {
      _isLoading = false;
      if (kDebugMode) {
        print('🔄 HomeController: Data loading completed. isLoading: $_isLoading');
      }
      notifyListeners();
    }
  }

  // Force refresh only banner sections
  Future<void> refreshBannerSections() async {
    if (kDebugMode) {
      print('🔄 HomeController: Force refreshing banner sections only...');
    }
    
    try {
      _isLoading = true;
      _error = null; // Clear any previous errors
      notifyListeners();

      // Force refresh banner sections only
      final bannerSections = await _apiService.getBannerSections(forceRefresh: true);
      _bannerSections = bannerSections;

      if (kDebugMode) {
        print('📊 HomeController: Refreshed banner sections: ${_bannerSections['sections']?.length ?? 0} sections');
        print('📊 HomeController: Home first banners: ${homeFirstBanners.length}, Home second banners: ${homeSecondBanners.length}');
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('❌ HomeController: Error refreshing banner sections: $e');
      }
      // Don't clear existing data on error, just show the error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Refresh data
  Future<void> refresh() async {
    await loadData();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _dataChangeService?.removeListener(_onDataChanged);
    super.dispose();
  }
}
