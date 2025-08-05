import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:libas_app/src/common/constant/app_color.dart';
import 'package:libas_app/src/common/services/auth_service.dart';
import 'package:libas_app/src/common/services/wishlist_service.dart';
import 'package:libas_app/src/common/services/cart_service.dart';
import 'package:libas_app/src/common/widgets/sign_in_bottom_sheet.dart';
import 'package:libas_app/src/feature/checkout/page/checkout_page.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

class ProductDetailsPage extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailsPage({
    Key? key,
    required this.product,
  }) : super(key: key);

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();
  String _selectedSize = 'M';
  int _quantity = 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<String> get _productImages {
    if (widget.product['images'] is List && (widget.product['images'] as List).isNotEmpty) {
      return (widget.product['images'] as List).cast<String>();
    }
    return ['https://via.placeholder.com/400x600'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.blackColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: AppColors.blackColor),
            onPressed: () {
              // TODO: Implement search functionality
            },
          ),
          // Debug button to check auth status
          IconButton(
            icon: Icon(Icons.bug_report, color: AppColors.blackColor),
            onPressed: () {
              final authService = Provider.of<AuthService>(context, listen: false);
              print('=== DEBUG AUTH STATUS ===');
              print('isAuthenticated: ${authService.isAuthenticated}');
              print('currentUser: ${authService.currentUser}');
              print('authToken: ${authService.authToken}');
              print('========================');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Auth: ${authService.isAuthenticated ? 'Logged In' : 'Not Logged In'}'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          // Debug button to test cart API
          IconButton(
            icon: Icon(Icons.shopping_cart, color: AppColors.blackColor),
            onPressed: () async {
              final authService = Provider.of<AuthService>(context, listen: false);
              if (!authService.isAuthenticated) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Please login first')),
                );
                return;
              }
              
              try {
                final response = await http.get(
                  Uri.parse('http://BelleN-NodeS-htzjq6lxvVlw-908287247.ap-south-1.elb.amazonaws.com/api/cart'),
                  headers: {
                    'Content-Type': 'application/json',
                    'Authorization': 'Bearer ${authService.authToken}',
                  },
                );
                
                print('=== CART API TEST ===');
                print('Status: ${response.statusCode}');
                print('Response: ${response.body}');
                print('=====================');
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Cart API: ${response.statusCode}'),
                    duration: Duration(seconds: 2),
                  ),
                );
              } catch (e) {
                print('Cart API test error: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
          ),
          Consumer2<AuthService, WishlistService>(
            builder: (context, authService, wishlistService, child) {
              final isInWishlist = wishlistService.isInWishlist(widget.product['id']);
              
              return IconButton(
                icon: Icon(
                  isInWishlist ? Icons.favorite : Icons.favorite_border,
                  color: isInWishlist ? Colors.red : AppColors.blackColor,
                ),
                onPressed: () {
                  if (!authService.isAuthenticated) {
                    showSignInBottomSheet(context);
                  } else {
                    final productId = widget.product['id'];
                    if (isInWishlist) {
                      wishlistService.removeFromWishlist(productId);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Removed from wishlist')),
                      );
                    } else {
                      wishlistService.addToWishlist(productId);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Added to wishlist')),
                      );
                    }
                  }
                },
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.shopping_bag_outlined, color: AppColors.blackColor),
            onPressed: () {
              // TODO: Implement cart functionality
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Carousel Section
            SizedBox(
              height: 400.h,
              child: Stack(
                children: [
                  // PageView for multiple images
                  PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentImageIndex = index;
                      });
                    },
                    itemCount: _productImages.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: EdgeInsets.symmetric(horizontal: 16.w),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16.r),
                          child: Image.network(
                            _productImages[index],
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[300],
                                child: Icon(
                                  Icons.image,
                                  size: 80.w,
                                  color: Colors.grey[600],
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  
                  // Image indicators
                  if (_productImages.length > 1)
                    Positioned(
                      bottom: 20.h,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _productImages.length,
                          (index) => Container(
                            margin: EdgeInsets.symmetric(horizontal: 4.w),
                            width: _currentImageIndex == index ? 24.w : 8.w,
                            height: 8.h,
                            decoration: BoxDecoration(
                              color: _currentImageIndex == index 
                                  ? AppColors.primaryColor 
                                  : Colors.grey[400],
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                          ),
                        ),
                      ),
                    ),
                  
                  // Discount badge
                  if (_hasDiscount())
                    Positioned(
                      top: 20.h,
                      left: 20.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Text(
                          '${_getDiscountPercentage()}% OFF',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Product Information Section
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name
                  Text(
                    widget.product['name'] ?? 'Unknown Product',
                    style: GoogleFonts.poppins(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.blackColor,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  
                  // Category
                  Text(
                    widget.product['category'] ?? 'Category',
                    style: GoogleFonts.poppins(
                      fontSize: 16.sp,
                      color: AppColors.greyColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  
                  // Rating and Reviews
                  Row(
                    children: [
                      Icon(Icons.star, size: 20.w, color: Colors.amber),
                      SizedBox(width: 4.w),
                      Text(
                        _getSafeRating(widget.product['rating']),
                        style: GoogleFonts.poppins(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.blackColor,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        '(${widget.product['reviews'] ?? 0} reviews)',
                        style: GoogleFonts.poppins(
                          fontSize: 14.sp,
                          color: AppColors.greyColor,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  
                  // Price Section
                  Row(
                    children: [
                      Text(
                        '\₹${_getCurrentPrice()}',
                        style: GoogleFonts.poppins(
                          fontSize: 28.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor,
                        ),
                      ),
                      if (_hasDiscount()) ...[
                        SizedBox(width: 12.w),
                        Text(
                          '\$${_getOriginalPrice()}',
                          style: GoogleFonts.poppins(
                            fontSize: 18.sp,
                            color: AppColors.greyColor,
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 24.h),
                  
                  // Description
                  if (widget.product['desc'] != null) ...[
                    Text(
                      'Description',
                      style: GoogleFonts.poppins(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.blackColor,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      widget.product['desc'],
                      style: GoogleFonts.poppins(
                        fontSize: 14.sp,
                        color: AppColors.greyColor,
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 24.h),
                  ],
                  
                  // Size Selection (if applicable)
                  if (widget.product['sizes'] != null) ...[
                    Text(
                      'Select Size',
                      style: GoogleFonts.poppins(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.blackColor,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Wrap(
                      spacing: 12.w,
                      children: (widget.product['sizes'] as List).map<Widget>((size) {
                        final sizeStr = size.toString();
                        final isSelected = _selectedSize == sizeStr;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedSize = sizeStr;
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primaryColor : Colors.transparent,
                              border: Border.all(
                                color: isSelected ? AppColors.primaryColor : AppColors.greyColor,
                              ),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Text(
                              sizeStr,
                              style: GoogleFonts.poppins(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                                color: isSelected ? Colors.white : AppColors.blackColor,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 24.h),
                  ],
                  
                  // Quantity Selection
                  Text(
                    'Quantity',
                    style: GoogleFonts.poppins(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.blackColor,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          if (_quantity > 1) {
                            setState(() {
                              _quantity--;
                            });
                          }
                        },
                        icon: Icon(
                          Icons.remove_circle_outline,
                          color: _quantity > 1 ? AppColors.primaryColor : Colors.grey,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.greyColor),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          '$_quantity',
                          style: GoogleFonts.poppins(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _quantity++;
                          });
                        },
                        icon: Icon(
                          Icons.add_circle_outline,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24.h),
                  
                  // Color Selection (if applicable)
                  if (widget.product['colors'] != null) ...[
                    Text(
                      'Select Color',
                      style: GoogleFonts.poppins(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.blackColor,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Wrap(
                      spacing: 12.w,
                      children: (widget.product['colors'] as List).map<Widget>((color) {
                        return Container(
                          width: 40.w,
                          height: 40.h,
                          decoration: BoxDecoration(
                            color: _parseColor(color),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 24.h),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Consumer2<AuthService, CartService>(
          builder: (context, authService, cartService, child) {
            return Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _addToCart(cartService),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: cartService.isLoading
                        ? SizedBox(
                            width: 20.w,
                            height: 20.h,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Add to Cart',
                            style: GoogleFonts.poppins(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _buyNow(cartService),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.blackColor,
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: Text(
                      'Buy Now',
                      style: GoogleFonts.poppins(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  bool _hasDiscount() {
    final originalPrice = widget.product['originalPrice'];
    final currentPrice = widget.product['price'];
    return originalPrice != null && 
           currentPrice != null && 
           originalPrice is num &&
           currentPrice is num &&
           originalPrice > currentPrice;
  }

  String _getCurrentPrice() {
    final price = widget.product['price'];
    if (price == null) return '0.00';
    return (price is num ? price : 0.0).toStringAsFixed(2);
  }

  String _getOriginalPrice() {
    final originalPrice = widget.product['originalPrice'];
    if (originalPrice == null) return '0.00';
    return (originalPrice is num ? originalPrice : 0.0).toStringAsFixed(2);
  }

  String _getDiscountPercentage() {
    final originalPrice = widget.product['originalPrice'];
    final currentPrice = widget.product['price'];
    
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

  Color _parseColor(dynamic color) {
    if (color is String) {
      switch (color.toLowerCase()) {
        case 'red': return Colors.red;
        case 'blue': return Colors.blue;
        case 'green': return Colors.green;
        case 'yellow': return Colors.yellow;
        case 'black': return Colors.black;
        case 'white': return Colors.white;
        case 'grey':
        case 'gray': return Colors.grey;
        default: return Colors.grey;
      }
    }
    return Colors.grey;
  }

  void _addToCart(CartService cartService) {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    print('Auth check - isAuthenticated: ${authService.isAuthenticated}');
    print('Auth check - currentUser: ${authService.currentUser}');
    print('Auth check - authToken: ${authService.authToken}');
    
    if (!authService.isAuthenticated) {
      print('User not authenticated, showing sign in sheet');
      showSignInBottomSheet(context);
      return;
    }

    print('Adding to cart - Product ID: ${widget.product['id']}');
    print('Adding to cart - Quantity: $_quantity');
    print('Adding to cart - Size: $_selectedSize');

    cartService.addToCart(
      productId: widget.product['id'].toString(),
      quantity: _quantity,
      size: _selectedSize,
    ).then((result) {
      print('Add to cart result: $result');
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Added to cart successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] ?? 'Failed to add to cart')),
        );
      }
    }).catchError((error) {
      print('Add to cart error: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    });
  }

  void _buyNow(CartService cartService) {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    if (!authService.isAuthenticated) {
      showSignInBottomSheet(context);
      return;
    }

    print('Buy now - Product ID: ${widget.product['id']}');
    print('Buy now - Quantity: $_quantity');
    print('Buy now - Size: $_selectedSize');

    // First add to cart, then navigate to checkout
    cartService.addToCart(
      productId: widget.product['id'].toString(),
      quantity: _quantity,
      size: _selectedSize,
    ).then((result) {
      print('Buy now result: $result');
      if (result['success']) {
        // Navigate to checkout page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CheckoutPage(),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] ?? 'Failed to add to cart')),
        );
      }
    }).catchError((error) {
      print('Buy now error: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    });
  }
} 