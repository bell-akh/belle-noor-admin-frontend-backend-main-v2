import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:libas_app/src/common/constant/app_color.dart';

void customSnackBar({required String message, bool? isError, BuildContext? context}) {
  if (context == null) {
    // If no context provided, just print the message for now
    print('SnackBar: $message');
    return;
  }
  
  // Use the provided context to access the scaffold messenger
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  
  scaffoldMessenger.showSnackBar(
    SnackBar(
      content: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError == true ? Icons.cancel_outlined : Icons.check_circle,
            color: Colors.white,
            size: 20.sp,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: AppColors.whiteColor,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: isError == true
          ? AppColors.redColor
          : AppColors.primaryColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
      ),
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 20.w),
      duration: const Duration(seconds: 3),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
