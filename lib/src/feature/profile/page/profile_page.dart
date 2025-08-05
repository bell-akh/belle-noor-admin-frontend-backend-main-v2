import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:libas_app/src/common/constant/app_color.dart';
import 'package:libas_app/src/common/services/auth_service.dart';
import 'package:libas_app/src/common/widgets/phone_auth_bottom_sheet.dart';
import 'package:libas_app/src/feature/wishlist/page/wishlist_page.dart';
import 'package:libas_app/src/feature/orders/page/orders_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      print('🔐 ProfilePage: Building ProfilePage widget - START');
    }
    
    // Add a simple print to see if this code is being executed
    print('🔐 ProfilePage: This should appear in console');
    
    if (kDebugMode) {
      print('🔐 ProfilePage: Building ProfilePage widget - END');
    }
    
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                      Consumer<AuthService>(
              builder: (context, authService, child) {
                if (!authService.isAuthenticated) {
                  return Column(
                    children: [
                      Icon(Icons.person_outline, size: 100.w, color: Colors.grey),
                      SizedBox(height: 16.h),
                      Text(
                        'Sign in to view your profile',
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Access your account details and preferences',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 24.h),
                                            ElevatedButton(
                        onPressed: () {
                          if (kDebugMode) {
                            print('🔐 ProfilePage: Sign in button pressed');
                          }
                          showPhoneAuthBottomSheet(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Sign In'),
                      ),
                    ],
                  );
                } else {
                  final user = authService.currentUser;
                  return Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Column(
                      children: [
                        // Profile Header
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(20.w),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor,
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 40.r,
                                backgroundColor: Colors.white,
                                child: Icon(
                                  Icons.person,
                                  size: 40.w,
                                  color: AppColors.primaryColor,
                                ),
                              ),
                              SizedBox(height: 12.h),
                              Text(
                                user?['name'] ?? 'User',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                user?['email'] ?? 'user@example.com',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        SizedBox(height: 24.h),
                        
                        // Profile Options
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _buildProfileOption(
                                context,
                                icon: Icons.favorite,
                                title: 'My Wishlist',
                                subtitle: 'View your saved items',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const WishlistPage()),
                                  );
                                },
                              ),
                              Divider(height: 1, color: Colors.grey[200]),
                              _buildProfileOption(
                                context,
                                icon: Icons.shopping_bag,
                                title: 'My Orders',
                                subtitle: 'Track your orders',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const OrdersPage()),
                                  );
                                },
                              ),
                              Divider(height: 1, color: Colors.grey[200]),
                              _buildProfileOption(
                                context,
                                icon: Icons.settings,
                                title: 'Settings',
                                subtitle: 'App preferences',
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Settings coming soon!')),
                                  );
                                },
                              ),
                              Divider(height: 1, color: Colors.grey[200]),
                              _buildProfileOption(
                                context,
                                icon: Icons.help,
                                title: 'Help & Support',
                                subtitle: 'Get help',
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Help & Support coming soon!')),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        
                        SizedBox(height: 24.h),
                        
                        // Sign Out Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              authService.logout();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[50],
                              foregroundColor: Colors.red,
                              padding: EdgeInsets.symmetric(vertical: 16.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                            child: Text(
                              'Sign Out',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40.w,
        height: 40.w,
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Icon(
          icon,
          color: AppColors.primaryColor,
          size: 20.w,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14.sp,
          color: Colors.grey[600],
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16.w,
        color: Colors.grey[400],
      ),
      onTap: onTap,
    );
  }
} 