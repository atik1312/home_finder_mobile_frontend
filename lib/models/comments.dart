class Comments{
  final num? id;
  final num? post_id;
  final num? user_id;
  final String? userName;
  final String? userProfilePicture;
  final String? comment;
  final String? created_at;
  Comments({
    this.id,
    this.userProfilePicture,
    this.userName,
    required this.post_id,
    required this.user_id,
    required this.comment,
    required this.created_at
  });
  factory Comments.fromJson(Map<String, dynamic> json) {
    return Comments(
      id: json['id'],
      userName: json['user_name'],
      userProfilePicture: json['user_profile_picture'],
      post_id: json['post'] != null ? num.parse(json['post'].toString()) : null,
      user_id: json['user'] != null ? num.parse(json['user'].toString()) : null,
      comment: json['content'],
      created_at: json['created_at'],
    );
  }
  
}