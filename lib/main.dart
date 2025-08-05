import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:libas_app/src/common/services/real_api_service.dart';
import 'package:libas_app/src/common/services/data_change_service.dart';
import 'package:libas_app/src/common/services/wishlist_service.dart';
import 'package:libas_app/src/common/services/auth_service.dart';
import 'package:libas_app/src/common/services/cart_service.dart';
import 'package:libas_app/src/common/services/video_service.dart';
import 'package:libas_app/src/common/services/cache_service.dart';
import 'package:libas_app/src/feature/home_page/controller/home_controller.dart';
import 'package:libas_app/src/common/widgets/splash_screen.dart';
import 'package:libas_app/src/common/constant/app_color.dart';
import 'package:libas_app/src/common/widgets/product_card.dart';
import 'package:libas_app/src/common/widgets/sign_in_bottom_sheet.dart';
import 'package:libas_app/src/feature/orders/page/orders_page.dart';
import 'package:libas_app/src/feature/wishlist/page/wishlist_page.dart';
import 'package:flutter/foundation.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => WishlistService()),
        ChangeNotifierProvider(create: (_) => CartService()),
        ChangeNotifierProvider(create: (_) => DataChangeService()),
        ChangeNotifierProvider(create: (_) => HomeController()),
        ChangeNotifierProvider(create: (_) => VideoService()),
        ChangeNotifierProvider(create: (_) => CacheService()),
        Provider<RealApiService>(create: (_) => RealApiService()),
      ],
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return MaterialApp(
            title: 'Belle Noor',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              primarySwatch: Colors.blue,
              visualDensity: VisualDensity.adaptivePlatformDensity,
            ),
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}



// All Products Page
class AllProductsPage extends StatefulWidget {
  const AllProductsPage({super.key});

  @override
  State<AllProductsPage> createState() => _AllProductsPageState();
}

class _AllProductsPageState extends State<AllProductsPage> {
  final RealApiService _apiService = RealApiService();
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = false; // Start as not loading
  String? _error;
  String _searchQuery = '';
  late DataChangeService _dataChangeService;

  @override
  void initState() {
    super.initState();
    _dataChangeService = context.read<DataChangeService>();
    _loadProductsIfNeeded();
    
    // Listen to data changes
    _dataChangeService.addListener(_onDataChanged);
  }

  Future<void> _loadProductsIfNeeded() async {
    if (!mounted) return;
    
    // Load if products are empty (regardless of loading state)
    if (_products.isEmpty) {
      if (kDebugMode) {
        print('🛍️ AllProductsPage: Loading products (products: ${_products.length})');
      }
      await _loadProducts();
    } else {
      if (kDebugMode) {
        print('🛍️ AllProductsPage: Using existing products (products: ${_products.length})');
      }
    }
  }

  void _onDataChanged() {
    if (kDebugMode) {
      print('🛍️ AllProductsPage: Data change detected, refreshing products');
    }
    if (mounted) {
      // Force refresh products when changes occur
      _loadProducts(forceRefresh: true);
    }
  }

  Future<void> _loadProducts({bool forceRefresh = false}) async {
    if (!mounted) return;
    
    if (kDebugMode) {
      print('🛍️ AllProductsPage: Starting to load products (forceRefresh: $forceRefresh)');
    }
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final products = await _apiService.getAllProducts(forceRefresh: forceRefresh);
      if (mounted) {
        setState(() {
          _products = products;
          _isLoading = false;
        });
        if (kDebugMode) {
          print('🛍️ AllProductsPage: Loaded ${products.length} products');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
        if (kDebugMode) {
          print('❌ AllProductsPage: Error loading products: $e');
        }
      }
    }
  }

  @override
  void dispose() {
    _dataChangeService.removeListener(_onDataChanged);
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredProducts {
    if (_searchQuery.isEmpty) return _products;
    return _products.where((product) {
      final name = product['name']?.toString().toLowerCase() ?? '';
      final desc = product['desc']?.toString().toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || desc.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => _loadProducts(forceRefresh: true),
      child: CustomScrollView(
        slivers: [
          // Search Bar
          SliverToBoxAdapter(
            child: Container(
              margin: EdgeInsets.all(16.w),
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  border: InputBorder.none,
                  icon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                ),
              ),
            ),
          ),

          // Products Grid
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (_error != null)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 80.w, color: Colors.grey),
                    SizedBox(height: 16.h),
                    Text('Error loading products'),
                    SizedBox(height: 8.h),
                    Text(_error!, style: TextStyle(color: Colors.grey[600])),
                    SizedBox(height: 16.h),
                    ElevatedButton(
                      onPressed: _loadProducts,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else if (_filteredProducts.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _searchQuery.isEmpty ? Icons.inventory_2 : Icons.search_off,
                      size: 80.w,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      _searchQuery.isEmpty
                          ? 'No products available'
                          : 'No products found for "$_searchQuery"',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_searchQuery.isNotEmpty) ...[
                      SizedBox(height: 8.h),
                      Text(
                        'Try a different search term',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.all(16.w),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.5,
                  crossAxisSpacing: 16.w,
                  mainAxisSpacing: 24.h,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final product = _filteredProducts[index];
                    return _buildProductCard(product);
                  },
                  childCount: _filteredProducts.length,
                ),
              ),
            ),

          // Bottom padding
          SliverToBoxAdapter(
            child: SizedBox(height: 20.h),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return ProductCard(
      product: product,
    );
  }
}

// Profile Page
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        if (!authService.isAuthenticated) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_outline, size: 100.w, color: Colors.grey),
                SizedBox(height: 16.h),
                Text(
                  'Sign in to view your profile',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Access your account details and preferences',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24.h),
                ElevatedButton(
                  onPressed: () {
                    // showSignInBottomSheet(context);
                    // TODO: Implement sign in functionality
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25.r),
                    ),
                  ),
                  child: Text(
                    'Sign In',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final user = authService.currentUser;
        return Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            children: [
              // Profile Header
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40.r,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person,
                        size: 40.w,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      user?['name'] ?? 'User',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      user?['email'] ?? 'user@example.com',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14.sp,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),
              
              // Profile Options
              _buildProfileOption(
                context,
                icon: Icons.favorite,
                title: 'My Wishlist',
                subtitle: 'View your saved items',
                onTap: () {
                  // Navigate to wishlist
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const WishlistPage()),
                  );
                },
              ),
              _buildProfileOption(
                context,
                icon: Icons.shopping_bag,
                title: 'My Orders',
                subtitle: 'Track your orders',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const OrdersPage()),
                  );
                },
              ),
              _buildProfileOption(
                context,
                icon: Icons.location_on,
                title: 'Shipping Address',
                subtitle: 'Manage your addresses',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Address management coming soon!')),
                  );
                },
              ),
              _buildProfileOption(
                context,
                icon: Icons.settings,
                title: 'Settings',
                subtitle: 'App preferences',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Settings coming soon!')),
                  );
                },
              ),
              
              Spacer(),
              
              // Logout Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await authService.logout();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Successfully logged out')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: Text(
                    'Logout',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: AppColors.primaryColor,
          size: 24.w,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.grey[600],
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16.w,
          color: Colors.grey[400],
        ),
        onTap: onTap,
      ),
    );
  }
}
