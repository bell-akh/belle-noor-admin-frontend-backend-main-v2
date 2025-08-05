import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BannerSectionWidget extends StatelessWidget {
  final List<Map<String, dynamic>> banners;
  final String sectionId;
  final VoidCallback? onBannerTap;

  const BannerSectionWidget({
    Key? key,
    required this.banners,
    required this.sectionId,
    this.onBannerTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (banners.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min, // Prevent extra space
      children: banners.map((banner) => _buildBannerItem(banner)).toList(),
    );
  }

  Widget _buildBannerItem(Map<String, dynamic> banner) {
    return Builder(
      builder: (context) => Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top, // Fill from top to safe area
        margin: EdgeInsets.zero,
        padding: EdgeInsets.zero,
        child: GestureDetector(
          onTap: () {
            if (onBannerTap != null) {
              onBannerTap!();
            }
          },
          child: Stack(
            children: [
              // Banner image container
              Container(
                width: double.infinity,
                height: double.infinity,
                child: Image.network(
                  banner['image'] ?? '',
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.fill, // Use fill to eliminate white space
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image, size: 60),
                    );
                  },
                ),
              ),
              // Title and subtitle overlay (only if they exist)
              if (banner['title'] != null || banner['subtitle'] != null)
                Positioned(
                  bottom: 20.h,
                  left: 20.w,
                  right: 20.w,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (banner['title'] != null)
                        Text(
                          banner['title'] ?? '',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      if (banner['title'] != null && banner['subtitle'] != null)
                        SizedBox(height: 8.h),
                      if (banner['subtitle'] != null)
                        Text(
                          banner['subtitle'] ?? '',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
} 