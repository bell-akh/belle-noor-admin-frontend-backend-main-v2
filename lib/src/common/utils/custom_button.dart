import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:libas_app/src/common/constant/app_color.dart';
import 'package:libas_app/src/common/utils/custom_container.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback ontap;
  final double? height;
  final double? width;
  final Color? buttonColor;
  final Color? textColor;
  final double? fontSize;
  final double? borderRadius;
  final Color? borderColor;
  final Widget? centerWidget;
  final bool? paddingWidth;
  final List<BoxShadow>? boxShadow;
  final FontWeight? fontWeight;
  const CustomButton({
    super.key,
    this.centerWidget,
    required this.text,
    required this.ontap,
    this.height,
    this.width,
    this.buttonColor,
    this.textColor,
    this.fontSize,
    this.borderRadius,
    this.borderColor,
    this.boxShadow,
    this.paddingWidth,
    this.fontWeight,
  });

  @override
  Widget build(BuildContext context) {
    return paddingWidth == true
        ? DecoratedBox(
            decoration: BoxDecoration(boxShadow: boxShadow ?? []),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                shadowColor: AppColors.primaryColor,
                backgroundColor: buttonColor ?? AppColors.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(borderRadius ?? 6.r),
                  side: BorderSide(color: borderColor ?? Colors.transparent),
                ),
              ),
              onPressed: ontap,
              child:
                  centerWidget ??
                  TextWidget(
                    text: text,
                    color: textColor ?? AppColors.whiteColor,
                    fontSize: fontSize ?? 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          )
        : SizedBox(
            width: width ?? double.infinity,
            height: height ?? 48.h,
            child: DecoratedBox(
              decoration: BoxDecoration(boxShadow: boxShadow ?? []),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shadowColor: AppColors.primaryColor,
                  backgroundColor: buttonColor ?? AppColors.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(borderRadius ?? 8.r),
                    side: BorderSide(color: borderColor ?? Colors.transparent),
                  ),
                ),
                onPressed: ontap,
                child:
                    centerWidget ??
                    TextWidget(
                      text: text,
                      color: textColor ?? AppColors.whiteColor,
                      fontSize: fontSize ?? 14.sp,
                      fontWeight: fontWeight ?? FontWeight.w500,
                    ),
              ),
            ),
          );
  }
}
