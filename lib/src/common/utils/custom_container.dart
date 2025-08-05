import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomContainer extends StatelessWidget {
  const CustomContainer({
    super.key,
    this.onTap,
    this.height,
    this.width,
    this.color,
    this.boxShadow,
    this.padding,
    this.boxConstraints,
    this.borderRadius,
    this.borderColor,
    this.borderWidth,
    this.child,
    this.margin,
    this.image,
    this.onLongPress,
    this.gradient,
    this.swipedown,
  });
  final Gradient? gradient;
  final EdgeInsets? margin;
  final BoxConstraints? boxConstraints;
  final EdgeInsets? padding;
  final Color? color;
  final Widget? child;
  final double? borderRadius;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double? width;
  final double? height;
  final double? borderWidth;
  final Color? borderColor;
  final List<BoxShadow>? boxShadow;
  final DecorationImage? image;
  final Function(DragUpdateDetails)? swipedown;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      onVerticalDragUpdate: swipedown,
      onTap: onTap,
      child: Container(
        height: height,
        width: width,
        constraints: boxConstraints,
        padding: padding,
        margin: margin,
        decoration: BoxDecoration(
          gradient: gradient,
          image: image,
          boxShadow: boxShadow,
          border: Border.all(
            color: borderColor ?? Colors.transparent,
            width: borderWidth ?? 0,
          ),
          color: color,
          borderRadius: BorderRadius.circular(borderRadius ?? 0),
        ),
        child: child,
      ),
    );
  }
}

class TextWidget extends StatelessWidget {
  const TextWidget({
    super.key,
    this.onTap,
    required this.text,
    this.color,
    this.fontFamily,
    this.fontSize,
    this.letterSpacing,
    this.fontWeight,
    this.underline,
    this.overflow,
    this.textShadow,
    this.textAlign,
    this.maxLines,
    this.decorationColor,
  });
  final String text;
  final Color? decorationColor;
  final VoidCallback? onTap;
  final Color? color;
  final String? fontFamily;
  final double? fontSize;
  final double? letterSpacing;
  final FontWeight? fontWeight;
  final TextDecoration? underline;
  final TextOverflow? overflow;
  final List<Shadow>? textShadow;
  final TextAlign? textAlign;
  final int? maxLines;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        text,
        textAlign: textAlign,
        maxLines: maxLines,
        style: GoogleFonts.poppins(
          decorationColor: decorationColor,
          color: color,
          fontWeight: fontWeight ?? FontWeight.w400,
          letterSpacing: letterSpacing ?? 0.1,
          fontSize: fontSize ?? 16.sp,
          decoration: underline ?? TextDecoration.none,
          shadows: textShadow,
        ),
        overflow: overflow,
      ),
    );
  }
}
