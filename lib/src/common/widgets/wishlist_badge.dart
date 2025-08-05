import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:libas_app/src/common/services/wishlist_service.dart';
import 'package:provider/provider.dart';

class WishlistBadge extends StatelessWidget {
  final Widget child;
  final Color? badgeColor;
  final Color? textColor;

  const WishlistBadge({
    Key? key,
    required this.child,
    this.badgeColor,
    this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<WishlistService>(
      builder: (context, wishlistService, child) {
        final count = wishlistService.wishlistCount;
        
        return Stack(
          clipBehavior: Clip.none,
          children: [
            this.child,
            if (count > 0)
              Positioned(
                right: -8.w,
                top: -8.h,
                child: Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: badgeColor ?? Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: BoxConstraints(
                    minWidth: 16.w,
                    minHeight: 16.h,
                  ),
                  child: Text(
                    count > 99 ? '99+' : count.toString(),
                    style: TextStyle(
                      color: textColor ?? Colors.white,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
} 