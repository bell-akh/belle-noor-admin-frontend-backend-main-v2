import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:libas_app/src/common/services/cart_service.dart';

class CartBadge extends StatelessWidget {
  final Widget child;
  final Color? badgeColor;
  final Color? textColor;

  const CartBadge({
    Key? key,
    required this.child,
    this.badgeColor,
    this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<CartService>(
      builder: (context, cartService, child) {
        return Stack(
          children: [
            this.child,
            if (cartService.itemCount > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: badgeColor ?? Colors.red,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  constraints: BoxConstraints(
                    minWidth: 16.w,
                    minHeight: 16.h,
                  ),
                  child: Text(
                    '${cartService.itemCount}',
                    style: GoogleFonts.poppins(
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