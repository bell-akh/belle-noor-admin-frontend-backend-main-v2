import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:libas_app/src/common/services/real_api_service.dart';
import 'package:libas_app/src/common/constant/app_color.dart';
import 'package:libas_app/src/common/widgets/product_card.dart';
import 'package:libas_app/src/feature/wishlist/page/wishlist_page.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

class CategoryProductPage extends StatefulWidget {
  final String categoryId;
  final String categoryName;
  final String categoryImage;

  const CategoryProductPage({
    super.key,
    required this.categoryId,
    required this.categoryName,
    required this.categoryImage,
  });

  @override
  State<CategoryProductPage> createState() => _CategoryProductPageState();
}

class _CategoryProductPageState extends State<CategoryProductPage> {
  final RealApiService _apiService = RealApiService();
  
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      if (kDebugMode) {
        print('🔄 CategoryProductPage: Starting to load data for category: ${widget.categoryId} (${widget.categoryName})');
      }
      
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Load only products for this category
      final products = await _apiService.getProductsByCategory(widget.categoryId);

      if (kDebugMode) {
        print('📊 CategoryProductPage: API returned ${products.length} products for category ${widget.categoryId}');
      }

      setState(() {
        _products = products;
        _isLoading = false;
      });

      if (kDebugMode) {
        print('📊 CategoryProductPage: Loaded ${_products.length} products for category ${widget.categoryName}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ CategoryProductPage: Error loading data: $e');
      }
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredProducts {
    if (_searchQuery.isEmpty) {
      return _products;
    }
    return _products.where((product) {
      final name = product['name']?.toString().toLowerCase() ?? '';
      final desc = product['desc']?.toString().toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || desc.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      appBar: AppBar(
        title: Text(widget.categoryName),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const WishlistPage()),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $_error'),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: CustomScrollView(
                    slivers: [
                      // Search Bar
                      SliverToBoxAdapter(
                        child: Container(
                          margin: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(16.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Search in ${widget.categoryName}...',
                              hintStyle: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16.sp,
                              ),
                              prefixIcon: Icon(
                                Icons.search,
                                color: Colors.grey[600],
                                size: 24.w,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 20.w,
                                vertical: 16.h,
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                            },
                          ),
                        ),
                      ),





                      // Products Section Header
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Products (${_filteredProducts.length})',
                                style: TextStyle(
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.blackColor,
                                ),
                              ),
                              if (_searchQuery.isNotEmpty)
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _searchQuery = '';
                                    });
                                  },
                                  child: Text(
                                    'Clear',
                                    style: TextStyle(
                                      color: AppColors.primaryColor,
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                      // Products Grid
                      if (_filteredProducts.isEmpty)
                        SliverToBoxAdapter(
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.all(64.w),
                              child: Column(
                                children: [
                                  Icon(
                                    _searchQuery.isEmpty ? Icons.inventory_2 : Icons.search_off,
                                    size: 80.w,
                                    color: AppColors.greyColor,
                                  ),
                                  SizedBox(height: 24.h),
                                  Text(
                                    _searchQuery.isEmpty 
                                        ? 'No products in this category yet'
                                        : 'No products match your search',
                                    style: TextStyle(
                                      fontSize: 18.sp,
                                      color: AppColors.greyColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: 8.h),
                                  Text(
                                    _searchQuery.isEmpty 
                                        ? 'Check back later for new products'
                                        : 'Try different keywords',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
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
                                
                                return ProductCard(
                                  product: product,
                                );
                              },
                              childCount: _filteredProducts.length,
                            ),
                          ),
                        ),

                      // Bottom padding
                      SliverToBoxAdapter(
                        child: SizedBox(height: 32.h),
                      ),
                    ],
                  ),
                ),
    );
  }
} 