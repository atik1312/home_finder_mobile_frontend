import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:home_finder_/auth/api_service.dart';
import 'package:home_finder_/auth/loggedUser.dart';
import 'package:home_finder_/models/posts.dart';
import 'package:latlong2/latlong.dart';

class CreatePost extends StatefulWidget {
  const CreatePost({super.key});

  static const String routeName = "/create-post";

  @override
  State<CreatePost> createState() => _CreatePostState();
}

class _CreatePostState extends State<CreatePost> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _houseNumberController = TextEditingController();
  final TextEditingController _geoLocationController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _rentPriceController = TextEditingController();

  final List<XFile> _selectedImages = [];
  final List<XFile> _selectedVideos = [];

  LatLng? _selectedLocation;

  bool _isSubmitting = false;
  bool _isRented = false;
  bool _onlyForMale = false;
  bool _onlyForFemale = false;

  @override
  void dispose() {
    _houseNumberController.dispose();
    _geoLocationController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _rentPriceController.dispose();
    super.dispose();
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _houseNumberController.clear();
    _geoLocationController.clear();
    _addressController.clear();
    _descriptionController.clear();
    _rentPriceController.clear();

    setState(() {
      _selectedImages.clear();
      _selectedVideos.clear();
      _selectedLocation = null;
      _isRented = false;
      _onlyForMale = false;
      _onlyForFemale = false;
    });
  }

  String _formatLocation(LatLng location) {
    return '${location.latitude.toStringAsFixed(6)},${location.longitude.toStringAsFixed(6)}';
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

  Future<void> _submitPost() async {
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

    if (_selectedImages.isEmpty && _selectedVideos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one image or one video.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final result = await ApiService.createPost(
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
        const SnackBar(content: Text('Post created successfully.')),
      );
      _clearForm();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.toString())),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loggedUser = LoggedUser.instance.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Post"),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  color: Color.fromARGB(255, 235, 245, 192),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Post owner',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          loggedUser == null
                              ? 'No logged-in user'
                              : '${loggedUser.name ?? 'User'}  •  ID ${loggedUser.userId ?? '-'}',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _houseNumberController,
                  decoration: const InputDecoration(
                    labelText: 'House number',
                    filled: true,
                    fillColor: const Color.fromARGB(255, 235, 245, 192),
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
                  controller: _geoLocationController,
                  decoration: const InputDecoration(
                    
                    filled: true,
                    fillColor: const Color.fromARGB(255, 235, 245, 192),
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
                const SizedBox(height: 8),
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
                const SizedBox(height: 12),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    filled: true,
                    fillColor: const Color.fromARGB(255, 235, 245, 192),
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
                    fillColor: const Color.fromARGB(255, 235, 245, 192),
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
                    fillColor: const Color.fromARGB(255, 235, 245, 192),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(15)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
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
                const SizedBox(height: 16),
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
                const SizedBox(height: 16),
                if (_selectedImages.isNotEmpty) ...[
                  const Text(
                    'Selected images',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selectedImages
                        .map((image) => Chip(label: Text(image.name)))
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                ],
                if (_selectedVideos.isNotEmpty) ...[
                  const Text(
                    'Selected videos',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selectedVideos
                        .map((video) => Chip(label: Text(video.name)))
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                ],
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitPost,
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
                        : const Text('Create post'),
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