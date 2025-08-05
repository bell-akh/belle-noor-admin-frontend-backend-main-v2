import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:libas_app/src/common/constant/app_color.dart';
import 'package:libas_app/src/common/services/auth_service.dart';
import 'package:libas_app/src/common/services/video_service.dart';
import 'package:libas_app/src/common/widgets/sign_in_bottom_sheet.dart';
import 'package:libas_app/src/common/utils/custom_button.dart';
import 'package:libas_app/src/common/utils/custom_formfield.dart';
import 'package:libas_app/src/common/utils/custom_snack_bar.dart';

class VideoUploadPage extends StatefulWidget {
  const VideoUploadPage({Key? key}) : super(key: key);

  @override
  State<VideoUploadPage> createState() => _VideoUploadPageState();
}

class _VideoUploadPageState extends State<VideoUploadPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  
  File? _selectedVideo;
  bool _isUploading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    try {
      final ImagePicker picker = ImagePicker();
      
      // Try to pick video directly first (most devices handle permissions automatically)
      XFile? video;
      try {
        video = await picker.pickVideo(
          source: ImageSource.gallery,
          maxDuration: const Duration(seconds: 30), // Allow longer videos, will be trimmed server-side
        );
      } catch (permissionError) {
        print('Permission error: $permissionError');
        // If direct pick fails, try to request permission explicitly
        try {
          final PermissionStatus status = await Permission.photos.status;
          if (status.isDenied) {
            final PermissionStatus result = await Permission.photos.request();
            if (result.isDenied) {
              customSnackBar(
                message: 'Permission denied. Please grant photo library access in settings.',
                isError: true
              );
              return;
            }
          }
          
          // Try picking again after permission request
          video = await picker.pickVideo(
            source: ImageSource.gallery,
            maxDuration: const Duration(seconds: 30),
          );
        } catch (e) {
          print('Second attempt failed: $e');
          customSnackBar(
            message: 'Unable to access photo library. Please check app permissions.',
            isError: true,
            context: context,
          );
          return;
        }
      }

      if (video != null) {
        final videoPath = video.path;
        if (videoPath.isNotEmpty) {
                  setState(() {
          _selectedVideo = File(videoPath);
        });
        customSnackBar(message: 'Video selected successfully!', isError: false, context: context);
        }
      }
    } catch (e) {
      print('Video picker error: $e');
      customSnackBar(
        message: 'Error picking video. Please try again.',
        isError: true,
        context: context,
      );
    }
  }

  Future<void> _uploadVideo() async {
    if (_selectedVideo == null) {
      customSnackBar(message: 'Please select a video first', isError: true, context: context);
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final videoService = context.read<VideoService>();
      final result = await videoService.uploadVideo(
        videoFile: _selectedVideo!,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _categoryController.text.trim().isEmpty ? 'general' : _categoryController.text.trim(),
      );

      if (result['success']) {
        customSnackBar(
          message: result['data']['wasTrimmed'] == true 
            ? 'Video uploaded successfully! (Trimmed to 7 seconds)' 
            : 'Video uploaded successfully!',
          context: context,
        );
        
        // Clear form
        _titleController.clear();
        _descriptionController.clear();
        _categoryController.clear();
        setState(() {
          _selectedVideo = null;
        });
        
        // Navigate back
        Navigator.pop(context);
      } else {
        customSnackBar(message: result['error'] ?? 'Upload failed', isError: true, context: context);
      }
    } catch (e) {
      customSnackBar(message: 'Upload error: $e', isError: true, context: context);
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      appBar: AppBar(
        backgroundColor: AppColors.whiteColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.blackColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Upload Video',
          style: GoogleFonts.poppins(
            color: AppColors.blackColor,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              FocusScope.of(context).unfocus();
            },
            child: Text(
              'Done',
              style: GoogleFonts.poppins(
                color: AppColors.primaryColor,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Consumer<AuthService>(
        builder: (context, authService, child) {
          if (!authService.isAuthenticated) {
            return _buildUnauthenticatedView();
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Video selection section
                  _buildVideoSelectionSection(),
                  SizedBox(height: 24.h),

                  // Form fields
                  _buildFormFields(),
                  SizedBox(height: 32.h),

                  // Upload button
                  _buildUploadButton(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUnauthenticatedView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.video_library_outlined,
            size: 80.sp,
            color: AppColors.greyColor.withOpacity(0.5),
          ),
          SizedBox(height: 16.h),
          Text(
            'Sign in to upload videos',
            style: GoogleFonts.poppins(
              color: AppColors.blackColor,
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'You need to be signed in to upload\nvideos to the platform',
            style: GoogleFonts.poppins(
              color: AppColors.greyColor,
              fontSize: 14.sp,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
          ElevatedButton(
            onPressed: () {
              showSignInBottomSheet(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25.r),
              ),
            ),
            child: Text(
              'Sign In',
              style: GoogleFonts.poppins(
                color: AppColors.whiteColor,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoSelectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Video',
          style: GoogleFonts.poppins(
            color: AppColors.blackColor,
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 12.h),
        
        if (_selectedVideo == null)
          GestureDetector(
            onTap: _isUploading ? null : _pickVideo,
            child: Container(
              width: double.infinity,
              height: 200.h,
              decoration: BoxDecoration(
                color: AppColors.greyColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: AppColors.greyColor.withOpacity(0.3),
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.video_library_outlined,
                    size: 48.sp,
                    color: AppColors.greyColor,
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'Tap to select video',
                    style: GoogleFonts.poppins(
                      color: AppColors.greyColor,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Videos will be automatically trimmed to 7 seconds',
                    style: GoogleFonts.poppins(
                      color: AppColors.greyColor.withOpacity(0.7),
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            width: double.infinity,
            height: 200.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: AppColors.primaryColor.withOpacity(0.3),
                style: BorderStyle.solid,
              ),
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.black,
                    child: const Center(
                      child: Icon(
                        Icons.video_file,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8.h,
                  right: 8.w,
                  child: GestureDetector(
                    onTap: _isUploading ? null : () {
                      setState(() {
                        _selectedVideo = null;
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 16.sp,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8.h,
                  left: 8.w,
                  right: 8.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      path.basename(_selectedVideo!.path),
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildFormFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextFormField(
          controller: _titleController,
          labelText: 'Video Title',
          hint: 'Enter video title',
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) {
            FocusScope.of(context).nextFocus();
          },
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a title';
            }
            return null;
          },
        ),
        SizedBox(height: 16.h),
        
        CustomTextFormField(
          controller: _descriptionController,
          labelText: 'Description',
          hint: 'Enter video description (optional)',
          maxline: 3,
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) {
            FocusScope.of(context).nextFocus();
          },
          validator: (value) => null, // Optional field, no validation required
        ),
        SizedBox(height: 16.h),
        
        CustomTextFormField(
          controller: _categoryController,
          labelText: 'Category',
          hint: 'Enter category (optional)',
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) {
            FocusScope.of(context).unfocus();
          },
          validator: (value) => null, // Optional field, no validation required
        ),
      ],
    );
  }

  Widget _buildUploadButton() {
    return SizedBox(
      width: double.infinity,
      child: CustomButton(
        ontap: _isUploading ? () {} : _uploadVideo,
        text: _isUploading ? 'Uploading...' : 'Upload Video',
        centerWidget: _isUploading 
          ? SizedBox(
              height: 20.h,
              width: 20.h,
              child: CircularProgressIndicator(
                color: AppColors.whiteColor,
                strokeWidth: 2,
              ),
            )
          : null,
      ),
    );
  }
} 