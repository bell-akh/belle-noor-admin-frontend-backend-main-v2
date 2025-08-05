import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:libas_app/src/common/constant/app_color.dart';
import 'package:libas_app/src/common/services/auth_service.dart';
import 'package:libas_app/src/common/services/cart_service.dart';
import 'package:libas_app/src/common/widgets/sign_in_bottom_sheet.dart';
import 'package:libas_app/src/feature/checkout/page/checkout_page.dart';

class CartPage extends StatefulWidget {
  const CartPage({Key? key}) : super(key: key);

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthAndLoadCart();
    });
  }

  void _checkAuthAndLoadCart() {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (!authService.isAuthenticated) {
      _showAuthRequiredDialog();
      return;
    }
    
    // Load cart data
    final cartService = Provider.of<CartService>(context, listen: false);
    cartService.getCart();
  }

  void _showAuthRequiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          'Authentication Required',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Please login to view your cart.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              showSignInBottomSheet(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
            ),
            child: Text(
              'Login',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthService, CartService>(
      builder: (context, authService, cartService, child) {
        if (!authService.isAuthenticated) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                'Cart',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 80.w,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Please login to view your cart',
                    style: GoogleFonts.poppins(
                      fontSize: 18.sp,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 24.h),
                  ElevatedButton(
                    onPressed: () => showSignInBottomSheet(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 12.h),
                    ),
                    child: Text(
                      'Login Now',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Cart (${cartService.itemCount})',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppColors.primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              IconButton(
                onPressed: () => cartService.getCart(),
                icon: const Icon(Icons.refresh),
              ),
              if (cartService.itemCount > 0)
                IconButton(
                  onPressed: () => _showClearCartDialog(),
                  icon: const Icon(Icons.delete_sweep),
                ),
            ],
          ),
          body: cartService.isLoading
              ? const Center(child: CircularProgressIndicator())
              : cartService.cartItems.isEmpty
                  ? _buildEmptyCart()
                  : _buildCartItems(cartService),
          bottomNavigationBar: cartService.cartItems.isNotEmpty
              ? _buildBottomBar(cartService)
              : null,
        );
      },
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80.w,
            color: Colors.grey,
          ),
          SizedBox(height: 16.h),
          Text(
            'Your cart is empty',
            style: GoogleFonts.poppins(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Add some products to get started',
            style: GoogleFonts.poppins(
              fontSize: 16.sp,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 24.h),
          ElevatedButton(
            onPressed: () {
              // Navigate to products page
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 12.h),
            ),
            child: Text(
              'Start Shopping',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItems(CartService cartService) {
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: cartService.cartItems.length,
      itemBuilder: (context, index) {
        final item = cartService.cartItems[index];
        final product = item['product'] ?? {};
        
        return Container(
          margin: EdgeInsets.only(bottom: 16.h),
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
          child: Padding(
            padding: EdgeInsets.all(12.w),
            child: Row(
              children: [
                // Product Image
                Container(
                  width: 80.w,
                  height: 80.h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.r),
                    color: Colors.grey[200],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.r),
                    child: Image.network(
                      product['images']?[0] ?? 'https://via.placeholder.com/80',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.image,
                          size: 40.w,
                          color: Colors.grey[400],
                        );
                      },
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                
                // Product Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['name'] ?? 'Unknown Product',
                        style: GoogleFonts.poppins(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Size: ${item['size'] ?? 'M'}',
                        style: GoogleFonts.poppins(
                          fontSize: 14.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        '₹${(product['price'] ?? 0).toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Quantity Controls
                Column(
                  children: [
                    // Remove button
                    IconButton(
                      onPressed: () => _removeItem(item['id']),
                      icon: Icon(
                        Icons.delete_outline,
                        color: Colors.red[400],
                        size: 20.w,
                      ),
                    ),
                    
                    // Quantity controls
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => _decreaseQuantity(item['id']),
                          icon: Icon(
                            Icons.remove_circle_outline,
                            color: AppColors.primaryColor,
                            size: 20.w,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w),
                          child: Text(
                            '${item['quantity']}',
                            style: GoogleFonts.poppins(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => _increaseQuantity(item['id']),
                          icon: Icon(
                            Icons.add_circle_outline,
                            color: AppColors.primaryColor,
                            size: 20.w,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomBar(CartService cartService) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total (${cartService.totalQuantity} items):',
                  style: GoogleFonts.poppins(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '₹${cartService.totalAmount.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            
            // Checkout button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _proceedToCheckout(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text(
                  'Proceed to Checkout',
                  style: GoogleFonts.poppins(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _removeItem(String itemId) {
    final cartService = Provider.of<CartService>(context, listen: false);
    cartService.removeFromCart(itemId).then((result) {
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Item removed from cart')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] ?? 'Failed to remove item')),
        );
      }
    });
  }

  void _increaseQuantity(String itemId) {
    final cartService = Provider.of<CartService>(context, listen: false);
    cartService.increaseQuantity(itemId).then((result) {
      if (!result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] ?? 'Failed to update quantity')),
        );
      }
    });
  }

  void _decreaseQuantity(String itemId) {
    final cartService = Provider.of<CartService>(context, listen: false);
    cartService.decreaseQuantity(itemId).then((result) {
      if (!result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] ?? 'Failed to update quantity')),
        );
      }
    });
  }

  void _showClearCartDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Clear Cart',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to remove all items from your cart?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _clearCart();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(
              'Clear',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _clearCart() {
    final cartService = Provider.of<CartService>(context, listen: false);
    cartService.clearCart().then((result) {
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cart cleared successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] ?? 'Failed to clear cart')),
        );
      }
    });
  }

  void _proceedToCheckout() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CheckoutPage(),
      ),
    );
  }
} 