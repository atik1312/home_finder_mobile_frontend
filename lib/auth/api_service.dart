import 'dart:convert';
import 'dart:developer';
import 'package:home_finder_/models/comments.dart';
import 'package:home_finder_/models/posts.dart';
import "package:http/http.dart" as http;
import 'package:image_picker/image_picker.dart';
import 'package:home_finder_/models/user.dart';

class ApiService {
  static const String _baseUrl = "https://shariar231.pythonanywhere.com";

  static Future<dynamic> logIn(String email, String password) async {

    final url="$_baseUrl/login/";
    try{
      final response=await http.post(Uri.parse(url),body: {
        "email":email,
        "password":password
      });
      if(response.statusCode==200){
        final json=jsonDecode(response.body);
        final user=User.fromJson(json["user"]);
        log(user.toString());
        return user;
      }
      else{
        return "Login failed: ${response.statusCode}";
      }


    }catch(e){
      return e.toString();
    }
    
  }

  static Future<dynamic> signUp(User user,String pass) async {
    final url="$_baseUrl/register/";

    try{
      final response=await http.post(Uri.parse(url),
      body:jsonEncode({
        "name":user.name,
        "email":user.email,
        "phone_number":user.phoneNumber,
        "password":pass
      }),
      headers: {
        "Content-Type":"application/json"
      }
      );

      if(response.statusCode==201){
        final json=jsonDecode(response.body);
        log(json.toString());
        return true;
      }
      else{
        return "Sign up failed: ${response.statusCode}";
      }


    }catch(e){
      return e.toString();
    }
  }
 
 
  static Future<dynamic> posts(String visibility,String? address) async {
    String url="$_baseUrl/posts/?visibility=$visibility";
    if (address != null && address.isNotEmpty) {
      url += "&address=$address";
    }
    try{
      final response=await http.get(Uri.parse(url),);
      if(response.statusCode==200){
        final json=jsonDecode(response.body);
        log(json.toString());
        return Post.fromJsonList(json);
      }
      else{
        return "Failed to fetch posts: ${response.statusCode}";
      }
    } catch(e) {
      log(e.toString());
      return e.toString();
    }
  }

  static Future<User?> getUser(num userId) async {
    final url="$_baseUrl/users/$userId/";
    try{
      final response=await http.get(Uri.parse(url));
      if(response.statusCode==200){
        final json=jsonDecode(response.body);
        log(json.toString());
        return User.fromJson(json);
      }
      else{
        log("Failed to fetch user: ${response.statusCode}");
        return null;
      }
    } catch(e) {
      log(e.toString());
      return null;
    }
  }
  static Future<bool> deletePost(num postId) async {
    final url="$_baseUrl/posts/delete/$postId/";
    try{
      final response=await http.delete(Uri.parse(url));
      log(  response.statusCode.toString());
      if(response.statusCode==204){
        log("Post deleted successfully");
        return true;
      }
      else{
        log("Failed to delete post: ${response.statusCode}");
        return false;
      }
    } catch(e) {
      log(e.toString());
      return false;
    }
  }
  static Future<dynamic> updateProfile(
  User user, {
  XFile? profilePicture,
}) async {
  final url = "$_baseUrl/users/${user.userId}/";

  try {
    final request = http.MultipartRequest('PATCH', Uri.parse(url));
    request.headers['Accept'] = 'application/json';

    request.fields['name'] = user.name ?? '';
    request.fields['email'] = user.email;
    request.fields['phone_number'] = user.phoneNumber;

    if (profilePicture != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'profile_picture',
          profilePicture.path,
        ),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      log(decoded.toString());

      if (decoded is List && decoded.isNotEmpty && decoded.first is Map<String, dynamic>) {
        return User.fromJson(decoded.first as Map<String, dynamic>);
      }

      if (decoded is Map<String, dynamic>) {
        if (decoded['user'] is Map<String, dynamic>) {
          return User.fromJson(decoded['user'] as Map<String, dynamic>);
        }
        return User.fromJson(decoded);
      }

      return decoded;
    } else {
      return "Profile update failed: ${response.statusCode} ${response.body}";
    }
  } catch (e) {
    return e.toString();
  }
}

  static Future<dynamic> createPost({
    required String userId,
    required String houseNumber,
    required String geoLocation,
    required String address,
    String? description,
    String? rentPrice,
    required bool isRented,
    required bool onlyForMale,
    required bool onlyForFemale,
    List<XFile> images = const [],
    List<XFile> videos = const [],
  }) async {
    final url="$_baseUrl/posts/create/";
    try{
      final request = http.MultipartRequest('POST', Uri.parse(url));
      request.headers['Accept'] = 'application/json';

      request.fields['user'] = userId;
      request.fields['house_number'] = houseNumber;
      request.fields['geo_location'] = geoLocation;
      request.fields['address'] = address;
      request.fields['is_rented'] = isRented.toString();
      request.fields['onlyfor_male'] = onlyForMale.toString();
      request.fields['onlyfor_female'] = onlyForFemale.toString();

      if (description != null && description.trim().isNotEmpty) {
        request.fields['description'] = description.trim();
      }

      if (rentPrice != null && rentPrice.trim().isNotEmpty) {
        request.fields['rent_price'] = rentPrice.trim();
      }

      for (final image in images) {
        request.files.add(
          await http.MultipartFile.fromPath('uploaded_images', image.path),
        );
      }

      for (final video in videos) {
        request.files.add(
          await http.MultipartFile.fromPath('uploaded_videos', video.path),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body);
        log(decoded.toString());

        if (decoded is Map<String, dynamic>) {
          if (decoded['post'] is Map<String, dynamic>) {
            return Post.fromJson(decoded['post']);
          }

          return Post.fromJson(decoded);
        }

        return decoded;
      }

      return "Create post failed: ${response.statusCode} ${response.body}";
    } catch (e) {
      log(e.toString());
      return e.toString();
    }
  }

  static Future<dynamic> addComment({
    required String postId,
    required String userId,
    required String comment,
  }) async {
    final url="$_baseUrl/comments/add/";
    try{
      final response=await http.post(Uri.parse(url),body: {
        "post":postId,
        "user":userId,
        "content":comment
      });
      log(response.statusCode.toString());
      if(response.statusCode==201){
        final json=jsonDecode(response.body);
        log(json.toString());
        return json;
      }
      else{
        return "Add comment failed: ${response.statusCode}";
      }
    }catch(e){
      log(e.toString());
      return e.toString();
    }
  }
  static Future<dynamic> getComments(num postId) async {
    final url="$_baseUrl/comments/$postId/";
    try{
      final response=await http.get(Uri.parse(url));
      log(  response.statusCode.toString());
      if(response.statusCode==200){
        final json=jsonDecode(response.body);
        log(json.toString());
        return json.map<Comments>((commentJson) => Comments.fromJson(commentJson)).toList();
      }
      else{
        return "Failed to fetch comments: ${response.statusCode}";
      }
    }catch(e){
      log(e.toString());
      return e.toString();
    }
  }
}
