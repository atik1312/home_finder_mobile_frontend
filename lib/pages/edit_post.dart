import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:home_finder_/auth/api_service.dart';
import 'package:home_finder_/auth/loggedUser.dart';
import 'package:home_finder_/models/posts.dart';

class EditPost extends StatefulWidget {
  const EditPost({super.key, required this.post});

  final Post post;

  @override
  State<EditPost> createState() => _EditPostState();
}

class _EditPostState extends State<EditPost> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  late final TextEditingController _houseNumberController;
  late final TextEditingController _geoLocationController;
  late final TextEditingController _addressController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _rentPriceController;

  final List<XFile> _selectedImages = [];
  final List<XFile> _selectedVideos = [];

  LatLng? _selectedLocation;
  bool _isSubmitting = false;
  bool _isRented = false;
  bool _onlyForMale = false;
  bool _onlyForFemale = false;

  @override
  void initState() {
    super.initState();

    _houseNumberController = TextEditingController(text: widget.post.houseNumber ?? '');
    _geoLocationController = TextEditingController(text: widget.post.geoLocation ?? '');
    _addressController = TextEditingController(text: widget.post.address ?? '');
    _descriptionController = TextEditingController(text: widget.post.description ?? '');
    _rentPriceController = TextEditingController(text: widget.post.rentPrice ?? '');

    _isRented = widget.post.isRented ?? false;
    _onlyForMale = widget.post.onlyForBoys ?? false;
    _onlyForFemale = widget.post.onlyForGirls ?? false;
    _selectedLocation = _parseLocation(widget.post.geoLocation);
  }

  @override
  void dispose() {
    _houseNumberController.dispose();
    _geoLocationController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _rentPriceController.dispose();
    super.dispose();
  }

  List<_MediaItem> get _currentMedia => _buildMediaItems();

  LatLng? _parseLocation(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final parts = value.split(',');
    if (parts.length != 2) {
      return null;
    }

    final latitude = double.tryParse(parts[0].trim());
    final longitude = double.tryParse(parts[1].trim());

    if (latitude == null || longitude == null) {
      return null;
    }

    return LatLng(latitude, longitude);
  }

  String _formatLocation(LatLng location) {
    return '${location.latitude.toStringAsFixed(6)},${location.longitude.toStringAsFixed(6)}';
  }

  String _resolveMediaUrl(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }

    if (trimmed.startsWith('/')) {
      return '${ApiService.baseUrl}$trimmed';
    }

    return '${ApiService.baseUrl}/$trimmed';
  }

  void _applySelectedLocation(LatLng location) {
    setState(() {
      _selectedLocation = location;
      _geoLocationController.text = _formatLocation(location);
    });
  }

  Future<void> _openMapPicker() async {
    LatLng tempLocation = _selectedLocation ?? const LatLng(23.8103, 90.4125);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return SafeArea(
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return SizedBox(
                height: MediaQuery.of(context).size.height * 0.85,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Pick a location on the map',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Tap anywhere on the map to update the geo-location field.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: tempLocation,
                          initialZoom: 14,
                          onTap: (tapPosition, point) {
                            setSheetState(() {
                              tempLocation = point;
                            });
                          },
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.home_finder_',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: tempLocation,
                                width: 44,
                                height: 44,
                                child: const Icon(
                                  Icons.location_pin,
                                  color: Colors.red,
                                  size: 44,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            _formatLocation(tempLocation),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () {
                              _applySelectedLocation(tempLocation);
                              Navigator.pop(context);
                            },
                            child: const Text('Use this location'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _pickImages() async {
    final pickedImages = await _picker.pickMultiImage(imageQuality: 85);
    if (!mounted || pickedImages.isEmpty) {
      return;
    }

    setState(() {
      _selectedImages.addAll(pickedImages);
    });
  }

  Future<void> _pickVideo() async {
    final pickedVideo = await _picker.pickVideo(source: ImageSource.gallery);
    if (!mounted || pickedVideo == null) {
      return;
    }

    setState(() {
      _selectedVideos.add(pickedVideo);
    });
  }

  Future<void> _submitUpdate() async {
    final loggedUser = LoggedUser.instance.user;

    if (loggedUser?.userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No logged-in user found. Please log in again.')),
      );
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (_selectedImages.isEmpty && _selectedVideos.isEmpty && _currentMedia.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one image or one video.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final result = await ApiService.updatePost(
      postId: widget.post.id!,
      userId: loggedUser!.userId.toString(),
      houseNumber: _houseNumberController.text.trim(),
      geoLocation: _geoLocationController.text.trim(),
      address: _addressController.text.trim(),
      description: _descriptionController.text.trim(),
      rentPrice: _rentPriceController.text.trim(),
      isRented: _isRented,
      onlyForMale: _onlyForMale,
      onlyForFemale: _onlyForFemale,
      images: _selectedImages,
      videos: _selectedVideos,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isSubmitting = false;
    });

    if (result is Post) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post updated successfully.')),
      );
      Navigator.pop(context, true);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.toString())),
    );
  }

  Future<void> _deletePost() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete post?'),
          content: const Text('This will permanently remove the post.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm != true || widget.post.id == null) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final success = await ApiService.deletePost(widget.post.id!);

    if (!mounted) {
      return;
    }

    setState(() {
      _isSubmitting = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post deleted successfully.')),
      );
      Navigator.pop(context, true);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Failed to delete post.')),
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
      final url = video.streamUrl ?? video.video;
      if (url != null && url.isNotEmpty) {
        media.add(_MediaItem(type: _MediaType.video, url: url));
      }
    }

    return media;
  }

  Widget _buildSection({
    required String title,
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.86),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE9E0B8)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildMediaPreview(_MediaItem item) {
    final resolvedUrl = _resolveMediaUrl(item.url);

    if (item.type == _MediaType.image) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: 1,
          child: Image.network(
            resolvedUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: const Color(0xFFF4F0DD),
                alignment: Alignment.center,
                child: const Icon(Icons.image_not_supported_outlined),
              );
            },
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F1D9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7D89A)),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const Icon(Icons.play_circle_fill, color: Colors.brown),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.url,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loggedUser = LoggedUser.instance.user;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F1DF),
      appBar: AppBar(
        title: const Text('Edit Post'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _isSubmitting ? null : _deletePost,
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete post',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSection(
                  title: 'Post owner',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loggedUser == null
                            ? 'No logged-in user'
                            : '${loggedUser.name ?? 'User'}  •  ID ${loggedUser.userId ?? '-'}',
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Editing post #${widget.post.id ?? '-'}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                _buildSection(
                  title: 'Basic details',
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _houseNumberController,
                        decoration: const InputDecoration(
                          labelText: 'House number',
                          filled: true,
                          fillColor: Color.fromARGB(255, 235, 245, 192),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(15)),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'House number is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          labelText: 'Address',
                          filled: true,
                          fillColor: Color.fromARGB(255, 235, 245, 192),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(15)),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Address is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          alignLabelWithHint: true,
                          filled: true,
                          fillColor: Color.fromARGB(255, 235, 245, 192),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(15)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _rentPriceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Rent price',
                          alignLabelWithHint: true,
                          filled: true,
                          fillColor: Color.fromARGB(255, 235, 245, 192),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(15)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildSection(
                  title: 'Location',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _geoLocationController,
                        decoration: const InputDecoration(
                          filled: true,
                          fillColor: Color.fromARGB(255, 235, 245, 192),
                          labelText: 'Geo location',
                          hintText: '23.8103,90.4125',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(15)),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Geo location is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: _openMapPicker,
                        icon: const Icon(Icons.map_outlined),
                        label: const Text('Pick from map'),
                        style: OutlinedButton.styleFrom(
                          elevation: 5,
                          shadowColor: Colors.black45,
                          foregroundColor: Colors.black,
                          backgroundColor: const Color.fromARGB(255, 246, 250, 229),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                      if (_selectedLocation != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Selected: ${_formatLocation(_selectedLocation!)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
                _buildSection(
                  title: 'Property options',
                  child: Column(
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _isRented,
                        title: const Text('Already rented'),
                        onChanged: (value) {
                          setState(() {
                            _isRented = value;
                          });
                        },
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _onlyForMale,
                        title: const Text('Only for male'),
                        onChanged: (value) {
                          setState(() {
                            _onlyForMale = value;
                          });
                        },
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _onlyForFemale,
                        title: const Text('Only for female'),
                        onChanged: (value) {
                          setState(() {
                            _onlyForFemale = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                _buildSection(
                  title: 'Current media',
                  child: _currentMedia.isEmpty
                      ? Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F4E2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text('No media attached to this post yet.'),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _currentMedia.length,
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.95,
                              ),
                              itemBuilder: (context, index) {
                                return _buildMediaPreview(_currentMedia[index]);
                              },
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Existing media is shown here. Add more media below if you want to extend the post.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                ),
                _buildSection(
                  title: 'Add more media',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pickImages,
                              icon: const Icon(Icons.photo_library_outlined),
                              label: const Text('Add images'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.black,
                                backgroundColor: const Color.fromARGB(255, 246, 250, 229),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pickVideo,
                              icon: const Icon(Icons.video_library_outlined),
                              label: const Text('Add video'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.black,
                                backgroundColor: const Color.fromARGB(255, 246, 250, 229),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_selectedImages.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'New images',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _selectedImages.map((image) => Chip(label: Text(image.name))).toList(),
                        ),
                      ],
                      if (_selectedVideos.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'New videos',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _selectedVideos.map((video) => Chip(label: Text(video.name))).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                _buildSection(
                  title: 'Actions',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitUpdate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 242, 245, 207),
                          foregroundColor: Colors.black,
                          elevation: 5,
                          shadowColor: Colors.black45,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Update post'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _isSubmitting ? null : _deletePost,
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        label: const Text('Delete post'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.redAccent),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _MediaType { image, video }

class _MediaItem {
  const _MediaItem({required this.type, required this.url});

  final _MediaType type;
  final String url;
}
