import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:libas_app/src/common/constant/app_color.dart';

class LoadingWidget extends StatelessWidget {
  final String? message;
  final double? size;

  const LoadingWidget({
    Key? key,
    this.message,
    this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: size ?? 40.w,
            height: size ?? 40.w,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
            ),
          ),
          if (message != null) ...[
            SizedBox(height: 16.h),
            Text(
              message!,
              style: TextStyle(
                color: AppColors.greyColor,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class ShimmerLoadingWidget extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerLoadingWidget({
    Key? key,
    this.width = double.infinity,
    this.height = 20,
    this.borderRadius = 8,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.greyColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
} 