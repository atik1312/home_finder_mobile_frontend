import 'dart:async';
// import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:home_finder_/models/posts.dart';
import 'package:home_finder_/pages/post_item_screen.dart';
import 'package:video_player/video_player.dart';

class PostItem extends StatefulWidget {
  const PostItem({super.key, required this.post});
  final Post post;

  @override
  State<PostItem> createState() => _PostItemState();
}

class _PostItemState extends State<PostItem> {
  int _currentMediaIndex = 0;
  late List<_MediaItem> _mediaItems;
  final Map<int, VideoPlayerController> _videoControllers =
      <int, VideoPlayerController>{};
  final Set<int> _videoInitializing = <int>{};
  final Set<int> _videoInitQueued = <int>{};
  final Map<int, String> _videoErrors = <int, String>{};

  String _resolveMediaUrl(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return trimmed;

    return trimmed;
  }

  @override
  void initState() {
    super.initState();
    _mediaItems = _buildMediaItems();
    _prepareCurrentVideoIfNeeded();
  }

  @override
  void didUpdateWidget(covariant PostItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post != widget.post) {
      _disposeVideoControllers();
      _mediaItems = _buildMediaItems();
      _currentMediaIndex = 0;
      _prepareCurrentVideoIfNeeded();
    }
  }

  void _disposeVideoControllers() {
    for (final controller in _videoControllers.values) {
      controller.dispose();
    }
    _videoControllers.clear();
    _videoInitializing.clear();
    _videoInitQueued.clear();
    _videoErrors.clear();
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
    if (_videoControllers.containsKey(index) || _videoInitializing.contains(index)) {
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
      _videoErrors.remove(index);
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
        padding: const EdgeInsets.all(14),
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
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
            const SizedBox(height: 10),
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
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                size: 66,
                color: Colors.black,
              ),
            ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Container(
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

  List<_MediaItem> _buildMediaItems() {
    final media = <_MediaItem>[];

    for (final image in widget.post.images ?? <Images>[]) {
      final url = image.image;
      if (url != null && url.isNotEmpty) {
        media.add(_MediaItem(type: _MediaType.image, url: url));
      }
    }

    for (final video in widget.post.videos ?? <Videos>[]) {
      final videoId = video.id;
      final url = videoId != null ? video.streamUrl : video.video;
      if (url != null && url.isNotEmpty) {
        media.add(_MediaItem(type: _MediaType.video, url: url));
      }
    }

    return media;
  }

  @override
  Widget build(BuildContext context) {
    _mediaItems = _buildMediaItems();

    if (_currentMediaIndex >= _mediaItems.length && _mediaItems.isNotEmpty) {
      _currentMediaIndex = _mediaItems.length - 1;
    }

    return InkWell(
      onTap: () {
        Navigator.of( context).push(
          MaterialPageRoute(
            builder: (context) => PostItemScreen(post: widget.post),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Colors.white.withOpacity(0.8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_mediaItems.isNotEmpty) ...[
                SizedBox(
                  height: 210,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
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
                                child: Icon(Icons.broken_image, size: 48),
                              ),
                            ),
                          );
                        }
                        return _buildVideoSlide(index: index, mediaUrl: mediaUrl);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                if (_mediaItems.length > 1)
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
                              ? Colors.blueAccent
                              : Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
              ],
              Text(
                widget.post.houseNumber ?? "No house number",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.post.description?.trim().isNotEmpty == true
                    ? widget.post.description!
                    : 'No description',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Text(
                  widget.post.rentPrice != null
                      ? 'Price:${widget.post.rentPrice} tk.'
                      : 'Price: Not available',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.green.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _disposeVideoControllers();
    super.dispose();
  }
}

enum _MediaType { image, video }

class _MediaItem {
  const _MediaItem({required this.type, required this.url});

  final _MediaType type;
  final String url;
}