import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'auth_service.dart';

class VideoService extends ChangeNotifier {
  static final VideoService _instance = VideoService._internal();
  factory VideoService() => _instance;
  VideoService._internal();

  final String _baseUrl = 'http://BelleN-NodeS-htzjq6lxvVlw-908287247.ap-south-1.elb.amazonaws.com/api';
  final AuthService _authService = AuthService();

  List<Map<String, dynamic>> _videos = [];
  List<Map<String, dynamic>> _likedVideos = [];
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get videos => _videos;
  List<Map<String, dynamic>> get likedVideos => _likedVideos;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get explore videos
  Future<void> fetchExploreVideos({int limit = 10, int offset = 0}) async {
    // Allow fetching videos without authentication for public viewing
    // Authentication will be handled at the API level if needed

    _setLoading(true);
    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      
      // Add authorization header only if user is authenticated
      if (_authService.isAuthenticated) {
        headers['Authorization'] = 'Bearer ${_authService.authToken}';
      }
      
      final response = await http.get(
        Uri.parse('$_baseUrl/videos/explore?limit=$limit&offset=$offset'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final newVideos = List<Map<String, dynamic>>.from(data['data']['videos']);
          
          // If offset is 0, replace the list (first load)
          // If offset > 0, append to the list (pagination)
          if (offset == 0) {
            _videos = newVideos;
            print('🎬 Initial videos loaded: ${_videos.length}');
          } else {
            _videos.addAll(newVideos);
            print('🎬 More videos loaded: ${newVideos.length}, total: ${_videos.length}');
          }
          
          // Load like status for each video if user is authenticated
          if (_authService.isAuthenticated) {
            await _loadLikeStatusForVideos();
          }
          
          // Start async like count refresh in background
          refreshLikeCountsAsync();
          
          _setError(null);
        } else {
          _setError(data['error'] ?? 'Failed to fetch videos');
        }
      } else {
        _setError('Failed to fetch videos: ${response.statusCode}');
      }
    } catch (e) {
      _setError('Network error: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Get user's liked videos
  Future<void> fetchLikedVideos({int limit = 10, int offset = 0}) async {
    if (!_authService.isAuthenticated) {
      _setError('Authentication required');
      return;
    }

    _setLoading(true);
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/videos/liked?limit=$limit&offset=$offset'),
        headers: {
          'Authorization': 'Bearer ${_authService.authToken}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          _likedVideos = List<Map<String, dynamic>>.from(data['data']['videos']);
          _setError(null);
        } else {
          _setError(data['error'] ?? 'Failed to fetch liked videos');
        }
      } else {
        _setError('Failed to fetch liked videos: ${response.statusCode}');
      }
    } catch (e) {
      _setError('Network error: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Upload video
  Future<Map<String, dynamic>> uploadVideo({
    required File videoFile,
    String? title,
    String? description,
    String? category,
  }) async {
    if (!_authService.isAuthenticated) {
      return {'success': false, 'error': 'Authentication required'};
    }

    try {
      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/videos/upload'),
      );

      // Add authorization header
      request.headers['Authorization'] = 'Bearer ${_authService.authToken}';

      // Add video file
      print('📁 Uploading video file: ${videoFile.path}');
      print('📁 File name: ${path.basename(videoFile.path)}');
      print('📁 File exists: ${await videoFile.exists()}');
      print('📁 File size: ${await videoFile.length()} bytes');
      
      request.files.add(
        await http.MultipartFile.fromPath(
          'video',
          videoFile.path,
          filename: path.basename(videoFile.path),
        ),
      );

      // Add other fields
      if (title != null && title.isNotEmpty) {
        request.fields['title'] = title;
      }
      if (description != null && description.isNotEmpty) {
        request.fields['description'] = description;
      }
      if (category != null && category.isNotEmpty) {
        request.fields['category'] = category;
      }

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          // Refresh videos list after successful upload
          await fetchExploreVideos();
          return {'success': true, 'data': data['data']};
        } else {
          return {'success': false, 'error': data['error'] ?? 'Upload failed'};
        }
      } else {
        final errorData = json.decode(response.body);
        return {'success': false, 'error': errorData['error'] ?? 'Upload failed: ${response.statusCode}'};
      }
    } catch (e) {
      if (kDebugMode) {
        print('Video upload error: $e');
      }
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Like/unlike video
  Future<Map<String, dynamic>> toggleLike(String videoId) async {
    if (!_authService.isAuthenticated) {
      return {'success': false, 'error': 'Authentication required'};
    }

    try {
      // First get current like status
      final userLikeStatus = await _getUserLikeStatus(videoId);
      final currentLikeStatus = userLikeStatus['hasLiked'] ?? false;
      
      // Toggle like using new likes API
      final response = await http.post(
        Uri.parse('$_baseUrl/likes/toggle'),
        headers: {
          'Authorization': 'Bearer ${_authService.authToken}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'videoId': videoId,
          'isLiked': !currentLikeStatus,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final responseData = data['data'];
          final newLikeCount = responseData['likeCount'];
          final newIsLiked = responseData['isLiked'];
          
          // Update video in local list with the actual count from server
          _updateVideoLikeStatus(videoId, newLikeCount, newIsLiked);
          
          return {'success': true, 'data': {'isLiked': newIsLiked, 'likeCount': newLikeCount}};
        } else {
          return {'success': false, 'error': data['error'] ?? 'Failed to toggle like'};
        }
      } else {
        final errorData = json.decode(response.body);
        return {'success': false, 'error': errorData['error'] ?? 'Failed to toggle like: ${response.statusCode}'};
      }
    } catch (e) {
      if (kDebugMode) {
        print('Toggle like error: $e');
      }
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Get user like status for a video
  Future<Map<String, dynamic>> _getUserLikeStatus(String videoId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/likes/user/video/$videoId'),
        headers: {
          'Authorization': 'Bearer ${_authService.authToken}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? {};
      } else {
        return {'hasLiked': false};
      }
    } catch (e) {
      if (kDebugMode) {
        print('Get user like status error: $e');
      }
      return {'hasLiked': false};
    }
  }

  // Load like status for all videos
  Future<void> _loadLikeStatusForVideos() async {
    for (int i = 0; i < _videos.length; i++) {
      try {
        final videoId = _videos[i]['id'];
        final likeStatus = await _getUserLikeStatus(videoId);
        _videos[i]['isLiked'] = likeStatus['hasLiked'] ?? false;
      } catch (e) {
        if (kDebugMode) {
          print('Error loading like status for video ${_videos[i]['id']}: $e');
        }
        _videos[i]['isLiked'] = false;
      }
    }
    notifyListeners();
  }

  // Refresh videos cache to get updated like counts
  Future<void> _refreshVideosCache() async {
    if (_videos.isNotEmpty) {
      try {
        // Fetch fresh data from server
        await fetchExploreVideos(limit: _videos.length, offset: 0);
        if (kDebugMode) {
          print('🔄 Refreshed videos cache with updated like counts');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error refreshing videos cache: $e');
        }
      }
    }
  }

  // Asynchronously refresh like counts for all videos
  Future<void> refreshLikeCountsAsync() async {
    if (_videos.isEmpty) return;
    
    try {
      if (kDebugMode) {
        print('🔄 Starting async like count refresh for ${_videos.length} videos');
      }
      
      // Refresh like counts for each video in parallel
      final futures = _videos.map((video) async {
        try {
          final videoId = video['id'];
          final response = await http.get(
            Uri.parse('$_baseUrl/likes/video/$videoId'),
            headers: {
              'Content-Type': 'application/json',
            },
          );
          
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            if (data['success'] == true) {
              final likes = data['data']['likes'] ?? [];
              final likeCount = likes.where((like) => like['isLiked'] == 'true').length;
              
              // Update the video's like count
              final videoIndex = _videos.indexWhere((v) => v['id'] == videoId);
              if (videoIndex != -1) {
                _videos[videoIndex]['likes'] = likeCount;
              }
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error refreshing like count for video ${video['id']}: $e');
          }
        }
      });
      
      await Future.wait(futures);
      notifyListeners();
      
      if (kDebugMode) {
        print('✅ Async like count refresh completed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in async like count refresh: $e');
      }
    }
  }

  // Increment view count
  Future<void> incrementView(String videoId) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/videos/$videoId/view'),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      if (kDebugMode) {
        print('Increment view error: $e');
      }
    }
  }

