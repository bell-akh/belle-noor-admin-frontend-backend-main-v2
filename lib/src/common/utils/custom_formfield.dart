import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:libas_app/src/common/constant/app_color.dart';

class CustomTextFormField extends StatelessWidget {
  const CustomTextFormField({
    super.key,
    required this.controller,
    required this.validator,
    this.keyboardType,
    this.labelText,
    this.color,
    this.filledColor,
    this.hint,
    this.prefixIcon,
    this.onFieldSubmitted,
    this.textInputAction,
    this.enable,
    this.maxline,
    this.focusnode,
    this.obsecure,
    this.hintTextColor,
    this.contentpadding,
    this.fontFamily,
    this.borderColor,
    this.fontSize,
    this.hintTextSize,
    this.suffixIcon,
    this.borderRadius,
    this.fontWeight,
    this.hintFontWeight,
    this.onChanged,
    this.focusedBorderColor,
    this.cursorHeight,
    this.readOnly,
    this.textInputColor,
    this.cursorColor,
    this.textAlign,
    this.prefix,
    this.onTap,
    this.textColor,
  });
  final TextEditingController controller;
  final String? Function(String?) validator;
  final TextInputType? keyboardType;
  final String? labelText;
  final Widget? prefixIcon;
  final Color? textInputColor;
  final Color? textColor;
  final double? cursorHeight;
  final Color? color;
  final EdgeInsets? contentpadding;
  final bool? enable;
  final int? maxline;
  final bool? readOnly;
  final Color? filledColor;
  final String? hint;
  final FocusNode? focusnode;
  final Function(String)? onFieldSubmitted;
  final TextInputAction? textInputAction;
  final Color? hintTextColor;
  final String? fontFamily;
  final Color? borderColor;
  final double? fontSize;
  final double? hintTextSize;
  final Widget? prefix;
  final double? borderRadius;
  final Widget? suffixIcon;
  final FontWeight? fontWeight;
  final FontWeight? hintFontWeight;
  final bool? obsecure;
  final Color? focusedBorderColor;
  final TextAlign? textAlign;
  final Color? cursorColor;
  final VoidCallback? onTap;
  final Function(String)? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      readOnly: readOnly ?? false,
      onTap: onTap,
      textAlign: textAlign ?? TextAlign.left,
      controller: controller,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      cursorColor: cursorColor,
      maxLines: maxline ?? 1,
      focusNode: focusnode,
      enabled: enable ?? true,
      cursorHeight: cursorHeight,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onChanged: onChanged,
      obscureText: obsecure ?? false,
      style: TextStyle(
        color: textInputColor,
        fontSize: fontSize ?? 15.sp,
        fontFamily: fontFamily ?? 'lato',
        fontWeight: fontWeight ?? FontWeight.w400,
      ),
      onTapOutside: (event) {
        FocusScope.of(context).unfocus();
      },
      onFieldSubmitted: onFieldSubmitted,
      decoration: InputDecoration(
        prefix: prefix,
        errorStyle: TextStyle(
          color: Colors.red,
          fontFamily: fontFamily ?? 'lato',
          fontSize: 10.sp,
        ),
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: filledColor ?? AppColors.whiteColor,
        isDense: true,
        contentPadding:
            contentpadding ??
            EdgeInsets.symmetric(horizontal: 20.w, vertical: 19.h),
        hintStyle: TextStyle(
          color: textColor,
          fontFamily: fontFamily ?? 'lato',
          fontSize: hintTextSize ?? 14.sp,
          fontWeight: hintFontWeight ?? FontWeight.w400,
        ),
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius ?? 12.r),
          borderSide: BorderSide(
            width: 1.w,
            color: focusedBorderColor ?? AppColors.blackColor.withOpacity(.3),
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius ?? 12.r),
          borderSide: BorderSide(
            width: 1.w,
            color: focusedBorderColor ?? AppColors.blackColor.withOpacity(.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius ?? 12.r),
          borderSide: BorderSide(
            width: 1.w,
            color: focusedBorderColor ?? AppColors.primaryColor.withOpacity(.7),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius ?? 12.r),
          borderSide: BorderSide(
            color: borderColor ?? AppColors.blackColor.withOpacity(.3),
            width: 1.w,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius ?? 12.r),
          borderSide: BorderSide(color: Colors.red, width: 1.w),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius ?? 12.r),
          borderSide: BorderSide(color: Colors.red, width: 1.w),
        ),
      ),
    );
  }
}
