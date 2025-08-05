import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:libas_app/src/common/constant/app_color.dart';
import 'package:libas_app/src/common/services/auth_service.dart';
import 'package:libas_app/src/common/services/video_service.dart';
import 'package:libas_app/src/common/widgets/sign_in_bottom_sheet.dart';
import 'package:libas_app/src/common/utils/custom_snack_bar.dart';

class VideoExplorePage extends StatefulWidget {
  const VideoExplorePage({Key? key}) : super(key: key);

  @override
  State<VideoExplorePage> createState() => _VideoExplorePageState();
}

class _VideoExplorePageState extends State<VideoExplorePage> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  int _currentPage = 0;
  final int _limit = 10;

  @override
  void initState() {
    super.initState();
    _loadVideos();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMoreVideos();
    }
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

  Future<void> _refreshVideos() async {
    _currentPage = 0;
    await _loadVideos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.blackColor,
      appBar: AppBar(
        backgroundColor: AppColors.blackColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.whiteColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Explore Videos',
          style: GoogleFonts.poppins(
            color: AppColors.whiteColor,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Consumer<AuthService>(
            builder: (context, authService, child) {
              if (authService.isAuthenticated) {
                return IconButton(
                  icon: Icon(Icons.favorite, color: AppColors.whiteColor),
                  onPressed: () {
                    // Navigate to liked videos
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LikedVideosPage(),
                      ),
                    );
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer2<AuthService, VideoService>(
        builder: (context, authService, videoService, child) {
          if (!authService.isAuthenticated) {
            return _buildUnauthenticatedView();
          }

          if (videoService.isLoading && videoService.videos.isEmpty) {
            return Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryColor,
              ),
            );
          }

          if (videoService.error != null && videoService.videos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: ${videoService.error}',
                    style: GoogleFonts.poppins(
                      color: AppColors.whiteColor,
                      fontSize: 16.sp,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16.h),
                  ElevatedButton(
                    onPressed: _refreshVideos,
                    child: const Text('Retry'),
                  ),
                ],
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
                    size: 80.sp,
                    color: AppColors.greyColor.withOpacity(0.5),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'No videos available',
                    style: GoogleFonts.poppins(
                      color: AppColors.whiteColor,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Be the first to upload a video!',
                    style: GoogleFonts.poppins(
                      color: AppColors.greyColor,
                      fontSize: 14.sp,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshVideos,
            color: AppColors.primaryColor,
            backgroundColor: AppColors.blackColor,
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.zero,
              itemCount: videoService.videos.length + (_isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                                 if (index == videoService.videos.length) {
                   return Center(
                     child: Padding(
                       padding: EdgeInsets.all(16.h),
                       child: CircularProgressIndicator(
                         color: AppColors.primaryColor,
                       ),
                     ),
                   );
                 }

                final video = videoService.videos[index];
                return VideoCard(
                  video: video,
                  onLike: () => _handleLike(video['id']),
                  onView: () => _handleView(video['id']),
                );
              },
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
            'Sign in to explore videos',
            style: GoogleFonts.poppins(
              color: AppColors.whiteColor,
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'You need to be signed in to view\nand interact with videos',
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

  Future<void> _handleLike(String videoId) async {
    final videoService = context.read<VideoService>();
    final result = await videoService.toggleLike(videoId);
    
    if (result['success']) {
      final isLiked = result['data']['isLiked'];
      customSnackBar(
        message: isLiked ? 'Video liked!' : 'Video unliked!',
      );
    } else {
      customSnackBar(
        message: result['error'] ?? 'Failed to update like',
        isError: true,
      );
    }
  }

  Future<void> _handleView(String videoId) async {
    final videoService = context.read<VideoService>();
    await videoService.incrementView(videoId);
  }
}

class VideoCard extends StatefulWidget {
  final Map<String, dynamic> video;
  final VoidCallback onLike;
  final VoidCallback onView;

  const VideoCard({
    Key? key,
    required this.video,
    required this.onLike,
    required this.onView,
  }) : super(key: key);

  @override
  State<VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<VideoCard> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  Future<void> _initializeVideo() async {
    try {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.video['videoUrl']),
      );
      
      await _videoController!.initialize();
      
      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: false,
        looping: true,
        aspectRatio: _videoController!.value.aspectRatio,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.primaryColor,
          handleColor: AppColors.primaryColor,
          backgroundColor: AppColors.greyColor,
          bufferedColor: AppColors.greyColor.withOpacity(0.5),
        ),
      );

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitialized = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Video player
          AspectRatio(
            aspectRatio: 16 / 9,
            child: _isInitialized
                ? Chewie(controller: _chewieController!)
                : Container(
                    color: Colors.black,
                    child: Center(
                                             child: Column(
                         mainAxisAlignment: MainAxisAlignment.center,
                         children: [
                           CircularProgressIndicator(
                             color: AppColors.primaryColor,
                           ),
                          SizedBox(height: 8.h),
                          Text(
                            'Loading video...',
                            style: GoogleFonts.poppins(
                              color: AppColors.whiteColor,
                              fontSize: 14.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),

          // Video info
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and like button
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.video['title'] ?? 'Untitled Video',
                        style: GoogleFonts.poppins(
                          color: AppColors.whiteColor,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    GestureDetector(
                      onTap: widget.onLike,
                      child: Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: (widget.video['isLiked'] == true)
                              ? AppColors.primaryColor
                              : AppColors.greyColor.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          (widget.video['isLiked'] == true)
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: AppColors.whiteColor,
                          size: 20.sp,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 8.h),

                // Description
                if (widget.video['description'] != null && widget.video['description'].toString().isNotEmpty)
                  Text(
                    widget.video['description'],
                    style: GoogleFonts.poppins(
                      color: AppColors.greyColor,
                      fontSize: 14.sp,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),

                SizedBox(height: 12.h),

                // Stats
                Row(
                  children: [
                    Icon(
                      Icons.favorite,
                      color: AppColors.greyColor,
                      size: 16.sp,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      '${widget.video['likes'] ?? 0}',
                      style: GoogleFonts.poppins(
                        color: AppColors.greyColor,
                        fontSize: 12.sp,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Icon(
                      Icons.visibility,
                      color: AppColors.greyColor,
                      size: 16.sp,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      '${widget.video['views'] ?? 0}',
                      style: GoogleFonts.poppins(
                        color: AppColors.greyColor,
                        fontSize: 12.sp,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Icon(
                      Icons.access_time,
                      color: AppColors.greyColor,
                      size: 16.sp,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      '${widget.video['duration']?.toStringAsFixed(1) ?? '0.0'}s',
                      style: GoogleFonts.poppins(
                        color: AppColors.greyColor,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LikedVideosPage extends StatefulWidget {
  const LikedVideosPage({Key? key}) : super(key: key);

  @override
  State<LikedVideosPage> createState() => _LikedVideosPageState();
}

class _LikedVideosPageState extends State<LikedVideosPage> {
  @override
  void initState() {
    super.initState();
    _loadLikedVideos();
  }

  Future<void> _loadLikedVideos() async {
    final videoService = context.read<VideoService>();
    await videoService.fetchLikedVideos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.blackColor,
      appBar: AppBar(
        backgroundColor: AppColors.blackColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.whiteColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Liked Videos',
          style: GoogleFonts.poppins(
            color: AppColors.whiteColor,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Consumer<VideoService>(
        builder: (context, videoService, child) {
                     if (videoService.isLoading) {
             return Center(
               child: CircularProgressIndicator(
                 color: AppColors.primaryColor,
               ),
             );
           }

          if (videoService.likedVideos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 80.sp,
                    color: AppColors.greyColor.withOpacity(0.5),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'No liked videos',
                    style: GoogleFonts.poppins(
                      color: AppColors.whiteColor,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Like some videos to see them here',
                    style: GoogleFonts.poppins(
                      color: AppColors.greyColor,
                      fontSize: 14.sp,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: videoService.likedVideos.length,
            itemBuilder: (context, index) {
              final video = videoService.likedVideos[index];
              return VideoCard(
                video: video,
                onLike: () async {
                  final result = await videoService.toggleLike(video['id']);
                  if (result['success']) {
                    // Refresh liked videos list
                    await _loadLikedVideos();
                  }
                },
                onView: () => videoService.incrementView(video['id']),
              );
            },
          );
        },
      ),
    );
  }
} 