  // Get video by ID
  Future<Map<String, dynamic>?> getVideoById(String videoId) async {
    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };

      if (_authService.isAuthenticated) {
        headers['Authorization'] = 'Bearer ${_authService.authToken}';
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/videos/$videoId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'];
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Get video error: $e');
      }
      return null;
    }
  }

  // Update video like status in local list
  void _updateVideoLikeStatus(String videoId, int? likes, bool isLiked) {
    final videoIndex = _videos.indexWhere((video) => video['id'] == videoId);
    if (videoIndex != -1) {
      // Always use the exact count from server if provided
      if (likes != null) {
        _videos[videoIndex]['likes'] = likes;
      }
      _videos[videoIndex]['isLiked'] = isLiked;
      notifyListeners();
    }
    
    // Also update in liked videos list if it exists
    final likedVideoIndex = _likedVideos.indexWhere((video) => video['id'] == videoId);
    if (likedVideoIndex != -1) {
      if (likes != null) {
        _likedVideos[likedVideoIndex]['likes'] = likes;
      }
      _likedVideos[likedVideoIndex]['isLiked'] = isLiked;
      notifyListeners();
    }
  }

  // Public method to update video like status
  void updateVideoLikeStatus(String videoId, bool isLiked, [int? likeCount]) {
    final videoIndex = _videos.indexWhere((video) => video['id'] == videoId);
    if (videoIndex != -1) {
      _videos[videoIndex]['isLiked'] = isLiked;
      // Use provided like count if available, otherwise calculate
      if (likeCount != null) {
        _videos[videoIndex]['likes'] = likeCount;
      } else {
        // Update likes count
        if (isLiked) {
          _videos[videoIndex]['likes'] = (_videos[videoIndex]['likes'] ?? 0) + 1;
        } else {
          _videos[videoIndex]['likes'] = (_videos[videoIndex]['likes'] ?? 1) - 1;
        }
      }
      notifyListeners();
    }
    
    // Also update in liked videos list if it exists
    final likedVideoIndex = _likedVideos.indexWhere((video) => video['id'] == videoId);
    if (likedVideoIndex != -1) {
      _likedVideos[likedVideoIndex]['isLiked'] = isLiked;
      if (likeCount != null) {
        _likedVideos[likedVideoIndex]['likes'] = likeCount;
      } else {
        // Update likes count
        if (isLiked) {
          _likedVideos[likedVideoIndex]['likes'] = (_likedVideos[likedVideoIndex]['likes'] ?? 0) + 1;
        } else {
          _likedVideos[likedVideoIndex]['likes'] = (_likedVideos[likedVideoIndex]['likes'] ?? 1) - 1;
        }
      }
      notifyListeners();
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearVideos() {
    _videos.clear();
    _likedVideos.clear();
    notifyListeners();
  }
} 