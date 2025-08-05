import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:libas_app/src/common/constant/app_color.dart';
import 'package:libas_app/src/common/widgets/phone_auth_bottom_sheet.dart';

void showSignInBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
    ),
    builder: (_) => Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16.w,
          right: 16.w,
          top: 24.h,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag indicator
            Container(
              width: 40.w,
              height: 5.h,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
            SizedBox(height: 24.h),
            
            // Title
            Text(
              "You're Not Signed In",
              style: GoogleFonts.poppins(
                color: AppColors.blackColor,
                fontWeight: FontWeight.w600,
                fontSize: 18.sp,
              ),
            ),
            SizedBox(height: 12.h),
            
            // Description
            Text(
              "You must be signed in to add items to your wishlist.\nYou can save items in your wishlist to purchase later.",
              style: GoogleFonts.poppins(
                color: AppColors.greyColor,
                fontWeight: FontWeight.w400,
                fontSize: 13.sp,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            
            // Sign In Button
            SizedBox(
              width: double.infinity,
              height: 48.h,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  showPhoneAuthBottomSheet(context);
                },
                child: Text(
                  "SIGN IN",
                  style: GoogleFonts.poppins(
                    color: AppColors.whiteColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            
            // Create Account Button
            SizedBox(
              width: double.infinity,
              height: 48.h,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.primaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  showPhoneAuthBottomSheet(context);
                },
                child: Text(
                  "CREATE ACCOUNT",
                  style: GoogleFonts.poppins(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    ),
  );
}

 