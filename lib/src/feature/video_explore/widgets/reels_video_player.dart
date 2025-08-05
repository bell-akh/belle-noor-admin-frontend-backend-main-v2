import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:libas_app/src/common/constant/app_color.dart';

class ReelsVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String title;
  final String description;
  final String authorName;
  final int likes;
  final int views;
  final bool isLiked;
  final VoidCallback? onLike;
  final VoidCallback? onShare;
  final VoidCallback? onComment;

  const ReelsVideoPlayer({
    Key? key,
    required this.videoUrl,
    required this.title,
    required this.description,
    required this.authorName,
    required this.likes,
    required this.views,
    required this.isLiked,
    this.onLike,
    this.onShare,
    this.onComment,
  }) : super(key: key);

  @override
  State<ReelsVideoPlayer> createState() => _ReelsVideoPlayerState();
}

class _ReelsVideoPlayerState extends State<ReelsVideoPlayer> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    print('🎬 ReelsVideoPlayer initState for video: ${widget.videoUrl}');
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      print('🎬 Initializing video: ${widget.videoUrl}');
      _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      
      await _videoPlayerController.initialize();
      print('🎬 Video initialized successfully: ${widget.videoUrl}');
      
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: true,
        looping: true,
        showControls: false,
        showOptions: false,
        aspectRatio: 9 / 16, // Vertical video aspect ratio
        allowFullScreen: false,
        allowMuting: false,
        allowPlaybackSpeedChanging: false,
        placeholder: Container(
          color: AppColors.blackColor,
          child: Center(
            child: CircularProgressIndicator(
              color: AppColors.primaryColor,
            ),
          ),
        ),
        errorBuilder: (context, errorMessage) {
          return Container(
            color: AppColors.blackColor,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: AppColors.whiteColor,
                    size: 48.sp,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Error loading video',
                    style: GoogleFonts.poppins(
                      color: AppColors.whiteColor,
                      fontSize: 16.sp,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

      _videoPlayerController.addListener(() {
        if (_videoPlayerController.value.isPlaying != _isPlaying) {
          setState(() {
            _isPlaying = _videoPlayerController.value.isPlaying;
          });
        }
      });

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      print('Error initializing video: $e');
    }
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _videoPlayerController.pause();
    } else {
      _videoPlayerController.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppColors.blackColor,
      child: Stack(
        children: [
          // Video Player (Centered)
          Center(
            child: _isInitialized && _chewieController != null
                ? Chewie(controller: _chewieController!)
                : Container(
                    color: AppColors.blackColor,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
          ),
          
          // Play/Pause Overlay
          GestureDetector(
            onTap: _togglePlayPause,
            child: Container(
              color: Colors.transparent,
              child: Center(
                child: AnimatedOpacity(
                  opacity: _isPlaying ? 0.0 : 1.0,
                  duration: Duration(milliseconds: 300),
                  child: Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: AppColors.whiteColor,
                      size: 48.sp,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Right Side Actions
          Positioned(
            right: 16.w,
            bottom: 120.h,
            child: Column(
              children: [
                // Like Button
                _buildActionButton(
                  icon: widget.isLiked ? Icons.favorite : Icons.favorite_border,
                  label: _formatCount(widget.likes),
                  color: widget.isLiked ? Colors.red : AppColors.whiteColor,
                  onTap: widget.onLike,
                ),
                SizedBox(height: 24.h),
                
                // Comment Button
                _buildActionButton(
                  icon: Icons.chat_bubble_outline,
                  label: 'Comment',
                  onTap: widget.onComment,
                ),
                SizedBox(height: 24.h),
                
                // Share Button
                _buildActionButton(
                  icon: Icons.share,
                  label: 'Share',
                  onTap: widget.onShare,
                ),
                SizedBox(height: 24.h),
                
                // Views
                _buildActionButton(
                  icon: Icons.visibility,
                  label: _formatCount(widget.views),
                ),
              ],
            ),
          ),

          // Bottom Info Section
          Positioned(
            left: 16.w,
            right: 80.w,
            bottom: 40.h,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Author Name
                Text(
                  '@${widget.authorName}',
                  style: GoogleFonts.poppins(
                    color: AppColors.whiteColor,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8.h),
                
                // Title
                if (widget.title.isNotEmpty)
                  Text(
                    widget.title,
                    style: GoogleFonts.poppins(
                      color: AppColors.whiteColor,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                SizedBox(height: 4.h),
                
                // Description
                if (widget.description.isNotEmpty)
                  Text(
                    widget.description,
                    style: GoogleFonts.poppins(
                      color: AppColors.whiteColor.withOpacity(0.8),
                      fontSize: 12.sp,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),

          // Top Gradient Overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 100.h,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.6),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Bottom Gradient Overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 120.h,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.6),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    Color? color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color ?? AppColors.whiteColor,
              size: 24.sp,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: AppColors.whiteColor,
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
} 