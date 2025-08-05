import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:libas_app/src/common/constant/app_color.dart';
import 'package:libas_app/src/common/services/real_api_service.dart';
import 'package:libas_app/src/common/widgets/loading_widget.dart';

// CDC Event Classes
class DataChangeEvent {
  final DataChangeType type;
  final String table;
  final String? id;
  final Map<String, dynamic>? data;
  final DateTime timestamp;

  DataChangeEvent({
    required this.type,
    required this.table,
    this.id,
    this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory DataChangeEvent.fromMap(Map<String, dynamic> map) {
    return DataChangeEvent(
      type: DataChangeType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
        orElse: () => DataChangeType.unknown,
      ),
      table: map['table'] ?? '',
      id: map['id'],
      data: map['data'],
      timestamp: map['timestamp'] != null 
          ? DateTime.parse(map['timestamp']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.toString().split('.').last,
      'table': table,
      'id': id,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

enum DataChangeType {
  productAdded,
  productUpdated,
  productRemoved,
  categoryAdded,
  categoryUpdated,
  categoryRemoved,
  bannerAdded,
  bannerUpdated,
  bannerRemoved,
  unknown,
}

class AdminPanel extends StatefulWidget {
  const AdminPanel({Key? key}) : super(key: key);

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  final RealApiService _apiService = RealApiService();
  List<DataChangeEvent> changeHistory = [];
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> banners = [];
  bool isLoading = true;
  int selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupDataChangeListener();
  }

  void _setupDataChangeListener() {
    _apiService.dataChangeService?.addListener(_onDataChange);
  }

  void _onDataChange() {
    setState(() {
      // Refresh data when changes occur
    });
    
    // Refresh data based on change type
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Load all data in parallel
      final futures = await Future.wait([
        _apiService.getAllProducts(),
        _apiService.getCategories(),
        _apiService.getBanners(),
      ]);

      setState(() {
        products = futures[0];
        categories = futures[1];
        banners = futures[2];
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Admin Panel',
          style: GoogleFonts.poppins(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.whiteColor,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.whiteColor),
            onPressed: _loadData,
          ),
        ],
      ),
      body: isLoading
          ? LoadingWidget(message: 'Loading admin data...')
          : Column(
              children: [
                // Connection Status
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16.w),
                  color: _apiService.isConnected ? Colors.green.shade50 : Colors.red.shade50,
                  child: Row(
                    children: [
                      Icon(
                        _apiService.isConnected ? Icons.wifi : Icons.wifi_off,
                        color: _apiService.isConnected ? Colors.green : Colors.red,
                        size: 20.sp,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        _apiService.isConnected 
                            ? 'Connected to real-time updates' 
                            : 'Disconnected from real-time updates',
                        style: GoogleFonts.poppins(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: _apiService.isConnected ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Tab Bar
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.whiteColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TabBar(
                    onTap: (index) {
                      setState(() {
                        selectedTabIndex = index;
                      });
                    },
                    labelColor: AppColors.primaryColor,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: AppColors.primaryColor,
                    tabs: [
                      Tab(text: 'Products (${products.length})'),
                      Tab(text: 'Categories (${categories.length})'),
                      Tab(text: 'Banners (${banners.length})'),
                      Tab(text: 'Changes (${changeHistory.length})'),
                    ],
                  ),
                ),
                
                // Tab Content
                Expanded(
                  child: IndexedStack(
                    index: selectedTabIndex,
                    children: [
                      _buildProductsTab(),
                      _buildCategoriesTab(),
                      _buildBannersTab(),
                      _buildChangesTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildProductsTab() {
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return Card(
          margin: EdgeInsets.only(bottom: 12.h),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primaryColor,
              child: Text(
                'P',
                style: TextStyle(color: AppColors.whiteColor),
              ),
            ),
            title: Text(
              product['name'] ?? 'Unknown Product',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'Category: ${product['categoryId'] ?? 'Unknown'}',
              style: GoogleFonts.poppins(fontSize: 12.sp),
            ),
            trailing: Text(
              '\$${product['price']?.toString() ?? '0'}',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: AppColors.primaryColor,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoriesTab() {
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return Card(
          margin: EdgeInsets.only(bottom: 12.h),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.secondaryColor,
              child: Text(
                'C',
                style: TextStyle(color: AppColors.whiteColor),
              ),
            ),
            title: Text(
              category['name'] ?? 'Unknown Category',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              category['description'] ?? 'No description',
              style: GoogleFonts.poppins(fontSize: 12.sp),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBannersTab() {
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: banners.length,
      itemBuilder: (context, index) {
        final banner = banners[index];
        return Card(
          margin: EdgeInsets.only(bottom: 12.h),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.accentColor,
              child: Text(
                'B',
                style: TextStyle(color: AppColors.whiteColor),
              ),
            ),
            title: Text(
              banner['title'] ?? 'Unknown Banner',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              banner['subtitle'] ?? 'No subtitle',
              style: GoogleFonts.poppins(fontSize: 12.sp),
            ),
            trailing: Icon(
              banner['isActive'] == true ? Icons.check_circle : Icons.cancel,
              color: banner['isActive'] == true ? Colors.green : Colors.red,
            ),
          ),
        );
      },
    );
  }

  Widget _buildChangesTab() {
    if (changeHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64.sp,
              color: Colors.grey.withOpacity(0.5),
            ),
            SizedBox(height: 16.h),
            Text(
              'No changes recorded yet',
              style: GoogleFonts.poppins(
                fontSize: 16.sp,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: changeHistory.length,
      itemBuilder: (context, index) {
        final change = changeHistory[index];
        return Card(
          margin: EdgeInsets.only(bottom: 12.h),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getChangeColor(change.type),
              child: Icon(
                _getChangeIcon(change.type),
                color: AppColors.whiteColor,
                size: 20.sp,
              ),
            ),
            title: Text(
              '${change.table} ${_getChangeTypeText(change.type)}',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ID: ${change.id ?? 'N/A'}',
                  style: GoogleFonts.poppins(fontSize: 12.sp),
                ),
                Text(
                  'Time: ${_formatTimestamp(change.timestamp)}',
                  style: GoogleFonts.poppins(fontSize: 12.sp),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getChangeColor(DataChangeType type) {
    switch (type) {
      case DataChangeType.productAdded:
      case DataChangeType.categoryAdded:
      case DataChangeType.bannerAdded:
        return Colors.green;
      case DataChangeType.productUpdated:
      case DataChangeType.categoryUpdated:
      case DataChangeType.bannerUpdated:
        return Colors.blue;
      case DataChangeType.productRemoved:
      case DataChangeType.categoryRemoved:
      case DataChangeType.bannerRemoved:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getChangeIcon(DataChangeType type) {
    switch (type) {
      case DataChangeType.productAdded:
      case DataChangeType.categoryAdded:
      case DataChangeType.bannerAdded:
        return Icons.add;
      case DataChangeType.productUpdated:
      case DataChangeType.categoryUpdated:
      case DataChangeType.bannerUpdated:
        return Icons.edit;
      case DataChangeType.productRemoved:
      case DataChangeType.categoryRemoved:
      case DataChangeType.bannerRemoved:
        return Icons.delete;
      default:
        return Icons.info;
    }
  }

  String _getChangeTypeText(DataChangeType type) {
    switch (type) {
      case DataChangeType.productAdded:
        return 'Added';
      case DataChangeType.productUpdated:
        return 'Updated';
      case DataChangeType.productRemoved:
        return 'Removed';
      case DataChangeType.categoryAdded:
        return 'Added';
      case DataChangeType.categoryUpdated:
        return 'Updated';
      case DataChangeType.categoryRemoved:
        return 'Removed';
      case DataChangeType.bannerAdded:
        return 'Added';
      case DataChangeType.bannerUpdated:
        return 'Updated';
      case DataChangeType.bannerRemoved:
        return 'Removed';
      default:
        return 'Changed';
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute}';
  }

  @override
  void dispose() {
    _apiService.dataChangeService?.removeListener(_onDataChange);
    super.dispose();
  }
} 