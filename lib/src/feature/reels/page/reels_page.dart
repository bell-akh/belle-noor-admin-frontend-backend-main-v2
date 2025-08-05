import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:libas_app/src/common/services/real_api_service.dart';
import 'package:libas_app/src/feature/reels/widgets/reel_card.dart';

class ReelsPage extends StatefulWidget {
  const ReelsPage({Key? key}) : super(key: key);

  @override
  State<ReelsPage> createState() => _ReelsPageState();
}

class _ReelsPageState extends State<ReelsPage> {
  final RealApiService _apiService = RealApiService();
  List<Map<String, dynamic>> _videos = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final videos = await _apiService.getVideos();
      
      // If no videos from API, create sample videos for demonstration
      if (videos.isEmpty) {
        _videos = _createSampleVideos();
      } else {
        _videos = videos;
      }

      setState(() {
        _isLoading = false;
      });

      if (kDebugMode) {
        print('🎬 ReelsPage: Loaded ${_videos.length} videos');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      
      // Create sample videos even if API fails
      _videos = _createSampleVideos();
      
      if (kDebugMode) {
        print('❌ ReelsPage: Error loading videos: $e');
        print('🎬 ReelsPage: Using sample videos for demonstration');
      }
    }
  }

  List<Map<String, dynamic>> _createSampleVideos() {
    return [
      {
        'id': 'sample-video-1',
        'title': 'Fashion Show Highlights',
        'description': 'Amazing fashion show with the latest trends and styles.',
        'url': 'https://example.com/video1.mp4',
        'thumbnail': 'https://example.com/thumb1.jpg',
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      },
      {
        'id': 'sample-video-2',
        'title': 'Behind the Scenes',
        'description': 'Exclusive behind the scenes footage from our latest photo shoot.',
        'url': 'https://example.com/video2.mp4',
        'thumbnail': 'https://example.com/thumb2.jpg',
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      },
      {
        'id': 'sample-video-3',
        'title': 'Style Tips & Tricks',
        'description': 'Learn how to style your outfits like a professional.',
        'url': 'https://example.com/video3.mp4',
        'thumbnail': 'https://example.com/thumb3.jpg',
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      },
      {
        'id': 'sample-video-4',
        'title': 'New Collection Preview',
        'description': 'First look at our upcoming collection featuring the latest designs.',
        'url': 'https://example.com/video4.mp4',
        'thumbnail': 'https://example.com/thumb4.jpg',
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      },
      {
        'id': 'sample-video-5',
        'title': 'Customer Reviews',
        'description': 'Hear what our customers have to say about our products.',
        'url': 'https://example.com/video5.mp4',
        'thumbnail': 'https://example.com/thumb5.jpg',
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reels'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadVideos,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading reels...'),
          ],
        ),
      );
    }

    if (_error != null && _videos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading reels',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadVideos,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_videos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.video_library_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No reels available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for new content!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadVideos,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _videos.length,
        itemBuilder: (context, index) {
          final video = _videos[index];
          return ReelCard(
            video: video,
            onTap: () {
              if (kDebugMode) {
                print('🎬 ReelsPage: Tapped on video: ${video['id']}');
              }
              // Here you would navigate to a video player or full-screen view
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Playing: ${video['title']}'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          );
        },
      ),
    );
  }
} 