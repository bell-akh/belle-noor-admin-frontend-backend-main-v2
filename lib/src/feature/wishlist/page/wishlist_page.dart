import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:libas_app/src/common/constant/app_color.dart';
import 'package:libas_app/src/common/services/wishlist_service.dart';
import 'package:libas_app/src/common/services/auth_service.dart';
import 'package:libas_app/src/common/services/real_api_service.dart';
import 'package:libas_app/src/common/services/cart_service.dart';
import 'package:libas_app/src/common/widgets/loading_widget.dart';
import 'package:libas_app/src/common/widgets/sign_in_bottom_sheet.dart';
import 'package:libas_app/src/feature/product_details/page/product_details_page.dart';
import 'package:provider/provider.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({Key? key}) : super(key: key);

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  final RealApiService _apiService = RealApiService();
  List<Map<String, dynamic>> allProducts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    if (!mounted) return;
    
    try {
      final products = await _apiService.getAllProducts();
      if (mounted) {
        setState(() {
          allProducts = products;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      appBar: AppBar(
        backgroundColor: AppColors.whiteColor,
        elevation: 0,
        automaticallyImplyLeading: false, // Remove back button
        title: Text(
          'My Wishlist',
          style: GoogleFonts.poppins(
            color: AppColors.primaryColor,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Consumer<WishlistService>(
            builder: (context, wishlistService, child) {
              if (wishlistService.wishlistCount > 0) {
                return TextButton(
                  onPressed: () {
                    _showClearWishlistDialog(context);
                  },
                  child: Text(
                    'Clear All',
                    style: GoogleFonts.poppins(
                      color: AppColors.redColor,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }
              return SizedBox.shrink();
            },
          ),
        ],
      ),
      body: isLoading 
        ? LoadingWidget(message: 'Loading wishlist...')
        : Consumer2<AuthService, WishlistService>(
            builder: (context, authService, wishlistService, child) {
              if (!authService.isAuthenticated) {
                return _buildUnauthenticatedWishlist(context);
              }

              final wishlistedProducts = allProducts
                  .where((product) => wishlistService.isInWishlist(product['id']))
                  .toList();

              if (wishlistedProducts.isEmpty) {
                return _buildEmptyWishlist(context);
              }

          return Column(
            children: [
              // Wishlist count
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                color: AppColors.greyColor.withOpacity(0.1),
                child: Text(
                  '${wishlistedProducts.length} items in wishlist',
                  style: GoogleFonts.poppins(
                    color: AppColors.greyColor,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              
              // Wishlist items
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.all(16.w),
                  itemCount: wishlistedProducts.length,
                  itemBuilder: (context, index) {
                    final product = wishlistedProducts[index];
                    return _buildWishlistItem(context, product, wishlistService);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildUnauthenticatedWishlist(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 80.sp,
            color: AppColors.greyColor.withOpacity(0.5),
          ),
          SizedBox(height: 16.h),
          Text(
            'Sign in to view your wishlist',
            style: GoogleFonts.poppins(
              color: AppColors.blackColor,
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'You need to be signed in to save items\nto your wishlist and view them here',
            style: GoogleFonts.poppins(
              color: AppColors.greyColor,
              fontSize: 14.sp,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
          ElevatedButton(
            onPressed: () {
              // Show sign-in bottom sheet
              showSignInBottomSheet(context);
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
              style: GoogleFonts.poppins(
                color: AppColors.whiteColor,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(height: 12.h),
          OutlinedButton(
            onPressed: () {
              // Navigate to home tab by popping to root and then navigating
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.primaryColor),
              padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25.r),
              ),
            ),
            child: Text(
              'Continue Shopping',
              style: GoogleFonts.poppins(
                color: AppColors.primaryColor,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWishlist(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 80.sp,
            color: AppColors.greyColor.withOpacity(0.5),
          ),
          SizedBox(height: 16.h),
          Text(
            'Your wishlist is empty',
            style: GoogleFonts.poppins(
              color: AppColors.blackColor,
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Start adding items to your wishlist\nby browsing our collections',
            style: GoogleFonts.poppins(
              color: AppColors.greyColor,
              fontSize: 14.sp,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
          ElevatedButton(
            onPressed: () {
              // Navigate to home tab by popping to root and then navigating
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25.r),
              ),
            ),
            child: Text(
              'Start Shopping',
              style: GoogleFonts.poppins(
                color: AppColors.whiteColor,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWishlistItem(BuildContext context, Map<String, dynamic> product, WishlistService wishlistService) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.greyColor.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Product Image
          Container(
            width: 100.w,
            height: 120.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12.r),
                bottomLeft: Radius.circular(12.r),
              ),
              image: DecorationImage(
                                                image: NetworkImage(product['images'][0]),
                fit: BoxFit.cover,
              ),
            ),
          ),
          
          // Product Details
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(12.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          product['name'],
                          style: GoogleFonts.poppins(
                            color: AppColors.blackColor,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          wishlistService.removeFromWishlist(product['id']);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Removed from wishlist'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        child: Icon(
                          Icons.favorite,
                          color: AppColors.redColor,
                          size: 20.sp,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    product['category'],
                    style: GoogleFonts.poppins(
                      color: AppColors.greyColor,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 14.sp,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        '${product['rating']}',
                        style: GoogleFonts.poppins(
                          color: AppColors.greyColor,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        '(${product['reviews']})',
                        style: GoogleFonts.poppins(
                          color: AppColors.greyColor,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Text(
                        '\$${_getSafePrice(product['price'])}',
                        style: GoogleFonts.poppins(
                          color: AppColors.primaryColor,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        '\$${_getSafePrice(product['originalPrice'])}',
                        style: GoogleFonts.poppins(
                          color: AppColors.greyColor,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w400,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            // Add to cart functionality
                            final cartService = context.read<CartService>();
                            final result = await cartService.addToCart(
                              productId: product['id'],
                              quantity: 1,
                            );
                            
                            if (result['success']) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Added to cart successfully'),
                                  backgroundColor: Colors.green,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(result['error'] ?? 'Failed to add to cart'),
                                  backgroundColor: Colors.red,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            padding: EdgeInsets.symmetric(vertical: 8.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                          child: Text(
                            'Add to Cart',
                            style: GoogleFonts.poppins(
                              color: AppColors.whiteColor,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            // View product details
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProductDetailsPage(product: product),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppColors.primaryColor),
                            padding: EdgeInsets.symmetric(vertical: 8.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                          child: Text(
                            'View',
                            style: GoogleFonts.poppins(
                              color: AppColors.primaryColor,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearWishlistDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Clear Wishlist',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'Are you sure you want to remove all items from your wishlist?',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: AppColors.greyColor,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                context.read<WishlistService>().clearWishlist();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Wishlist cleared'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: Text(
                'Clear',
                style: GoogleFonts.poppins(
                  color: AppColors.redColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _getSafePrice(dynamic price) {
    if (price == null) return '0.00';
    if (price is num) {
      return price.toStringAsFixed(2);
    }
    return '0.00';
  }
} 