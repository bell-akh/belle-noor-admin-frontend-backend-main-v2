import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:libas_app/src/common/constant/app_color.dart';
import 'package:libas_app/src/common/services/auth_service.dart';
import 'package:libas_app/src/common/services/wishlist_service.dart';
import 'package:libas_app/src/common/services/cart_service.dart';
import 'package:libas_app/src/common/widgets/sign_in_bottom_sheet.dart';
import 'package:libas_app/src/feature/product_details/page/product_details_page.dart';
import 'package:provider/provider.dart';

class ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback? onTap;

  const ProductCard({
    Key? key,
    required this.product,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer3<AuthService, WishlistService, CartService>(
      builder: (context, authService, wishlistService, cartService, child) {
        final isInWishlist = wishlistService.isInWishlist(product['id']);
        final isInCart = cartService.isInCart(product['id']);
        
        return Container(
          margin: EdgeInsets.only(bottom: 8.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Card with Full Image
              GestureDetector(
                onTap: onTap ?? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductDetailsPage(product: product),
                    ),
                  );
                },
                child: Container(
                  height: 220.h, // Increased height for the card
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12.r),
                        child: Image.network(
                          _getProductImage(),
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: Icon(
                                Icons.image,
                                size: 50.w,
                                color: Colors.grey[600],
                              ),
                            );
                          },
                        ),
                      ),
                      
                      // Wishlist Button
                      Positioned(
                        top: 8.w,
                        right: 8.w,
                        child: GestureDetector(
                          onTap: () => _handleWishlistTap(context, authService, wishlistService),
                          child: Container(
                            padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              isInWishlist ? Icons.favorite : Icons.favorite_border,
                              size: 18.w,
                              color: isInWishlist ? Colors.red : Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                      
                      // Cart Badge
                      if (isInCart)
                        Positioned(
                          top: 8.w,
                          left: 8.w,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor,
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.shopping_cart,
                                  size: 12.w,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  'In Cart',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      
                      // Discount Badge
                      if (_hasDiscount())
                        Positioned(
                          top: isInCart ? 40.h : 8.w,
                          left: 8.w,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Text(
                              '${_getDiscountPercentage()}% OFF',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              
              // Product Details Below the Card
              SizedBox(height: 12.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name
                    Text(
                      product['name'] ?? 'Unknown Product',
                      style: GoogleFonts.poppins(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.blackColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    
                    // Category
                    Text(
                      product['category'] ?? 'Category',
                      style: GoogleFonts.poppins(
                        fontSize: 12.sp,
                        color: AppColors.greyColor,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    
                    // Rating
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          size: 14.w,
                          color: Colors.amber,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          _getSafeRating(product['rating']),
                          style: GoogleFonts.poppins(
                            fontSize: 12.sp,
                            color: AppColors.greyColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '(${product['reviews'] ?? 0})',
                          style: GoogleFonts.poppins(
                            fontSize: 12.sp,
                            color: AppColors.greyColor,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    
                    // Price
                    Row(
                      children: [
                        Text(
                          '\₹${_getCurrentPrice()}',
                          style: GoogleFonts.poppins(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryColor,
                          ),
                        ),
                        if (_hasDiscount()) ...[
                          SizedBox(width: 8.w),
                          Text(
                            '\₹${_getOriginalPrice()}',
                            style: GoogleFonts.poppins(
                              fontSize: 11.sp,
                              color: AppColors.greyColor,
                              fontWeight: FontWeight.w400,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleWishlistTap(BuildContext context, AuthService authService, WishlistService wishlistService) {
    if (!authService.isAuthenticated) {
      // Show sign-in bottom sheet for unauthenticated users
      showSignInBottomSheet(context);
    } else {
      // Toggle wishlist for authenticated users
      final productId = product['id'];
      if (wishlistService.isInWishlist(productId)) {
        wishlistService.removeFromWishlist(productId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed from wishlist'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        wishlistService.addToWishlist(productId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added to wishlist'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  String _getProductImage() {
    if (product['images'] is List && (product['images'] as List).isNotEmpty) {
      return (product['images'] as List).first;
    }
    return 'https://via.placeholder.com/300x400';
  }

  bool _hasDiscount() {
    final originalPrice = product['originalPrice'];
    final currentPrice = product['price'];
    return originalPrice != null && 
           currentPrice != null && 
           originalPrice is num &&
           currentPrice is num &&
           originalPrice > currentPrice;
  }

  String _getCurrentPrice() {
    final price = product['price'];
    if (price == null) return '0.00';
    return (price is num ? price : 0.0).toStringAsFixed(2);
  }

  String _getOriginalPrice() {
    final originalPrice = product['originalPrice'];
    if (originalPrice == null) return '0.00';
    return (originalPrice is num ? originalPrice : 0.0).toStringAsFixed(2);
  }

  String _getDiscountPercentage() {
    final originalPrice = product['originalPrice'];
    final currentPrice = product['price'];
    
    if (originalPrice == null || currentPrice == null || 
        originalPrice is! num || currentPrice is! num) {
      return '0';
    }
    
    if (originalPrice > 0) {
      final discount = ((originalPrice - currentPrice) / originalPrice * 100).round();
      return discount.toString();
    }
    return '0';
  }

  String _getSafeRating(dynamic rating) {
    if (rating == null) return '0.0';
    if (rating is num) {
      return rating.toStringAsFixed(1);
    }
    return '0.0';
  }
} 