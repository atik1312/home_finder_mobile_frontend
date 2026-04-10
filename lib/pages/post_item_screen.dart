import 'dart:async';
import 'dart:developer';
import 'package:flutter/services.dart';

import 'package:flutter/material.dart';
import 'package:home_finder_/auth/api_service.dart';
import 'package:home_finder_/auth/loggedUser.dart';
import 'package:home_finder_/models/comments.dart';
import 'package:home_finder_/models/posts.dart';
import 'package:home_finder_/models/user.dart';
import 'package:video_player/video_player.dart';

class PostItemScreen extends StatefulWidget {
  const PostItemScreen({super.key, required this.post});
  final Post post;
  @override
  State<PostItemScreen> createState() => _PostItemScreenState();
}

class _PostItemScreenState extends State<PostItemScreen> {
  static const MethodChannel _callChannel = MethodChannel('home_finder/call');
  static const MethodChannel _emailChannel = MethodChannel('home_finder/email');
  static const MethodChannel _mapChannel = MethodChannel('home_finder/map');
  late final Future<User?> _userFuture;
  late Future<List<Comments>> _commentsFuture;
  final TextEditingController _commentController = TextEditingController();
  int _currentMediaIndex = 0;
  late final List<_MediaItem> _mediaItems;
  final Map<int, VideoPlayerController> _videoControllers =
      <int, VideoPlayerController>{};
  final Set<int> _videoInitializing = <int>{};
  final Set<int> _videoInitQueued = <int>{};
  final Map<int, String> _videoErrors = <int, String>{};

  @override
  void initState() {
    super.initState();
    _userFuture = _getUserDetails();
    _commentsFuture = _loadComments();
    _mediaItems = _buildMediaItems();
    _prepareCurrentVideoIfNeeded();
  }

  Future<List<Comments>> _loadComments() async {
    final postId = widget.post.id;
    if (postId == null) {
      return <Comments>[];
    }

    final result = await ApiService.getComments(postId);
    if (result is List<Comments>) {
      return result;
    }

    if (result is String) {
      throw Exception(result);
    }

    return <Comments>[];
  }

  void _refreshComments() {
    if (!mounted) return;
    setState(() {
      _commentsFuture = _loadComments();
    });
  }

  Future<User?> _getUserDetails() async {
    final userId = widget.post.user;
    if (userId == null) {
      return null;
    }

    final result = await ApiService.getUser(userId);
    return result is User ? result : null;
  }

  List<_MediaItem> _buildMediaItems() {
    final media = <_MediaItem>[];

    for (final image in widget.post.images ?? <Images>[]) {
      final url = image.image;
      if (url != null && url.isNotEmpty) {
        media.add(_MediaItem(type: _MediaType.image, url: url));
      }
    }

    for (final video in widget.post.videos ?? <Videos>[]) {
      final url = video.streamUrl ?? video.video;
      if (url != null && url.isNotEmpty) {
        media.add(_MediaItem(type: _MediaType.video, url: url));
      }
    }

    return media;
  }

  String _resolveMediaUrl(String rawUrl) {
    final trimmed = rawUrl.trim();
    return trimmed;
  }

