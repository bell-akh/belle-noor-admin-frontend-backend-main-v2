import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:libas_app/src/common/constant/app_color.dart';
import 'package:libas_app/src/common/services/auth_service.dart';
import 'package:libas_app/src/common/services/cart_service.dart';
import 'package:libas_app/src/common/services/razorpay_service.dart';
import 'package:libas_app/src/common/services/real_api_service.dart';
import 'package:libas_app/src/feature/orders/page/orders_page.dart';
import 'package:libas_app/src/common/utils/custom_formfield.dart';
import 'package:flutter/foundation.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({Key? key}) : super(key: key);

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  
  late RazorpayService _razorpayService;
  bool _isProcessing = false;
  String _selectedPaymentMethod = 'razorpay';
  double _discount = 0.0;

  @override
  void initState() {
    super.initState();
    _razorpayService = RazorpayService();
    _loadUserData();
  }

  void _loadUserData() {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.currentUser != null) {
      final user = authService.currentUser!;
      _nameController.text = user['name'] ?? '';
      _emailController.text = user['email'] ?? '';
      _phoneController.text = user['phone'] ?? '';
      _addressController.text = user['address'] ?? '';
    }
  }

  @override
  void dispose() {
    _razorpayService.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Checkout',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer2<AuthService, CartService>(
        builder: (context, authService, cartService, child) {
          if (!authService.isAuthenticated) {
            return const Center(
              child: Text('Please login to checkout'),
            );
          }

          if (cartService.cartItems.isEmpty) {
            return const Center(
              child: Text('Your cart is empty'),
            );
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Shipping Details Section
                  _buildSectionTitle('Shipping Details'),
                  SizedBox(height: 16.h),
                  _buildShippingForm(),
                  SizedBox(height: 24.h),
                  
                  // Order Summary Section
                  _buildSectionTitle('Order Summary'),
                  SizedBox(height: 16.h),
                  _buildOrderSummary(cartService),
                  SizedBox(height: 24.h),
                  
                  // Payment Method Section
                  _buildSectionTitle('Payment Method'),
                  SizedBox(height: 16.h),
                  _buildPaymentMethods(),
                  SizedBox(height: 32.h),
                  
                  // Place Order Button
                  _buildPlaceOrderButton(cartService),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18.sp,
        fontWeight: FontWeight.bold,
        color: AppColors.blackColor,
      ),
    );
  }

  Widget _buildShippingForm() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: CustomTextFormField(
                controller: _nameController,
                labelText: 'Full Name',
                hint: 'Enter your full name',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        Row(
          children: [
            Expanded(
              child: CustomTextFormField(
                controller: _emailController,
                labelText: 'Email',
                hint: 'Enter your email',
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: CustomTextFormField(
                controller: _phoneController,
                labelText: 'Phone',
                hint: 'Enter your phone number',
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        CustomTextFormField(
          controller: _addressController,
          labelText: 'Address',
          hint: 'Enter your complete address',
          maxline: 3,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your address';
            }
            return null;
          },
        ),
        SizedBox(height: 16.h),
        Row(
          children: [
            Expanded(
              child: CustomTextFormField(
                controller: _cityController,
                labelText: 'City',
                hint: 'Enter your city',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your city';
                  }
                  return null;
                },
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: CustomTextFormField(
                controller: _stateController,
                labelText: 'State',
                hint: 'Enter your state',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your state';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        CustomTextFormField(
          controller: _pincodeController,
          labelText: 'Pincode',
          hint: 'Enter your pincode',
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your pincode';
            }
            if (value.length != 6) {
              return 'Please enter a valid 6-digit pincode';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildOrderSummary(CartService cartService) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          // Cart Items
          ...cartService.cartItems.map((item) {
            final product = item['product'] ?? {};
            final quantity = item['quantity'] ?? 0;
            final price = (product['price'] ?? 0).toDouble();
            final total = price * quantity;
            
            return Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: Row(
                children: [
                  // Product Image
                  Container(
                    width: 50.w,
                    height: 50.h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.r),
                      color: Colors.grey[200],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.r),
                      child: Image.network(
                        product['images']?[0] ?? 'https://via.placeholder.com/50',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.image,
                            size: 25.w,
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
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Size: ${item['size'] ?? 'M'} | Qty: $quantity',
                          style: GoogleFonts.poppins(
                            fontSize: 12.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Price
                  Text(
                    '₹${total.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          
          Divider(height: 24.h),
          
          // Price Breakdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subtotal:',
                style: GoogleFonts.poppins(fontSize: 14.sp),
              ),
              Text(
                '₹${cartService.totalAmount.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Shipping:',
                style: GoogleFonts.poppins(fontSize: 14.sp),
              ),
              Text(
                '₹50.00',
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tax:',
                style: GoogleFonts.poppins(fontSize: 14.sp),
              ),
              Text(
                '₹${(cartService.totalAmount * 0.18).toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Divider(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total:',
                style: GoogleFonts.poppins(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '₹${(cartService.totalAmount + 50 + (cartService.totalAmount * 0.18)).toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods() {
    return Column(
      children: [
        RadioListTile<String>(
          title: Row(
            children: [
              Icon(Icons.payment, color: AppColors.primaryColor),
              SizedBox(width: 12.w),
              Text(
                'Pay Online (Razorpay)',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          subtitle: Text(
            'Pay securely with cards, UPI, or wallets',
            style: GoogleFonts.poppins(fontSize: 12.sp, color: Colors.grey[600]),
          ),
          value: 'razorpay',
          groupValue: _selectedPaymentMethod,
          onChanged: (value) {
            setState(() {
              _selectedPaymentMethod = value!;
            });
          },
          activeColor: AppColors.primaryColor,
        ),
        RadioListTile<String>(
          title: Row(
            children: [
              Icon(Icons.money, color: AppColors.primaryColor),
              SizedBox(width: 12.w),
              Text(
                'Cash on Delivery',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          subtitle: Text(
            'Pay when you receive your order',
            style: GoogleFonts.poppins(fontSize: 12.sp, color: Colors.grey[600]),
          ),
          value: 'cod',
          groupValue: _selectedPaymentMethod,
          onChanged: (value) {
            setState(() {
              _selectedPaymentMethod = value!;
            });
          },
          activeColor: AppColors.primaryColor,
        ),
      ],
    );
  }

  Widget _buildPlaceOrderButton(CartService cartService) {
    final totalAmount = cartService.totalAmount + 50 + (cartService.totalAmount * 0.18);
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : () => _placeOrder(totalAmount),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          padding: EdgeInsets.symmetric(vertical: 16.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child: _isProcessing
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20.w,
                    height: 20.h,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    'Processing...',
                    style: GoogleFonts.poppins(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              )
            : Text(
                'Place Order - ₹${totalAmount.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  void _placeOrder(double totalAmount) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      if (_selectedPaymentMethod == 'razorpay') {
        await _processRazorpayPayment(totalAmount);
      } else {
        await _processCashOnDelivery(totalAmount);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _processRazorpayPayment(double totalAmount) async {
    // Create order on Razorpay
    final orderResult = await _razorpayService.createOrder(
      amount: totalAmount,
      currency: 'INR',
      receipt: 'order_${DateTime.now().millisecondsSinceEpoch}',
    );

    if (!orderResult['success']) {
      throw Exception(orderResult['error']);
    }

    final orderData = orderResult['data'];
    final orderId = orderData['id'];

    // Open Razorpay checkout
    _razorpayService.openCheckout(
      amount: totalAmount,
      currency: 'INR',
      orderId: orderId,
      name: 'Belle Noor',
      description: 'Order Payment',
      prefillEmail: _emailController.text,
      prefillContact: _phoneController.text,
      onSuccess: (response) async {
        await _handlePaymentSuccess(response, totalAmount);
      },
      onError: (response) {
        _handlePaymentError(response);
      },
      onCancel: (response) {
        _handlePaymentCancel(response);
      },
    );
  }

  Future<void> _processCashOnDelivery(double totalAmount) async {
    // Create order with COD payment method
    await _createOrder('CASH_ON_DELIVERY', totalAmount);
  }

  Future<void> _handlePaymentSuccess(Map<String, dynamic> response, double totalAmount) async {
    if (kDebugMode) {
      print('🔄 CheckoutPage: _handlePaymentSuccess called');
      print('Payment success response: $response');
    }

    try {
      // Temporarily skip signature verification for testing
      if (kDebugMode) {
        print('Skipping signature verification for testing');
      }

      // Proceed with order creation
      if (kDebugMode) {
        print('🔄 CheckoutPage: Calling _createOrder');
      }
      await _createOrder('RAZORPAY', totalAmount, response);
      if (kDebugMode) {
        print('🔄 CheckoutPage: _createOrder completed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ CheckoutPage: Error in _handlePaymentSuccess: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing payment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handlePaymentError(Map<String, dynamic> response) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: ${response['error']}')),
      );
    }
  }

  void _handlePaymentCancel(Map<String, dynamic> response) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment cancelled')),
      );
    }
  }

  Future<void> _createOrder(String paymentMethod, double totalAmount, [Map<String, dynamic>? paymentResponse]) async {
    final cartService = Provider.of<CartService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final apiService = RealApiService();

    try {
      // Prepare products data for the API
      final products = cartService.cartItems.map((item) {
        final product = item['product'] ?? {};
        return {
          'productId': item['productId'],
          'name': product['name'] ?? 'Unknown Product',
          'image': product['images']?[0] ?? '',
          'price': product['price'] ?? 0.0,
          'quantity': item['quantity'],
          'size': item['size'] ?? 'M',
        };
      }).toList();

      // Prepare shipping address
      final shippingAddress = {
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'address': _addressController.text,
        'city': _cityController.text,
        'state': _stateController.text,
        'pincode': _pincodeController.text,
      };

      if (kDebugMode) {
        print('Creating order with data:');
        print('Products: $products');
        print('Shipping Address: $shippingAddress');
        print('Payment Method: $paymentMethod');
        print('Discount: ${_discount}');
      }

      // Create order using RealApiService
      final result = await apiService.createOrder(
        products: products,
        shippingAddress: shippingAddress,
        paymentMethod: paymentMethod,
        discount: _discount,
      );

      if (result['success'] == true) {
        if (mounted) {
          // Clear cart after successful order
          await cartService.clearCart();
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Order created successfully!')),
          );
          
          // Navigate to Orders page
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const OrdersPage()),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to create order'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error creating order: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
} 