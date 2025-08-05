import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:libas_app/src/common/constant/app_color.dart';
import 'package:libas_app/src/common/services/real_api_service.dart';
import 'package:libas_app/src/common/services/data_change_service.dart';
import 'package:libas_app/src/common/services/auth_service.dart';
import 'package:libas_app/src/common/widgets/cart_badge.dart';
import 'package:libas_app/src/common/widgets/wishlist_badge.dart';
import 'package:libas_app/src/feature/home_page/controller/home_controller.dart';
import 'package:libas_app/src/feature/home_page/page/home_page.dart';
import 'package:libas_app/src/feature/wishlist/page/wishlist_page.dart';
import 'package:libas_app/src/feature/cart/page/cart_page.dart';
import 'package:libas_app/src/feature/video_explore/page/reels_video_page.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

// Import pages from main.dart
import 'package:libas_app/main.dart' show AllProductsPage;
import 'package:libas_app/src/feature/profile/page/profile_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  late RealApiService _apiService;
  late DataChangeService _dataChangeService;
  late AuthService _authService;
  late HomeController _homeController;
  
  double _progress = 0.0;
  String _loadingText = 'Initializing...';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    // Start animations
    _animationController.forward();
    
    // Initialize services and load data
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      // Get service instances
      _apiService = context.read<RealApiService>();
      _dataChangeService = context.read<DataChangeService>();
      _authService = context.read<AuthService>();
      _homeController = context.read<HomeController>();
      
      if (kDebugMode) {
        print('🚀 SplashScreen: Starting data pre-loading...');
      }
      
      // Step 1: Initialize services
      _updateProgress(0.1, 'Initializing services...');
      _apiService.initialize(_dataChangeService);
      _homeController.initialize(_dataChangeService);
      
      // Step 2: Initialize authentication
      _updateProgress(0.2, 'Setting up authentication...');
      await _authService.initialize();
      
      // Step 3: Connect to real-time updates
      _updateProgress(0.3, 'Connecting to real-time updates...');
      await _apiService.connectToRealtimeUpdates();
      
      // Step 4: Load banner sections
      _updateProgress(0.4, 'Loading banner sections...');
      await _homeController.loadData(forceRefresh: true);
      
      // Step 5: Pre-load banner images
      _updateProgress(0.6, 'Pre-loading images...');
      await _preloadBannerImages();
      
      // Step 6: Load categories
      _updateProgress(0.8, 'Loading categories...');
      await _apiService.getCategories(forceRefresh: true);
      
      // Step 7: Load initial products
      _updateProgress(0.9, 'Loading products...');
      await _apiService.getAllProducts(forceRefresh: true);
      
      // Step 8: Complete
      _updateProgress(1.0, 'Ready!');
      
      // Wait a bit for smooth transition
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        // Navigate to main app
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const MainApp(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ SplashScreen: Error during initialization: $e');
      }
      
      // Even if there's an error, proceed to main app
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const MainApp(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    }
  }

  Future<void> _preloadBannerImages() async {
    try {
      final banners = _homeController.homeFirstBanners;
      final imageUrls = <String>[];
      
      // Collect all image URLs from banners
      for (final banner in banners) {
        final imageUrl = banner['image'] as String?;
        if (imageUrl != null && imageUrl.isNotEmpty) {
          imageUrls.add(imageUrl);
        }
      }
      
      // Pre-load images in parallel
      await Future.wait(
        imageUrls.map((url) => _preloadImage(url)),
      );
      
      if (kDebugMode) {
        print('🖼️ SplashScreen: Pre-loaded ${imageUrls.length} images');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ SplashScreen: Error pre-loading images: $e');
      }
    }
  }

  Future<void> _preloadImage(String imageUrl) async {
    try {
      final image = NetworkImage(imageUrl);
      final imageStream = image.resolve(const ImageConfiguration());
      final completer = Completer<void>();
      imageStream.addListener(ImageStreamListener((info, _) {
        completer.complete();
      }));
      await completer.future.timeout(const Duration(seconds: 10));
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ SplashScreen: Failed to pre-load image $imageUrl: $e');
      }
    }
  }

  void _updateProgress(double progress, String text) {
    if (mounted) {
      setState(() {
        _progress = progress;
        _loadingText = text;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo with animations
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      width: 120.w,
                      height: 120.w,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.shopping_bag,
                        size: 60.w,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
                );
              },
            ),
            
            SizedBox(height: 40.h),
            
            // App name
            FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                'Belle Noor',
                style: TextStyle(
                  fontSize: 32.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
            ),
            
            SizedBox(height: 8.h),
            
            // Tagline
            FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                'Fashion & Lifestyle',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.white70,
                  letterSpacing: 1,
                ),
              ),
            ),
            
            SizedBox(height: 60.h),
            
            // Loading text
            FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                _loadingText,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.white70,
                ),
              ),
            ),
            
            SizedBox(height: 20.h),
            
            // Progress bar
            FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                width: 200.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2.r),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _progress,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.textYellowColor,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
              ),
            ),
            
            SizedBox(height: 10.h),
            
            // Progress percentage
            FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                '${(_progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.white60,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// MainApp widget (moved from main.dart)
class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  late RealApiService _apiService;
  late DataChangeService _dataChangeService;
  late AuthService _authService;
  late HomeController _homeController;
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const AllProductsPage(),
    const ReelsVideoPage(),
    const WishlistPage(),
    const ProfilePage(),
  ];

  final List<String> _titles = [
    'Home',
    'Products',
    'Reels',
    'Wishlist',
    'Profile',
  ];

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      print('🏗️ MainApp: Initializing...');
    }
    
    _apiService = context.read<RealApiService>();
    _dataChangeService = context.read<DataChangeService>();
    _authService = context.read<AuthService>();
    _homeController = context.read<HomeController>();
    
    if (kDebugMode) {
      print('🏗️ MainApp: DataChangeService instance: ${_dataChangeService.hashCode}');
      print('🏗️ MainApp: HomeController instance: ${_homeController.hashCode}');
    }
    
    // Listen to data changes and refresh UI
    _dataChangeService.addListener(_onDataChanged);
    
    if (kDebugMode) {
      print('🏗️ MainApp: Initialization completed');
    }
  }

  void _onDataChanged() {
    if (mounted) {
      setState(() {
        // Trigger UI refresh when data changes
      });
      
      // Show notification for data changes (only if there are actual changes)
      final productChanges = _dataChangeService.productChangeCount;
      final categoryChanges = _dataChangeService.categoryChangeCount;
      final bannerChanges = _dataChangeService.bannerChangeCount;
      
      final totalChanges = productChanges + categoryChanges + bannerChanges;
      if (totalChanges > 0) {
        // Use a simple print instead of SnackBar to avoid layout issues
        if (kDebugMode) {
          print('🔄 Data updated: $totalChanges changes');
        }
      }
    }
  }

  @override
  void dispose() {
    _dataChangeService.removeListener(_onDataChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: (_currentIndex == 0 || _currentIndex == 2) ? null : AppBar( // Hide app bar for Home (index 0) and Reels (index 2)
        title: Text(_titles[_currentIndex]),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          CartBadge(
            child: IconButton(
              icon: const Icon(Icons.shopping_cart),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CartPage()),
                );
              },
            ),
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primaryColor,
        unselectedItemColor: Colors.grey,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'Products',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.video_library),
            label: 'Reels',
          ),
          BottomNavigationBarItem(
            icon: WishlistBadge(
              child: const Icon(Icons.favorite),
            ),
            label: 'Wishlist',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
} 