  void _scheduleEnsureVideoController(int index) {
    if (_videoControllers.containsKey(index) ||
        _videoInitializing.contains(index) ||
        _videoInitQueued.contains(index)) {
      return;
    }

    _videoInitQueued.add(index);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _videoInitQueued.remove(index);
      if (!mounted) return;
      _ensureVideoController(index);
    });
  }

  Future<void> _prepareCurrentVideoIfNeeded() async {
    if (_mediaItems.isEmpty || _currentMediaIndex >= _mediaItems.length) {
      return;
    }

    final item = _mediaItems[_currentMediaIndex];
    if (item.type != _MediaType.video) return;
    await _ensureVideoController(_currentMediaIndex);
  }

  Future<void> _ensureVideoController(int index) async {
    if (index < 0 || index >= _mediaItems.length) return;

    final item = _mediaItems[index];
    if (item.type != _MediaType.video) return;
    if (_videoControllers.containsKey(index) ||
        _videoInitializing.contains(index)) {
      return;
    }

    final videoUrl = _resolveMediaUrl(item.url);
    final controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
    _videoControllers[index] = controller;
    _videoInitializing.add(index);
    _videoErrors.remove(index);

    try {
      await controller.initialize().timeout(
        const Duration(seconds: 12),
        onTimeout: () {
          throw TimeoutException('Timed out while loading video (12s)');
        },
      );
      await controller.setLooping(true);
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      await controller.dispose();
      _videoControllers.remove(index);
      _videoErrors[index] = e.toString();
      if (mounted) {
        setState(() {});
      }
    } finally {
      _videoInitializing.remove(index);
    }
  }

  Future<void> _retryVideo(int index) async {
    final existing = _videoControllers[index];
    if (existing != null) {
      await existing.dispose();
      _videoControllers.remove(index);
    }
    _videoErrors.remove(index);
    if (mounted) {
      setState(() {});
    }
    await _ensureVideoController(index);
  }

  Future<void> _callPhoneNumber(String phoneNumber) async {
    final cleanedNumber = phoneNumber.trim();
    if (cleanedNumber.isEmpty) return;

    try {
      await _callChannel.invokeMethod<void>('call', <String, String>{
        'phoneNumber': cleanedNumber,
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open the phone dialer: $e')),
      );
    }
  }

  Future<void> _emailOwner(String emailAddress) async {
    final cleanedEmail = emailAddress.trim();
    if (cleanedEmail.isEmpty) return;

    try {
      await _emailChannel.invokeMethod<void>('email', <String, String>{
        'emailAddress': cleanedEmail,
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open the email app: $e')),
      );
    }
  }

  Future<void> _openGeoLocation(String geoLocation) async {
    final cleanedLocation = geoLocation.trim();
    if (cleanedLocation.isEmpty) return;

    try {
      await _mapChannel.invokeMethod<void>('map', <String, String>{
        'geoLocation': cleanedLocation,
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open the map app: $e')),
      );
    }
  }

  Future<void> _submitComment() async {
    final loggedUser = LoggedUser.instance.user;
    final postId = widget.post.id;
    final commentText = _commentController.text.trim();

    if (postId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This post does not have a valid ID.')),
      );
      return;
    }

    if (loggedUser?.userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You need to be logged in to comment.')),
      );
      return;
    }

    if (commentText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Write a comment first.')),
      );
      return;
    }

    try {
      final result = await ApiService.addComment(
        postId: postId.toString(),
        userId: loggedUser!.userId.toString(),
        comment: commentText,
      );

      if (result is String) {
        throw Exception(result);
      }

      _commentController.clear();
      _refreshComments();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comment posted.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not post comment: $e')),
      );
    }
  }

  void _pauseVideosExcept(int keepIndex) {
    for (final entry in _videoControllers.entries) {
      if (entry.key == keepIndex) continue;
      if (entry.value.value.isInitialized && entry.value.value.isPlaying) {
        entry.value.pause();
      }
    }
  }

  void _toggleVideoAt(int index) {
    final controller = _videoControllers[index];
    if (controller == null || !controller.value.isInitialized) return;

    if (controller.value.isPlaying) {
      controller.pause();
    } else {
      _pauseVideosExcept(index);
      controller.play();
    }
    setState(() {});
  }

  Widget _buildVideoSlide({required int index, required String mediaUrl}) {
    _scheduleEnsureVideoController(index);
    final controller = _videoControllers[index];
    final errorText = _videoErrors[index];

    if (errorText != null) {
      return Container(
        color: Colors.black87,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.white70, size: 34),
            const SizedBox(height: 8),
            const Text(
              'Video failed to load',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              errorText,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => _retryVideo(index),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white60),
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (controller == null || !controller.value.isInitialized) {
      return Container(
        color: Colors.black87,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return GestureDetector(
      onTap: () => _toggleVideoAt(index),
      child: Stack(
        fit: StackFit.expand,
        children: [
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: controller.value.size.width,
              height: controller.value.size.height,
              child: VideoPlayer(controller),
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                controller.value.isPlaying ? 'Pause' : 'Play',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
          if (!controller.value.isPlaying)
            const Center(
              child: Icon(
                Icons.play_circle_fill,
                size: 68,
                color: Colors.white70,
              ),
            ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                mediaUrl,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaSection() {
    if (_mediaItems.isEmpty) {
      return Container(
        height: 260,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueGrey.shade900, Colors.blueGrey.shade700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.home_outlined, size: 56, color: Colors.white70),
              SizedBox(height: 12),
              Text(
                'No media uploaded for this post',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: AspectRatio(
            aspectRatio: 1.12,
            child: PageView.builder(
              itemCount: _mediaItems.length,
              onPageChanged: (index) {
                setState(() {
                  _currentMediaIndex = index;
                });
                _pauseVideosExcept(index);
                _prepareCurrentVideoIfNeeded();
              },
              itemBuilder: (context, index) {
                final item = _mediaItems[index];
                final mediaUrl = _resolveMediaUrl(item.url);
                if (item.type == _MediaType.image) {
                  return Image.network(
                    mediaUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey.shade300,
                      child: const Center(
                        child: Icon(Icons.broken_image_outlined, size: 48),
                      ),
                    ),
                  );
                }
                return _buildVideoSlide(index: index, mediaUrl: mediaUrl);
              },
            ),
          ),
        ),
        if (_mediaItems.length > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _mediaItems.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _currentMediaIndex == index ? 18 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: _currentMediaIndex == index
                      ? Colors.tealAccent.shade700
                      : Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDetailChip({required IconData icon, required String label}) {
    log(label);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white70),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Color(0xFFFFF8E8),
        border: Border.all(color: Color(0xFFF3D9A4)),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.blueGrey.shade50,
              child: Icon(icon, size: 18, color: Colors.blueGrey.shade700),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection(User user) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade700, Colors.teal.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Contact Owner',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white.withOpacity(0.18),
                backgroundImage: user.profilePicture != null &&
                        user.profilePicture!.trim().isNotEmpty
                    ? NetworkImage(user.profilePicture!)
                    : null,
                child: user.profilePicture == null ||
                        user.profilePicture!.trim().isEmpty
                    ? const Icon(Icons.person, color: Colors.white, size: 30)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name?.trim().isNotEmpty == true
                          ? user.name!
                          : 'Unknown user',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Verified contact for this listing',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                InkWell(
                  onTap: () => _emailOwner(user.email),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.email_outlined, color: Colors.white70),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            user.email,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.white70,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => _callPhoneNumber(user.phoneNumber),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.phone_outlined, color: Colors.white70),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            user.phoneNumber,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.white70,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCommentTimestamp(String timestamp) {
    final parsed = DateTime.tryParse(timestamp);
    if (parsed == null) {
      return timestamp;
    }

    final local = parsed.toLocal();
    final year = local.year.toString();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute';
  }

  Widget _buildCommentComposer() {
    final loggedUser = LoggedUser.instance.user;
    final canComment = loggedUser?.userId != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blueGrey.shade900, Colors.blueGrey.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Write a Comment',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            canComment
                ? 'Your comment will be posted as ${loggedUser?.name ?? 'User #${loggedUser?.userId}'}.'
                : 'Log in to post a comment.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.82),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _commentController,
            enabled: canComment,
            maxLines: 4,
            minLines: 3,
            style: const TextStyle(color: Colors.white),
            cursorColor: Colors.tealAccent,
            decoration: InputDecoration(
              hintText: canComment
                  ? 'Share your thoughts about this property...'
                  : 'You must be logged in to comment',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.55)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.08),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.tealAccent),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: canComment ? _submitComment : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.tealAccent.shade700,
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.send_outlined),
              label: const Text(
                'Post Comment',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsSection() {
    return FutureBuilder<List<Comments>>(
      future: _commentsFuture,
      builder: (context, snapshot) {
        final comments = snapshot.data ?? <Comments>[];

        Widget commentsBody;
        if (snapshot.connectionState == ConnectionState.waiting) {
          commentsBody = const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          commentsBody = Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Could not load comments: ${snapshot.error}',
              style: TextStyle(color: Colors.red.shade700),
            ),
          );
        } else if (comments.isEmpty) {
          commentsBody = Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'No comments yet. Be the first to respond.',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
            ),
          );
        } else {
          commentsBody = Column(
            children: [
              for (final comment in comments) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FBFD),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE3EBF3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.blueGrey.shade100,
                            backgroundImage: NetworkImage(comment.userProfilePicture ?? "https://cdn-icons-png.flaticon.com/512/9187/9187604.png"),
                            child: SizedBox.shrink()
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              comment.userName!,
                              style: TextStyle(
                                color: Colors.blueGrey.shade900,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            _formatCommentTimestamp(comment.created_at!),
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        comment.comment ?? 'No comment available',
                        style: TextStyle(
                          color: Colors.blueGrey.shade900,
                          fontSize: 14,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ],
          );
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFF7FAFC),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE5ECF3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Comments',
                    style: TextStyle(
                      color: Colors.blueGrey.shade900,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (comments.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${comments.length}',
                        style: TextStyle(
                          color: Colors.teal.shade800,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              _buildCommentComposer(),
              const SizedBox(height: 16),
              commentsBody,
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(User? user) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 80,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          surfaceTintColor: Colors.white,
          elevation: 0,
          title: const Text(
            'Post Details',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMediaSection(),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _buildDetailChip(
                      icon: Icons.price_change_outlined,
                      label: widget.post.rentPrice != null
                          ? '\$${widget.post.rentPrice}'
                          : 'Price unavailable',
                    ),
                    _buildDetailChip(
                      icon: Icons.house_outlined,
                      label: widget.post.houseNumber?.trim().isNotEmpty == true
                          ? widget.post.houseNumber!
                          : 'House number not set',
                    ),
                    _buildDetailChip(
                      icon: Icons.home_filled,
                      label: widget.post.address?.trim().isNotEmpty == true
                          ? widget.post.address!
                          : 'Location unavailable',
                    ),
                    _buildDetailChip(
                      icon: Icons.location_on_outlined,
                      label: widget.post.address?.trim().isNotEmpty == true
                          ? widget.post.address!
                          : 'Location unavailable',
                    ),
                    _buildDetailChip(
                      icon: widget.post.isRented == true
                          ? Icons.event_busy_outlined
                          : Icons.event_available_outlined,
                      label: widget.post.isRented == true ? 'Rented' : 'Available',
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  'Description',
                  style: TextStyle(
                    color: Colors.blueGrey.shade900,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFF3D9A4)),
                  ),
                  child: Text(
                    widget.post.description?.trim().isNotEmpty == true
                        ? widget.post.description!
                        : 'No description provided for this post.',
                    style: TextStyle(
                      color: Colors.blueGrey.shade900,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Property Details',
                  style: TextStyle(
                    color: Colors.blueGrey.shade900,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                _buildInfoRow(
                  'House Number',
                  widget.post.houseNumber?.trim().isNotEmpty == true
                      ? widget.post.houseNumber!
                      : 'Not available',
                  icon: Icons.home_outlined,
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: widget.post.geoLocation?.trim().isNotEmpty == true
                      ? () => _openGeoLocation(widget.post.geoLocation!)
                      : null,
                  borderRadius: BorderRadius.circular(18),
                  child: _buildInfoRow(
                    'Location',
                    widget.post.geoLocation?.trim().isNotEmpty == true
                        ? widget.post.geoLocation!
                        : 'Not available',
                    icon: Icons.place_outlined,
                  ),
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                    'Address',
                    widget.post.address?.trim().isNotEmpty == true
                        ? widget.post.address!
                        : 'Not available',
                    icon: Icons.place_outlined,
                  ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Rent Price',
                  widget.post.rentPrice != null
                      ? '\$${widget.post.rentPrice}'
                      : 'Not available',
                  icon: Icons.payments_outlined,
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Status',
                  widget.post.isRented == true ? 'Rented' : 'Available',
                  icon: widget.post.isRented == true
                      ? Icons.block_outlined
                      : Icons.check_circle_outline,
                ),
                const SizedBox(height: 18),
                if (user != null) _buildContactSection(user),
                if (user == null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3FBFA),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFCFEDEA)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Contact Owner',
                          style: TextStyle(
                            color: Colors.blueGrey.shade900,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'User contact details are not available for this post.',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 18),
                _buildCommentsSection(),
                const SizedBox(height: 18),
                if (widget.post.images != null &&
                    widget.post.images!.isNotEmpty) ...[
                  Text(
                    'Images',
                    style: TextStyle(
                      color: Colors.blueGrey.shade900,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 110,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.post.images!.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final imageUrl = widget.post.images![index].image;
                        if (imageUrl == null || imageUrl.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.grey.shade300,
                                child: const Icon(Icons.broken_image_outlined),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
                if (widget.post.videos != null &&
                    widget.post.videos!.isNotEmpty) ...[
                  Text(
                    'Videos',
                    style: TextStyle(
                      color: Colors.blueGrey.shade900,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 180,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.post.videos!.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final video = widget.post.videos![index];
                        final videoUrl = video.streamUrl ?? video.video;
                        if (videoUrl == null || videoUrl.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return Container(
                          width: 220,
                          child: _buildVideoCard(videoUrl),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoCard(String videoUrl) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black87, Colors.blueGrey.shade900],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          const Center(
            child: Icon(Icons.play_circle_fill, color: Colors.white70, size: 54),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.black.withOpacity(0.45),
              child: Text(
                _resolveMediaUrl(videoUrl),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User?>(
      future: _userFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Container(
              color: Colors.white,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        final user = snapshot.data;
        return Scaffold(
          backgroundColor: Colors.white,
          body: _buildBody(user),
        );
      },
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    for (final controller in _videoControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}

class _MediaItem {
  const _MediaItem({required this.type, required this.url});

  final _MediaType type;
  final String url;
}

enum _MediaType { image, video }