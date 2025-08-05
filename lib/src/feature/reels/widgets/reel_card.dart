import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:libas_app/src/common/services/real_api_service.dart';
import 'package:libas_app/src/common/services/data_change_service.dart';

class ReelCard extends StatefulWidget {
  final Map<String, dynamic> video;
  final VoidCallback? onTap;

  const ReelCard({
    Key? key,
    required this.video,
    this.onTap,
  }) : super(key: key);

  @override
  State<ReelCard> createState() => _ReelCardState();
}

class _ReelCardState extends State<ReelCard> {
  final RealApiService _apiService = RealApiService();
  final DataChangeService _dataChangeService = DataChangeService();
  
  bool _isLiked = false;
  bool _isLoading = false;
  int _likeCount = 0;
  int _commentCount = 0;
  String? _userComment;
  Map<String, dynamic>? _userLikeData;

  @override
  void initState() {
    super.initState();
    _loadLikeData();
    _setupLikesChangeListener();
  }

  void _setupLikesChangeListener() {
    _dataChangeService.likesChanges.listen((event) {
      if (kDebugMode) {
        print('🔄 ReelCard: Likes change detected, refreshing like data');
      }
      _loadLikeData();
    });
  }

  Future<void> _loadLikeData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Get user's like status for this video
      final userLikeStatus = await _apiService.getUserLikeStatus(widget.video['id']);
      setState(() {
        _isLiked = userLikeStatus['hasLiked'] ?? false;
        _userComment = userLikeStatus['like']?['comments'];
        _userLikeData = userLikeStatus['like'];
      });

      // Get video likes and comments count
      final videoLikes = await _apiService.getVideoLikes(widget.video['id']);
      setState(() {
        _likeCount = videoLikes['totalLikes'] ?? 0;
        _commentCount = videoLikes['totalComments'] ?? 0;
      });

      if (kDebugMode) {
        print('❤️ ReelCard: Loaded like data - isLiked: $_isLiked, likeCount: $_likeCount, commentCount: $_commentCount');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ ReelCard: Error loading like data: $e');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleLike() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final newLikeStatus = !_isLiked;
      final response = await _apiService.toggleLike(
        videoId: widget.video['id'],
        isLiked: newLikeStatus,
        comments: _userComment,
      );

      if (response['success'] == true) {
        setState(() {
          _isLiked = newLikeStatus;
        });
        
        // Refresh like counts
        await _loadLikeData();

        if (kDebugMode) {
          print('❤️ ReelCard: Like toggled successfully to: $_isLiked');
        }
      } else {
        if (kDebugMode) {
          print('❌ ReelCard: Failed to toggle like: ${response['message']}');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to ${newLikeStatus ? 'like' : 'unlike'} video')),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ ReelCard: Error toggling like: $e');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error ${_isLiked ? 'unliking' : 'liking'} video')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addComment() async {
    final TextEditingController commentController = TextEditingController(text: _userComment ?? '');
    
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
        setState(() {
          _isLoading = true;
        });

        // If user doesn't have a like record yet, create one with the comment
        if (_userLikeData == null) {
          final response = await _apiService.toggleLike(
            videoId: widget.video['id'],
            isLiked: _isLiked,
            comments: result.trim(),
          );
          
          if (response['success'] == true) {
            _userLikeData = response['data'];
          }
        } else {
          // Update existing like with new comment
          final response = await _apiService.updateComment(_userLikeData!['id'], result.trim());
          
          if (response['success'] == true) {
            _userLikeData = response['data'];
          }
        }

        setState(() {
          _userComment = result.trim();
        });

        // Refresh comment count
        await _loadLikeData();

        if (kDebugMode) {
          print('💬 ReelCard: Comment added successfully');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comment added successfully')),
        );
      } catch (e) {
        if (kDebugMode) {
          print('❌ ReelCard: Error adding comment: $e');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error adding comment')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Video thumbnail or placeholder
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.video_library,
                    size: 48,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.video['title'] ?? 'Video ${widget.video['id']}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Video title and description
                Text(
                  widget.video['title'] ?? 'Untitled Video',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.video['description'] ?? 'No description available',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 12),
                
                // Like and comment counts
                Row(
                  children: [
                    Icon(
                      Icons.favorite,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$_likeCount',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.comment,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$_commentCount',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // User comment if exists
                if (_userComment != null && _userComment!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your comment:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _userComment!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _toggleLike,
                        icon: Icon(
                          _isLiked ? Icons.favorite : Icons.favorite_border,
                          color: _isLiked ? Colors.red : null,
                        ),
                        label: Text(_isLiked ? 'Unlike' : 'Like'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isLiked ? Colors.red[50] : null,
                          foregroundColor: _isLiked ? Colors.red : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _addComment,
                        icon: const Icon(Icons.comment),
                        label: const Text('Comment'),
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