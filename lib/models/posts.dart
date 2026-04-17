class Post {
  Post({
      this.id, 
      this.user, 
      this.houseNumber, 
      this.geoLocation, 
      this.images, 
      this.videos, 
      this.createdAt, 
      this.updatedAt, 
      this.description,
      this.rentPrice,
      this.isRented, 
      this.onlyForBoys,
      this.onlyForGirls,
      this.address,
      this.likes, 
      this.dislikes,});

  Post.fromJson(dynamic json) {
    id = json['id'];
    user = json['user'];
    description = json['description'];
    rentPrice = json['rent_price'];
    houseNumber = json['house_number'];
    geoLocation = json['geo_location'];
    onlyForBoys = json['only_for_boys'];
    onlyForGirls = json['only_for_girls'];
    address = json['address'];
    if (json['images'] != null) {
      images = [];
      json['images'].forEach((v) {
        images?.add(Images.fromJson(v));
      });
    }
    if (json['videos'] != null) {
      videos = [];
      json['videos'].forEach((v) {
        videos?.add(Videos.fromJson(v));
      });
    }
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    isRented = json['is_rented'];
    likes = json['likes'] != null ? json['likes'].cast<num>() : [];
    dislikes = json['dislikes'] != null ? json['dislikes'].cast<num>() : [];
  }
  num? id;
  num? user;
  bool? onlyForBoys;
  bool? onlyForGirls;
  String? address;
  String? houseNumber;
  String? geoLocation;
  String? description;
  String? rentPrice;
  List<Images>? images;
  List<Videos>? videos;
  String? createdAt;
  String? updatedAt;
  bool? isRented;
  List<num>? likes;
  List<num>? dislikes;
static List<Post> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((json) => Post.fromJson(json)).toList();
  }
Post copyWith({  num? id,
  num? user,
  String? houseNumber,
  String? geoLocation,
  String? description,
  String? rentPrice,
  List<Images>? images,
  List<Videos>? videos,
  String? createdAt,
  String? updatedAt,
  bool? isRented,
  bool? onlyForBoys,
  bool? onlyForGirls,
  String? address,
  List<num>? likes,
  List<num>? dislikes,
  Post? post,
}) => Post(  id: id ?? this.id,
  user: user ?? this.user,
  houseNumber: houseNumber ?? this.houseNumber,
  geoLocation: geoLocation ?? this.geoLocation,
  images: images ?? this.images,
  videos: videos ?? this.videos,
  createdAt: createdAt ?? this.createdAt,
  updatedAt: updatedAt ?? this.updatedAt,
  isRented: isRented ?? this.isRented,
  onlyForBoys: onlyForBoys ?? this.onlyForBoys,
  onlyForGirls: onlyForGirls ?? this.onlyForGirls,
  address: address ?? this.address,
  likes: likes ?? this.likes,
  dislikes: dislikes ?? this.dislikes,
);
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['user'] = user;
    map['description'] = description;
    map['rent_price'] = rentPrice;
    map['house_number'] = houseNumber;
    map['geo_location'] = geoLocation;
    map['onlyfor_male'] = onlyForBoys;
    map['onlyfor_female'] = onlyForGirls;
    map['address'] = address;
    if (images != null) {
      map['images'] = images?.map((v) => v.toJson()).toList();
    }
    if (videos != null) {
      map['videos'] = videos?.map((v) => v.toJson()).toList();
    }
    map['created_at'] = createdAt;
    map['updated_at'] = updatedAt;
    map['is_rented'] = isRented;
    map['likes'] = likes;
    map['dislikes'] = dislikes;
    return map;
  }

}

class Videos {
  Videos({
      this.id, 
      this.post, 
      this.video, 
      this.streamUrl,
      this.uploadedAt,});

  Videos.fromJson(dynamic json) {
    id = json['id'];
    post = json['post'];
    video = json['video'];
    streamUrl = json['stream_url'];
    uploadedAt = json['uploaded_at'];
  }
  num? id;
  num? post;
  String? video;
  String? streamUrl;
  String? uploadedAt;
Videos copyWith({  num? id,
  num? post,
  String? video,
  String? streamUrl,
  String? uploadedAt,
}) => Videos(  id: id ?? this.id,
  post: post ?? this.post,
  video: video ?? this.video,
  streamUrl: streamUrl ?? this.streamUrl,
  uploadedAt: uploadedAt ?? this.uploadedAt,
);
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['post'] = post;
    map['stream_url'] = streamUrl;
    map['video'] = video;
    map['uploaded_at'] = uploadedAt;
    return map;
  }

}

class Images {
  Images({
      this.id, 
      this.post, 
      this.image, 
      this.uploadedAt,});

  Images.fromJson(dynamic json) {
    id = json['id'];
    post = json['post'];
    image = json['image'];
    uploadedAt = json['uploaded_at'];
  }
  num? id;
  num? post;
  String? image;
  String? uploadedAt;
Images copyWith({  num? id,
  num? post,
  String? image,
  String? uploadedAt,
}) => Images(  id: id ?? this.id,
  post: post ?? this.post,
  image: image ?? this.image,
  uploadedAt: uploadedAt ?? this.uploadedAt,
);
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['post'] = post;
    map['image'] = image;
    map['uploaded_at'] = uploadedAt;
    return map;
  }

}