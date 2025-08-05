import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:libas_app/src/common/constant/app_color.dart';
import 'package:libas_app/src/common/services/data_change_service.dart';
import 'package:libas_app/src/common/services/real_api_service.dart';

class RealtimeDataManager extends StatefulWidget {
  final Widget child;
  final Function(Map<String, dynamic>)? onDataChange;

  const RealtimeDataManager({
    Key? key,
    required this.child,
    this.onDataChange,
  }) : super(key: key);

  @override
  State<RealtimeDataManager> createState() => _RealtimeDataManagerState();
}

class _RealtimeDataManagerState extends State<RealtimeDataManager> {
  final RealApiService _apiService = RealApiService();
  StreamSubscription<Map<String, dynamic>>? _productSubscription;
  StreamSubscription<Map<String, dynamic>>? _categorySubscription;
  StreamSubscription<Map<String, dynamic>>? _bannerSubscription;

  @override
  void initState() {
    super.initState();
    _listenToDataChanges();
  }

  void _listenToDataChanges() {
    final dataChangeService = _apiService.dataChangeService;
    if (dataChangeService == null) {
      if (kDebugMode) {
        print('❌ DataChangeService not available in RealtimeDataManager');
      }
      return;
    }

    // Listen to product changes
    _productSubscription = dataChangeService.productChanges.listen((event) {
      if (widget.onDataChange != null) {
        widget.onDataChange!(event);
      }
      _showDataChangeNotification(event, 'product');
    });

    // Listen to category changes
    _categorySubscription = dataChangeService.categoryChanges.listen((event) {
      if (widget.onDataChange != null) {
        widget.onDataChange!(event);
      }
      _showDataChangeNotification(event, 'category');
    });

    // Listen to banner changes
    _bannerSubscription = dataChangeService.bannerChanges.listen((event) {
      if (widget.onDataChange != null) {
        widget.onDataChange!(event);
      }
      _showDataChangeNotification(event, 'banner');
    });
  }

  void _showDataChangeNotification(Map<String, dynamic> event, String type) {
    String message = '';
    Color backgroundColor = AppColors.primaryColor;
    
    final eventType = event['type']?.toString().toLowerCase() ?? '';
    
    switch (type) {
      case 'category':
        switch (eventType) {
          case 'category_added':
          case 'category_created':
            message = 'New category added: ${event['data']?['name'] ?? 'Unknown'}';
            backgroundColor = Colors.green;
            break;
          case 'category_updated':
            message = 'Category updated: ${event['data']?['name'] ?? 'Unknown'}';
            backgroundColor = Colors.blue;
            break;
          case 'category_removed':
          case 'category_deleted':
            message = 'Category removed';
            backgroundColor = Colors.orange;
            break;
        }
        break;
      case 'product':
        switch (eventType) {
          case 'product_added':
          case 'product_created':
            message = 'New product added: ${event['data']?['name'] ?? 'Unknown'}';
            backgroundColor = Colors.green;
            break;
          case 'product_updated':
            message = 'Product updated: ${event['data']?['name'] ?? 'Unknown'}';
            backgroundColor = Colors.blue;
            break;
          case 'product_removed':
          case 'product_deleted':
            message = 'Product removed';
            backgroundColor = Colors.orange;
            break;
        }
        break;
      case 'banner':
        switch (eventType) {
          case 'banner_added':
          case 'banner_created':
            message = 'New banner added: ${event['data']?['title'] ?? 'Unknown'}';
            backgroundColor = Colors.green;
            break;
          case 'banner_updated':
            message = 'Banner updated: ${event['data']?['title'] ?? 'Unknown'}';
            backgroundColor = Colors.blue;
            break;
          case 'banner_removed':
          case 'banner_deleted':
            message = 'Banner removed';
            backgroundColor = Colors.orange;
            break;
        }
        break;
    }

    if (message.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                _getIconForChangeType(eventType),
                color: AppColors.whiteColor,
                size: 20.sp,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.poppins(
                    color: AppColors.whiteColor,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: backgroundColor,
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
          action: SnackBarAction(
            label: 'Dismiss',
            textColor: AppColors.whiteColor,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  IconData _getIconForChangeType(String eventType) {
    switch (eventType) {
      case 'category_added':
      case 'category_created':
      case 'product_added':
      case 'product_created':
      case 'banner_added':
      case 'banner_created':
        return Icons.add_circle_outline;
      case 'category_updated':
      case 'product_updated':
      case 'banner_updated':
        return Icons.edit_outlined;
      case 'category_removed':
      case 'category_deleted':
      case 'product_removed':
      case 'product_deleted':
      case 'banner_removed':
      case 'banner_deleted':
        return Icons.delete_outline;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  void dispose() {
    _productSubscription?.cancel();
    _categorySubscription?.cancel();
    _bannerSubscription?.cancel();
    super.dispose();
  }
} 