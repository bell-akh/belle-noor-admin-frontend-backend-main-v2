import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:libas_app/src/common/constant/app_color.dart';
import 'package:libas_app/src/common/services/auth_service.dart';
import 'package:libas_app/src/common/services/video_service.dart';
import 'package:libas_app/src/common/services/real_api_service.dart';
import 'package:libas_app/src/common/widgets/sign_in_bottom_sheet.dart';
import 'package:libas_app/src/common/utils/custom_snack_bar.dart';
import 'package:libas_app/src/feature/video_explore/widgets/reels_video_player.dart';

class ReelsVideoPage extends StatefulWidget {
  const ReelsVideoPage({Key? key}) : super(key: key);

  @override
  State<ReelsVideoPage> createState() => _ReelsVideoPageState();
}

class _ReelsVideoPageState extends State<ReelsVideoPage> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  bool _isLoadingMore = false;
  int _currentPage = 0;
  final int _limit = 10;
  final RealApiService _apiService = RealApiService();

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadVideos() async {
    final videoService = context.read<VideoService>();
    await videoService.fetchExploreVideos(limit: _limit, offset: 0);
  }

  Future<void> _loadMoreVideos() async {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    _currentPage++;
    final videoService = context.read<VideoService>();
    await videoService.fetchExploreVideos(limit: _limit, offset: _currentPage * _limit);

    setState(() {
      _isLoadingMore = false;
    });
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });

    // Load more videos when approaching the end
    final videoService = context.read<VideoService>();
    print('🎬 Page changed to index: $index, total videos: ${videoService.videos.length}');
    
    if (index >= videoService.videos.length - 3) {
      print('🔄 Loading more videos...');
      _loadMoreVideos();
    }
  }

  Future<void> _onLikeVideo(String videoId) async {
    final authService = context.read<AuthService>();
    if (!authService.isAuthenticated) {
      _showSignInBottomSheet();
      return;
    }

    try {
      // Get current like status
      final userLikeStatus = await _apiService.getUserLikeStatus(videoId);
      final currentLikeStatus = userLikeStatus['hasLiked'] ?? false;
      
      // Toggle like
      final result = await _apiService.toggleLike(
        videoId: videoId,
        isLiked: !currentLikeStatus,
      );
      
      print('🔍 Like toggle result: $result');
      
      if (result['success'] == true) {
        // Get the updated data from the response
        final responseData = result['data'];
        final newIsLiked = responseData['isLiked'] ?? !currentLikeStatus;
        final newLikeCount = responseData['likeCount'] ?? 0;
        
        print('🔍 New like status: $newIsLiked, like count: $newLikeCount');
        
        // Update the video service to reflect the change
        final videoService = context.read<VideoService>();
        videoService.updateVideoLikeStatus(videoId, newIsLiked, newLikeCount);
        
        customSnackBar(
          message: newIsLiked ? 'Video liked!' : 'Video unliked!',
          isError: false,
          context: context,
        );
      } else {
        print('❌ Like toggle failed: ${result['error']}');
        customSnackBar(
          message: result['error'] ?? 'Failed to like video',
          isError: true,
          context: context,
        );
      }
    } catch (e) {
      customSnackBar(
        message: 'Error liking video: ${e.toString()}',
        isError: true,
        context: context,
      );
    }
  }

  void _onShareVideo(Map<String, dynamic> video) {
    // TODO: Implement share functionality
    customSnackBar(
      message: 'Share feature coming soon!',
      isError: false,
      context: context,
    );
  }

  Future<void> _onCommentVideo(Map<String, dynamic> video) async {
    final authService = context.read<AuthService>();
    if (!authService.isAuthenticated) {
      _showSignInBottomSheet();
      return;
    }

    final TextEditingController commentController = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Comment'),
          content: TextField(
            controller: commentController,
            decoration: const InputDecoration(
              hintText: 'Write your comment...',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(commentController.text),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result != null && result.trim().isNotEmpty) {
      try {
        // Get current like status
        final userLikeStatus = await _apiService.getUserLikeStatus(video['id']);
        final currentLikeStatus = userLikeStatus['hasLiked'] ?? false;
        final existingLike = userLikeStatus['like'];
        
        if (existingLike != null) {
          // Update existing like with comment
          final response = await _apiService.updateComment(existingLike['id'], result.trim());
          
          if (response['success'] == true) {
            customSnackBar(
              message: 'Comment added successfully!',
              isError: false,
              context: context,
            );
          } else {
            customSnackBar(
              message: 'Failed to add comment',
              isError: true,
              context: context,
            );
          }
        } else {
          // Create new like with comment
          final response = await _apiService.toggleLike(
            videoId: video['id'],
            isLiked: currentLikeStatus,
            comments: result.trim(),
          );
          
          if (response['success'] == true) {
            customSnackBar(
              message: 'Comment added successfully!',
              isError: false,
              context: context,
            );
          } else {
            customSnackBar(
              message: 'Failed to add comment',
              isError: true,
              context: context,
            );
          }
        }
      } catch (e) {
        customSnackBar(
          message: 'Error adding comment: ${e.toString()}',
          isError: true,
          context: context,
        );
      }
    }
  }

  void _showSignInBottomSheet() {
    showSignInBottomSheet(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.blackColor,
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: Consumer<VideoService>(
        builder: (context, videoService, child) {
          if (videoService.isLoading && videoService.videos.isEmpty) {
            return Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryColor,
              ),
            );
          }

          if (videoService.videos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.video_library_outlined,
                    color: AppColors.whiteColor,
                    size: 64.sp,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'No videos available',
                    style: GoogleFonts.poppins(
                      color: AppColors.whiteColor,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Upload the first video!',
                    style: GoogleFonts.poppins(
                      color: AppColors.whiteColor.withOpacity(0.7),
                      fontSize: 14.sp,
                    ),
                  ),
                ],
              ),
            );
          }

          return Stack(
            children: [
              // Video PageView
              PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                onPageChanged: _onPageChanged,
                itemCount: videoService.videos.length,
                itemBuilder: (context, index) {
                  final video = videoService.videos[index];
                  print('🎬 Building video at index $index: ${video['id']} - ${video['title']}');
                  
                  return ReelsVideoPlayer(
                    key: ValueKey(video['id']), // Add unique key for each video
                    videoUrl: video['videoUrl'] ?? '',
                    title: video['title'] ?? '',
                    description: video['description'] ?? '',
                    authorName: video['authorName'] ?? 'Unknown User',
                    likes: video['likes'] ?? 0,
                    views: video['views'] ?? 0,
                    isLiked: video['isLiked'] ?? false,
                    onLike: () => _onLikeVideo(video['id']),
                    onShare: () => _onShareVideo(video),
                    onComment: () => _onCommentVideo(video),
                  );
                },
              ),

              // Top Bar
              Positioned(
                top: MediaQuery.of(context).padding.top,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Reels',
                        style: GoogleFonts.poppins(
                          color: AppColors.whiteColor,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Spacer(),
                      Consumer<AuthService>(
                        builder: (context, authService, child) {
                          if (authService.isAuthenticated) {
                            return IconButton(
                              icon: Icon(
                                Icons.favorite,
                                color: AppColors.whiteColor,
                                size: 24.sp,
                              ),
                              onPressed: () {
                                // Navigate to liked videos
                                Navigator.pushNamed(context, '/liked-videos');
                              },
                            );
                          }
                          return SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Loading indicator at bottom
              if (_isLoadingMore)
                Positioned(
                  bottom: MediaQuery.of(context).padding.bottom + 20.h,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16.w,
                            height: 16.w,
                            child: CircularProgressIndicator(
                              color: AppColors.primaryColor,
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            'Loading more...',
                            style: GoogleFonts.poppins(
                              color: AppColors.whiteColor,
                              fontSize: 12.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
} 