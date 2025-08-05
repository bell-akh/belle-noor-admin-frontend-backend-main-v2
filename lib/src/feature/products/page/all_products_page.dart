import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:libas_app/src/common/constant/app_color.dart';
import 'package:libas_app/src/common/services/real_api_service.dart';
import 'package:libas_app/src/common/widgets/product_card.dart';
import 'package:flutter/foundation.dart';

class AllProductsPage extends StatefulWidget {
  const AllProductsPage({super.key});

  @override
  State<AllProductsPage> createState() => _AllProductsPageState();
}

class _AllProductsPageState extends State<AllProductsPage> {
  final RealApiService _apiService = RealApiService();
  
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final products = await _apiService.getAllProducts();

      setState(() {
        _products = products;
        _isLoading = false;
      });

      if (kDebugMode) {
        print('🛍️ AllProductsPage: Loaded ${_products.length} products');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      if (kDebugMode) {
        print('❌ AllProductsPage: Error loading products: $e');
      }
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
        title: const Text('All Products'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
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
                        onPressed: _loadProducts,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadProducts,
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
                              hintText: 'Search products...',
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
                      SliverPadding(
                        padding: EdgeInsets.all(16.w),
                        sliver: SliverGrid(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 16.w,
                            mainAxisSpacing: 16.h,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final product = _filteredProducts[index];
                              return ProductCard(product: product);
                            },
                            childCount: _filteredProducts.length,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
} 