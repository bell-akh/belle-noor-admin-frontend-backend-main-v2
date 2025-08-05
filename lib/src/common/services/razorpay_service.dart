import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' show utf8, base64Encode, json;
import 'package:razorpay_flutter/razorpay_flutter.dart';

class RazorpayService {
  // Test keys - replace with live keys for production
  static const String _razorpayKey = 'rzp_test_CeAT7DBb7Kk8Mk';
  static const String _razorpaySecret = 'Rk5ScMbQiCRZ28pftFF07gv7';

  // static const String _razorpayKey = 'rzp_live_ZgwEBPv4n5VOsS';
  // static const String _razorpaySecret = 'L9Vx3aQk4yyId9SAae03yvrB';
  
  // Live keys (uncomment for production)
  // static const String _razorpayKey = 'rzp_live_ZgwEBPv4n5VOsS';
  // static const String _razorpaySecret = 'L9Vx3aQk4yyId9SAae03yvrB';

  late Razorpay _razorpay;
  Function(Map<String, dynamic>)? _onPaymentSuccess;
  Function(Map<String, dynamic>)? _onPaymentError;
  // Function(Map<String, dynamic>)? _onPaymentCancel; // Unused for now

  RazorpayService() {
    _initializeRazorpay();
  }

  void _initializeRazorpay() {
    try {
      _razorpay = Razorpay();
      _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
      _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
      _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    } catch (e) {
      if (kDebugMode) {
        print('Razorpay initialization error: $e');
      }
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    if (kDebugMode) {
      print('Payment success: ${response.data}');
    }
    // Convert PaymentSuccessResponse to Map<String, dynamic>
    final responseMap = {
      'razorpay_payment_id': response.data?['razorpay_payment_id'],
      'razorpay_order_id': response.data?['razorpay_order_id'],
      'razorpay_signature': response.data?['razorpay_signature'],
    };

    if (kDebugMode) {
      print('Calling payment success callback with: $responseMap');
      print('Callback is null: ${_onPaymentSuccess == null}');
    }

    _onPaymentSuccess?.call(responseMap);

    if (kDebugMode) {
      print('Payment success callback completed');
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (kDebugMode) {
      print('Payment error: ${response.message}');
    }
    // Convert PaymentFailureResponse to Map<String, dynamic>
    final responseMap = {
      'error': response.message,
      'code': response.code,
    };
    _onPaymentError?.call(responseMap);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (kDebugMode) {
      print('External wallet: ${response.walletName}');
    }
  }

  // Open checkout for payment
  void openCheckout({
    required double amount,
    required String currency,
    required String orderId,
    required String name,
    required String description,
    required String prefillEmail,
    required String prefillContact,
    Function(Map<String, dynamic>)? onSuccess,
    Function(Map<String, dynamic>)? onError,
    Function(Map<String, dynamic>)? onCancel,
  }) {
    _onPaymentSuccess = onSuccess;
    _onPaymentError = onError;
    // _onPaymentCancel = onCancel; // Unused for now

    final options = {
      'key': _razorpayKey,
      'amount': (amount * 100).toInt(), // Convert to paise
      'currency': currency,
      'name': name,
      'description': description,
      'order_id': orderId,
      'prefill': {
        'email': prefillEmail,
        'contact': prefillContact,
      },
      'theme': {
        'color': '#3399cc',
      },
    };

    try {
      _razorpay.open(options);
      if (kDebugMode) {
        print('Razorpay checkout options: $options');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Razorpay checkout error: $e');
      }
      // Create a mock PaymentFailureResponse for the error
      final errorResponse = PaymentFailureResponse(
        1, // code (int)
        e.toString(), // message
        null, // error parameter
      );
      _handlePaymentError(errorResponse);
    }
  }

  // Create order on Razorpay
  Future<Map<String, dynamic>> createOrder({
    required double amount,
    required String currency,
    required String receipt,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.razorpay.com/v1/orders'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic ${base64Encode(utf8.encode('$_razorpayKey:$_razorpaySecret'))}',
        },
        body: json.encode({
          'amount': (amount * 100).toInt(), // Convert to paise
          'currency': currency,
          'receipt': receipt,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'data': data};
      } else {
        final error = json.decode(response.body);
        return {'success': false, 'error': error['error'] ?? 'Failed to create order'};
      }
    } catch (e) {
      if (kDebugMode) {
        print('Create order error: $e');
      }
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Verify payment signature
  Future<bool> verifyPaymentSignature({
    required String paymentId,
    required String orderId,
    required String signature,
  }) async {
    try {
      final text = '$orderId|$paymentId';
      final expectedSignature = base64Encode(utf8.encode(text));
      return signature == expectedSignature;
    } catch (e) {
      if (kDebugMode) {
        print('Verify signature error: $e');
      }
      return false;
    }
  }

  // Capture payment
  Future<Map<String, dynamic>> capturePayment({
    required String paymentId,
    required double amount,
    required String currency,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.razorpay.com/v1/payments/$paymentId/capture'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic ${base64Encode(utf8.encode('$_razorpayKey:$_razorpaySecret'))}',
        },
        body: json.encode({
          'amount': (amount * 100).toInt(), // Convert to paise
          'currency': currency,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'data': data};
      } else {
        final error = json.decode(response.body);
        return {'success': false, 'error': error['error'] ?? 'Failed to capture payment'};
      }
    } catch (e) {
      if (kDebugMode) {
        print('Capture payment error: $e');
      }
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Refund payment
  Future<Map<String, dynamic>> refundPayment({
    required String paymentId,
    double? amount,
    String? speed,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (amount != null) body['amount'] = (amount * 100).toInt();
      if (speed != null) body['speed'] = speed;

      final response = await http.post(
        Uri.parse('https://api.razorpay.com/v1/payments/$paymentId/refund'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic ${base64Encode(utf8.encode('$_razorpayKey:$_razorpaySecret'))}',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'data': data};
      } else {
        final error = json.decode(response.body);
        return {'success': false, 'error': error['error'] ?? 'Failed to refund payment'};
      }
    } catch (e) {
      if (kDebugMode) {
        print('Refund payment error: $e');
      }
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Get payment details
  Future<Map<String, dynamic>> getPaymentDetails(String paymentId) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.razorpay.com/v1/payments/$paymentId'),
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode('$_razorpayKey:$_razorpaySecret'))}',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'data': data};
      } else {
        final error = json.decode(response.body);
        return {'success': false, 'error': error['error'] ?? 'Failed to get payment details'};
      }
    } catch (e) {
      if (kDebugMode) {
        print('Get payment details error: $e');
      }
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  void dispose() {
    try {
      _razorpay.clear();
    } catch (e) {
      if (kDebugMode) {
        print('Razorpay dispose error: $e');
      }
    }
  }
} 