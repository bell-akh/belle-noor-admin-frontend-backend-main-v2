import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:libas_app/src/common/services/real_api_service.dart';
import 'package:libas_app/src/common/services/data_change_service.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({Key? key}) : super(key: key);

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  String? _error;
  final RealApiService _apiService = RealApiService();
  final DataChangeService _dataChangeService = DataChangeService();
  Set<String> _expandedOrders = {};
  StreamSubscription<Map<String, dynamic>>? _orderChangeSubscription;

  @override
  void initState() {
    super.initState();
    _loadOrders();
    _setupOrderChangeListener();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (kDebugMode) {
        print('🔄 OrdersPage: Loading orders...');
        print('🔄 OrdersPage: Making API call to getUserOrders with forceRefresh: true');
      }
      
      // Force refresh to get latest data
      final orders = await _apiService.getUserOrders(forceRefresh: true);
      
      if (kDebugMode) {
        print('🔄 OrdersPage: API call completed successfully');
        print('🔄 OrdersPage: Loaded ${orders.length} orders');
        print('🔄 OrdersPage: Full orders data:');
        for (int i = 0; i < orders.length; i++) {
          final order = orders[i];
          print('  Order ${i + 1}:');
          print('    ID: ${order['id']}');
          print('    Status: "${order['status']}"');
          print('    Payment Status: "${order['paymentStatus']}"');
          print('    Total: ${order['total']}');
          print('    Created At: ${order['createdAt']}');
          print('    Updated At: ${order['updatedAt']}');
          print('    Payment Method: ${order['paymentMethod']}');
          print('    Products Count: ${(order['products'] as List?)?.length ?? 0}');
          if (order['shippingAddress'] != null) {
            print('    Shipping Address: ${order['shippingAddress']}');
          }
          print('    ---');
        }
      }
      
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ OrdersPage: Error loading orders: $e');
        print('❌ OrdersPage: Error stack trace: ${StackTrace.current}');
      }
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _getStatusText(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'Pending';
      case 'FULFILLED':
        return 'Fulfilled';
      case 'CANCELLED':
        return 'Cancelled';
      case 'REFUND_RAISED':
        return 'Refund Requested';
      case 'REFUND_ISSUED':
        return 'Refund Issued';
      default:
        return status;
    }
  }

  String _getPaymentStatusText(String paymentStatus) {
    switch (paymentStatus.toUpperCase()) {
      case 'PENDING':
        return 'Payment Pending';
      case 'PAID':
        return 'Payment Completed';
      case 'FAILED':
        return 'Payment Failed';
      case 'REFUNDED':
        return 'Payment Refunded';
      default:
        return paymentStatus;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Colors.orange;
      case 'FULFILLED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      case 'REFUND_RAISED':
        return Colors.purple;
      case 'REFUND_ISSUED':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color _getPaymentStatusColor(String paymentStatus) {
    switch (paymentStatus.toUpperCase()) {
      case 'PENDING':
        return Colors.orange;
      case 'PAID':
        return Colors.green;
      case 'FAILED':
        return Colors.red;
      case 'REFUNDED':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  bool _canCancelOrder(String status) {
    return status.toUpperCase() == 'PENDING';
  }

  bool _canRequestRefund(String status) {
    return status.toUpperCase() == 'FULFILLED';
  }

  bool _isActionDisabled(String status) {
    return status.toUpperCase() == 'CANCELLED' || 
           status.toUpperCase() == 'REFUND_RAISED' || 
           status.toUpperCase() == 'REFUND_ISSUED';
  }

  Future<void> _cancelOrder(String orderId) async {
    try {
      final result = await _apiService.cancelOrder(orderId);
      
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Order cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadOrders(); // Refresh the orders list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to cancel order'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error cancelling order: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _requestRefund(String orderId) async {
    try {
      final result = await _apiService.requestRefund(orderId);
      
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Refund requested successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadOrders(); // Refresh the orders list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to request refund'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error requesting refund: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _setupOrderChangeListener() {
    _orderChangeSubscription = _dataChangeService.orderChanges.listen((event) {
      if (kDebugMode) {
        print('🔄 OrdersPage: Order change detected, refreshing orders');
      }
      _loadOrders();
    });
  }

  @override
  void dispose() {
    _orderChangeSubscription?.cancel();
    super.dispose();
  }

  void _toggleOrderDetails(String orderId) {
    setState(() {
      if (_expandedOrders.contains(orderId)) {
        _expandedOrders.remove(orderId);
      } else {
        _expandedOrders.add(orderId);
      }
    });
  }

  Widget _buildOrderDetails(Map<String, dynamic> order) {
    final products = List<Map<String, dynamic>>.from(order['products'] ?? []);
    final shippingAddress = order['shippingAddress'] ?? {};
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 8),
        
        // Shipping Address
        const Text(
          'Shipping Address:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text('${shippingAddress['name'] ?? 'N/A'}'),
        Text('${shippingAddress['email'] ?? 'N/A'}'),
        Text('${shippingAddress['phone'] ?? 'N/A'}'),
        Text('${shippingAddress['address'] ?? 'N/A'}'),
        Text('${shippingAddress['city'] ?? 'N/A'}, ${shippingAddress['state'] ?? 'N/A'} - ${shippingAddress['pincode'] ?? 'N/A'}'),
        
        const SizedBox(height: 12),
        
        // Order Details
        const Text(
          'Order Details:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text('Order ID: ${order['id']}'),
        Text('Payment Method: ${order['paymentMethod'] ?? 'N/A'}'),
        if (order['couponCode'] != null) Text('Coupon Code: ${order['couponCode']}'),
        if (order['discount'] != null && order['discount'] > 0) 
          Text('Discount: ₹${order['discount'].toStringAsFixed(2)}'),
        Text('Original Total: ₹${order['originalTotal']?.toStringAsFixed(2) ?? '0.00'}'),
        Text('Final Total: ₹${order['total']?.toStringAsFixed(2) ?? '0.00'}'),
        
        const SizedBox(height: 12),
        
        // Products
        const Text(
          'Products:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        ...products.map((product) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              if (product['image'] != null && product['image'].isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    product['image'],
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 50,
                      height: 50,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image, color: Colors.grey),
                    ),
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['name'] ?? 'Unknown Product',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      'Size: ${product['size'] ?? 'M'} | Qty: ${product['quantity']}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      '₹${product['total']?.toStringAsFixed(2) ?? '0.00'}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )),
        
        // Refund information if applicable
        if (order['status'] == 'REFUND_RAISED' || order['status'] == 'REFUND_ISSUED') ...[
          const SizedBox(height: 12),
          const Text(
            'Refund Information:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          if (order['refundReason'] != null) Text('Reason: ${order['refundReason']}'),
          if (order['refundAmount'] != null) Text('Refund Amount: ₹${order['refundAmount'].toStringAsFixed(2)}'),
          if (order['refundMethod'] != null) Text('Refund Method: ${order['refundMethod']}'),
          if (order['refundIssuedAt'] != null) Text('Refund Date: ${DateTime.fromMillisecondsSinceEpoch(order['refundIssuedAt']).toString().split(' ')[0]}'),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error: $_error',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadOrders,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _orders.isEmpty
                  ? const Center(
                      child: Text(
                        'No orders found',
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadOrders,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _orders.length,
                        itemBuilder: (context, index) {
                          final order = _orders[index];
                          final orderId = order['id']?.toString() ?? '';
                          final isExpanded = _expandedOrders.contains(orderId);
                          final status = order['status']?.toString() ?? 'PENDING';
                          

                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Order #${orderId.substring(0, orderId.length > 8 ? 8 : orderId.length)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(status),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              _getStatusText(status),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getPaymentStatusColor(order['paymentStatus'] ?? 'PENDING'),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              _getPaymentStatusText(order['paymentStatus'] ?? 'PENDING'),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Total: ₹${order['total']?.toStringAsFixed(2) ?? '0.00'}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Date: ${DateTime.fromMillisecondsSinceEpoch(order['createdAt'] ?? 0).toString().split(' ')[0]}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  
                                  // Expandable details section
                                  if (isExpanded) _buildOrderDetails(order),
                                  
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () => _toggleOrderDetails(orderId),
                                          child: Text(isExpanded ? 'Hide Details' : 'View Details'),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Builder(
                                        builder: (context) {
                                          
                                          if (_canCancelOrder(status)) {
                                            return Expanded(
                                              child: ElevatedButton(
                                                onPressed: () => _cancelOrder(orderId),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.red,
                                                  foregroundColor: Colors.white,
                                                ),
                                                child: const Text('Cancel'),
                                              ),
                                            );
                                          } else if (_canRequestRefund(status)) {
                                            return Expanded(
                                              child: ElevatedButton(
                                                onPressed: () => _requestRefund(orderId),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.orange,
                                                  foregroundColor: Colors.white,
                                                ),
                                                child: const Text('Request Refund'),
                                              ),
                                            );
                                          } else if (_isActionDisabled(status)) {
                                            return Expanded(
                                              child: ElevatedButton(
                                                onPressed: null,
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.grey,
                                                  foregroundColor: Colors.white,
                                                ),
                                                child: Text(status.toUpperCase() == 'CANCELLED' ? 'Cancelled' : 'Refund ${status.split('_').last.toLowerCase()}'),
                                              ),
                                            );
                                          } else {
                                            // Fallback for unexpected status
                                            return Expanded(
                                              child: ElevatedButton(
                                                onPressed: null,
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.grey,
                                                  foregroundColor: Colors.white,
                                                ),
                                                child: Text('Status: $status'),
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
} 