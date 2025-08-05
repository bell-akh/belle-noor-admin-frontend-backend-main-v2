import 'dart:async';

import 'package:bottom_bar_matu/bottom_bar/bottom_bar_bubble.dart';
import 'package:bottom_bar_matu/bottom_bar_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:libas_app/src/common/constant/app_color.dart';
import 'package:libas_app/src/common/utils/custom_container.dart';
import 'package:libas_app/src/common/utils/custom_formfield.dart';
import 'package:libas_app/src/common/widgets/cart_badge.dart';
import 'package:libas_app/src/common/services/cart_service.dart';
import 'package:libas_app/src/feature/category_product/page/category_product_page.dart';
import 'package:libas_app/src/feature/cart/page/cart_page.dart';
import 'package:libas_app/src/feature/home_page/controller/home_controller.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int index = 0;
  late HomeController _homeController;

  TextEditingController searchController = TextEditingController();
  Duration remainingTime = const Duration(hours: 2, minutes: 30, seconds: 40);
  Timer? countdownTimer;
  
  // Text banner variables
  final List<String> texts = [
    'SHOP FOR 2499 & MORE, PURPLE300',
    'SHOP FOR 3499 & MORE, PURPLE300',
    'SHOP FOR 1999 & MORE, PURPLE300',
  ];
  
  late ScrollController _textScrollController;
  int _currentTextIndex = 0;
  Timer? _textScrollTimer;
  void startTimer() {
    countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (remainingTime.inSeconds > 0) {
        setState(() {
          remainingTime -= const Duration(seconds: 1);
        });
      } else {
        countdownTimer?.cancel();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    startTimer();
    
    // Initialize scroll controller for text banner
    _textScrollController = ScrollController();
    
    // Get home controller instance
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _homeController = context.read<HomeController>();
    });
    
    // Start text cycling timer
    _startTextCycling();
    
    if (kDebugMode) {
      print('🏠 HomePage: Initialized - data already loaded by splash screen');
    }
  }

  // Helper function to get banner image by index
  Widget _getBannerImage(int index) {
    return Consumer<HomeController>(
      builder: (context, controller, child) {
        final banners = controller.homeFirstBanners;
        if (banners.length > index) {
          final imageUrl = banners[index]['image'] ?? '';
          return Image.network(
            imageUrl,
            width: double.infinity,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: Colors.grey[200],
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              if (kDebugMode) {
                print('❌ Error loading banner image $index: $error');
              }
              return Container(
                color: Colors.grey[300],
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.image, size: 60, color: Colors.grey),
                    const SizedBox(height: 8),
                    Text(
                      'Image $index',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              );
            },
          );
        }
        return Container(
          color: Colors.grey[300],
          child: const Icon(Icons.image, size: 60),
        );
      },
    );
  }




  void _startTextCycling() {
    _textScrollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) {
        setState(() {
          _currentTextIndex = (_currentTextIndex + 1) % texts.length;
        });
      }
    });
  }

  Widget _buildTextWithColor(String textWithColor) {
    // Split the text by comma to get text and color
    final parts = textWithColor.split(',');
    final displayText = parts[0].trim();
    final colorCode = parts.length > 1 ? parts[1].trim() : 'PURPLE300';
    
    // Convert color code to actual color
    Color textColor;
    switch (colorCode) {
      case 'PURPLE300':
        textColor = AppColors.primaryColor;
        break;
      case 'PURPLE100':
        textColor = Colors.purple[100] ?? AppColors.primaryColor;
        break;
      default:
        textColor = AppColors.primaryColor;
    }
    
    return TextWidget(
      key: ValueKey(_currentTextIndex),
      text: displayText,
      textAlign: TextAlign.center,
      color: textColor,
      fontSize: 13.sp,
      fontWeight: FontWeight.w600,
    );
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    _textScrollTimer?.cancel();
    _textScrollController.dispose();
    super.dispose();
  }

  String formatDigits(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final hours = formatDigits(remainingTime.inHours);
    final minutes = formatDigits(remainingTime.inMinutes.remainder(60));
    final seconds = formatDigits(remainingTime.inSeconds.remainder(60));

    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(80.h),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: Center(
            child: Row(
              children: [
                Container(
                  width: 60.w,
                  height: 60.w,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.shopping_bag,
                    color: Colors.white,
                    size: 30.w,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: CustomTextFormField(
                    hintTextSize: 13.sp,
                    hint: 'Search products here',
                    prefixIcon: Icon(
                      Icons.search,
                      color: AppColors.greyColor,
                      size: 20.sp,
                    ),
                    contentpadding: EdgeInsets.symmetric(
                      vertical: 10.w,
                      horizontal: 10.w,
                    ),
                    controller: searchController,
                    validator: (val) => null,
                  ),
                ),
                SizedBox(width: 20.w),
                Consumer<CartService>(
                  builder: (context, cartService, child) {
                    return CartBadge(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const CartPage()),
                          );
                        },
                        child: Icon(
                          Icons.shopping_bag_outlined,
                          color: AppColors.primaryColor,
                          size: 30.sp,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            CustomContainer(
              height: 80.h,

              width: double.infinity,
              color: Color(0xff71006a),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextWidget(
                    text: 'FLASH SALE - Ends In',
                    color: AppColors.textYellowColor,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  SizedBox(width: 30.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextWidget(
                        text: "$hours :",
                        color: AppColors.textYellowColor,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                      ),

                      TextWidget(
                        text: "Hrs ",
                        fontSize: 13.sp,
                        color: AppColors.textYellowColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ],
                  ),
                  SizedBox(width: 5.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextWidget(
                        text: "$minutes :",
                        color: AppColors.textYellowColor,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                      ),

                      TextWidget(
                        text: "Mins ",
                        fontSize: 13.sp,
                        color: AppColors.textYellowColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ],
                  ),
                  SizedBox(width: 5.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextWidget(
                        text: "$seconds ",
                        color: AppColors.textYellowColor,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                      ),

                      TextWidget(
                        text: "Secs ",
                        fontSize: 13.sp,
                        color: AppColors.textYellowColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Consumer<HomeController>(
              builder: (context, controller, child) {
                return GestureDetector(
                  onTap: () {
                    if (kDebugMode) {
                      print('🖱️ HomePage: Banner 0 tapped - navigating to category');
                    }
                    final banners = controller.homeFirstBanners;
                    if (banners.length > 0) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CategoryProductPage(
                            categoryId: banners[0]['link'] ?? '1',
                            categoryName: banners[0]['title'] ?? 'Category',
                            categoryImage: '',
                          ),
                        ),
                      );
                    }
                  },
                  child: _getBannerImage(0),
                );
              },
            ),
            CustomContainer(
              color: AppColors.textYellowColor,
              height: 30.h,
              width: double.infinity,
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(1.0, 0.0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    );
                  },
                  child: _buildTextWithColor(texts[_currentTextIndex]),
                ),
              ),
            ),
            _getBannerImage(1),
            Consumer<HomeController>(
              builder: (context, controller, child) {
                return GestureDetector(
                  onTap: () {
                    final banners = controller.homeFirstBanners;
                    if (banners.length > 2) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CategoryProductPage(
                            categoryId: banners[2]['link'] ?? '2',
                            categoryName: banners[2]['title'] ?? 'Category',
                            categoryImage: '',
                          ),
                        ),
                      );
                    }
                  },
                  child: _getBannerImage(2),
                );
              },
            ),
            CustomContainer(
              height: 60.h,

              width: double.infinity,
              color: Color(0xff671673),
              child: Center(
                child: TextWidget(
                  text: 'Deals to Steal'.toUpperCase(),
                  color: AppColors.textYellowColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 22.sp,
                ),
              ),
            ),
            Container(
              color: Color(0xff671673),
              child: Row(
                children: [
                  Expanded(
                    child: Consumer<HomeController>(
                      builder: (context, controller, child) {
                        return GestureDetector(
                          onTap: () {
                            final banners = controller.homeFirstBanners;
                            if (banners.length > 3) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CategoryProductPage(
                                    categoryId: banners[3]['link'] ?? '3',
                                    categoryName: banners[3]['title'] ?? 'Category',
                                    categoryImage: '',
                                  ),
                                ),
                              );
                            }
                          },
                          child: _getBannerImage(3),
                        );
                      },
                    ),
                  ),
                  SizedBox(width: 5.w),
                  Expanded(
                    child: Consumer<HomeController>(
                      builder: (context, controller, child) {
                        return GestureDetector(
                          onTap: () {
                            final banners = controller.homeFirstBanners;
                            if (banners.length > 4) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CategoryProductPage(
                                    categoryId: banners[4]['link'] ?? '4',
                                    categoryName: banners[4]['title'] ?? 'Category',
                                    categoryImage: '',
                                  ),
                                ),
                              );
                            }
                          },
                          child: _getBannerImage(4),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Consumer<HomeController>(
              builder: (context, controller, child) {
                return GestureDetector(
                  onTap: () {
                    final banners = controller.homeFirstBanners;
                    if (banners.length > 5) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CategoryProductPage(
                            categoryId: banners[5]['link'] ?? '5',
                            categoryName: banners[5]['title'] ?? 'Category',
                            categoryImage: '',
                          ),
                        ),
                      );
                    }
                  },
                  child: _getBannerImage(5),
                );
              },
            ),
            Container(
              color: Color(0xff671673),
              child: Row(
                children: [
                  Expanded(
                    child: Consumer<HomeController>(
                      builder: (context, controller, child) {
                        return GestureDetector(
                          onTap: () {
                            final banners = controller.homeFirstBanners;
                            if (banners.length > 6) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CategoryProductPage(
                                    categoryId: banners[6]['link'] ?? '1',
                                    categoryName: banners[6]['title'] ?? 'Category',
                                    categoryImage: '',
                                  ),
                                ),
                              );
                            }
                          },
                          child: _getBannerImage(6),
                        );
                      },
                    ),
                  ),
                  SizedBox(width: 5.w),
                  Expanded(
                    child: Consumer<HomeController>(
                      builder: (context, controller, child) {
                        return GestureDetector(
                          onTap: () {
                            final banners = controller.homeFirstBanners;
                            if (banners.length > 7) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CategoryProductPage(
                                    categoryId: banners[7]['link'] ?? '2',
                                    categoryName: banners[7]['title'] ?? 'Category',
                                    categoryImage: '',
                                  ),
                                ),
                              );
                            }
                          },
                          child: _getBannerImage(7),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Consumer<HomeController>(
              builder: (context, controller, child) {
                return GestureDetector(
                  onTap: () {
                    final banners = controller.homeFirstBanners;
                    if (banners.length > 8) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CategoryProductPage(
                            categoryId: banners[8]['link'] ?? '3',
                            categoryName: banners[8]['title'] ?? 'Category',
                            categoryImage: '',
                          ),
                        ),
                      );
                    }
                  },
                  child: _getBannerImage(8),
                );
              },
            ),
            Container(
              color: Color(0xff671673),
              child: Row(
                children: [
                  Expanded(
                    child: Consumer<HomeController>(
                      builder: (context, controller, child) {
                        return GestureDetector(
                          onTap: () {
                            final banners = controller.homeFirstBanners;
                            if (banners.length > 9) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CategoryProductPage(
                                    categoryId: banners[9]['link'] ?? '4',
                                    categoryName: banners[9]['title'] ?? 'Category',
                                    categoryImage: '',
                                  ),
                                ),
                              );
                            }
                          },
                          child: _getBannerImage(9),
                        );
                      },
                    ),
                  ),
                  SizedBox(width: 5.w),
                  Expanded(
                    child: Consumer<HomeController>(
                      builder: (context, controller, child) {
                        return GestureDetector(
                          onTap: () {
                            final banners = controller.homeFirstBanners;
                            if (banners.length > 10) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CategoryProductPage(
                                    categoryId: banners[10]['link'] ?? '5',
                                    categoryName: banners[10]['title'] ?? 'Category',
                                    categoryImage: '',
                                  ),
                                ),
                              );
                            }
                          },
                          child: _getBannerImage(10),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            Consumer<HomeController>(
              builder: (context, controller, child) {
                return GestureDetector(
                  onTap: () {
                    final banners = controller.homeFirstBanners;
                    if (banners.length > 11) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CategoryProductPage(
                            categoryId: banners[11]['link'] ?? '1',
                            categoryName: banners[11]['title'] ?? 'Category',
                            categoryImage: '',
                          ),
                        ),
                      );
                    }
                  },
                  child: _getBannerImage(11),
                );
              },
            ),

            Consumer<HomeController>(
              builder: (context, controller, child) {
                return GestureDetector(
                  onTap: () {
                    final banners = controller.homeFirstBanners;
                    if (banners.length > 12) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CategoryProductPage(
                            categoryId: banners[12]['link'] ?? '2',
                            categoryName: banners[12]['title'] ?? 'Category',
                            categoryImage: '',
                          ),
                        ),
                      );
                    }
                  },
                  child: _getBannerImage(12),
                );
              },
            ),
            Container(
              color: Color(0xff671673),
              child: Row(
                children: [
                  Expanded(
                    child: Consumer<HomeController>(
                      builder: (context, controller, child) {
                        return GestureDetector(
                          onTap: () {
                            final banners = controller.homeFirstBanners;
                            if (banners.length > 13) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CategoryProductPage(
                                    categoryId: banners[13]['link'] ?? '3',
                                    categoryName: banners[13]['title'] ?? 'Category',
                                    categoryImage: '',
                                  ),
                                ),
                              );
                            }
                          },
                          child: _getBannerImage(13),
                        );
                      },
                    ),
                  ),
                  SizedBox(width: 5.w),
                  Expanded(
                    child: Consumer<HomeController>(
                      builder: (context, controller, child) {
                        return GestureDetector(
                          onTap: () {
                            final banners = controller.homeFirstBanners;
                            if (banners.length > 14) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CategoryProductPage(
                                    categoryId: banners[14]['link'] ?? '4',
                                    categoryName: banners[14]['title'] ?? 'Category',
                                    categoryImage: '',
                                  ),
                                ),
                              );
                            }
                          },
                          child: _getBannerImage(14),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Container(
              color: Color(0xff671673),
              child: Row(
                children: [
                  Expanded(
                    child: Consumer<HomeController>(
                      builder: (context, controller, child) {
                        return GestureDetector(
                          onTap: () {
                            final banners = controller.homeFirstBanners;
                            if (banners.length > 15) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CategoryProductPage(
                                    categoryId: banners[15]['link'] ?? '5',
                                    categoryName: banners[15]['title'] ?? 'Category',
                                    categoryImage: '',
                                  ),
                                ),
                              );
                            }
                          },
                          child: _getBannerImage(15),
                        );
                      },
                    ),
                  ),
                  SizedBox(width: 5.w),
                  Expanded(
                    child: Consumer<HomeController>(
                      builder: (context, controller, child) {
                        return GestureDetector(
                          onTap: () {
                            final banners = controller.homeFirstBanners;
                            if (banners.length > 16) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CategoryProductPage(
                                    categoryId: banners[16]['link'] ?? '2',
                                    categoryName: banners[16]['title'] ?? 'Category',
                                    categoryImage: '',
                                  ),
                                ),
                              );
                            }
                          },
                          child: _getBannerImage(16),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Container(
              color: Color(0xff671673),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                                              Get.to(
                        CategoryProductPage(
                          categoryId: '3',
                          categoryName: 'Loungerwear',
                          categoryImage: '',
                        ),
                      );
                      },
                                             child: _getBannerImage(17),
                    ),
                  ),
                  SizedBox(width: 5.w),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                                              Get.to(
                        CategoryProductPage(
                          categoryId: '1',
                          categoryName: 'Plus Suze Clothing',
                          categoryImage: '',
                        ),
                      );
                      },
                                             child: _getBannerImage(18),
                    ),
                  ),
                ],
              ),
            ),
                         _getBannerImage(19),

            CustomContainer(
              color: Color(0xfffd8c90),
              width: double.infinity,

              padding: EdgeInsets.symmetric(vertical: 20.h),
              child: Center(
                child: TextWidget(
                  text:
                      'We do not ask for your bank account or card details verbally\n or telephonically. Do not divulge these to fraudsters or imposters\n claiming on our behalf as it can result in financial\nloss/found. Thank you!',
                  textAlign: TextAlign.center,
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 10.sp,
                ),
              ),
            ),
            CustomContainer(
              color: AppColors.whiteColor,
              width: double.infinity,

              padding: EdgeInsets.symmetric(vertical: 20.h),
              child: Center(
                child: TextWidget(
                  text: "©Libas 2024. All Rights Reserved.",
                  textAlign: TextAlign.center,
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 10.sp,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
