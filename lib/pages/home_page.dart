import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:go_router/go_router.dart';
import 'package:home_finder_/auth/api_service.dart';
import 'package:home_finder_/auth/loggedUser.dart';
import 'package:home_finder_/models/posts.dart';
import 'package:home_finder_/models/user.dart';
import 'package:home_finder_/pages/create_post.dart';
import 'package:home_finder_/pages/edit_profile.dart';
import 'package:home_finder_/pages/my_post.dart';
import 'package:home_finder_/widgets/postItem.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.user});
  final User user;
  static const String routeName = "/home";

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Post> posts = [];
  TextEditingController _searchController = TextEditingController();
  @override
  void initState() {
    super.initState();
    fetchPosts();
    log(posts.length.toString());
  }
  
  
  void onDelete() async {
    await fetchPosts();
  }
  Future<void> fetchPosts() async {
    final fetchedPosts = await ApiService.posts("all", null);
    if (!mounted) return;

    setState(() {
      posts = fetchedPosts is List<Post> ? fetchedPosts : <Post>[];
    });
  }
  
  String? getUserProfileImage() {
    if (widget.user.profilePicture != null ) {
      return "https://shariar231.pythonanywhere.com/${widget.user.profilePicture}";
    }
    return 'https://cdn-icons-png.flaticon.com/512/9187/9187604.png';
  }
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Home Finder"),
         centerTitle: true,
         leading: null,
          elevation: 2,
          
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Color.fromARGB(255, 235, 245, 192),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: NetworkImage(getUserProfileImage()!),
                    ),
                    SizedBox(height: 10),
                    Text(
                      widget.user.name!,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                     Text(
                      widget.user.email,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                      overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                )
              ),
              ListTile(
                leading: Icon(Icons.home),
                title: Text('All Homes'),
                onTap: () async{
                  EasyLoading.show(status: "Loading...");
                  posts=await ApiService.posts( "all", null) as List<Post>;
                  setState(() {
                  });
                  EasyLoading.dismiss();
                  context.pop();
                },
              ),
              ListTile(
                leading: Icon(Icons.male_rounded),
                title: Text('Boys houses'),
                onTap: () async{
                  EasyLoading.show(status: "Loading...");
                  posts=await ApiService.posts( "male", null) as List<Post>;
                  log(posts.length.toString());
                  setState(() {
                  });
                  EasyLoading.dismiss();
                  context.pop();
                },
              ),
              ListTile(
                leading: Icon(Icons.female_rounded),
                title: Text('Girls houses'),
                onTap: ()async {
                  EasyLoading.show(status: "Loading...");
                  posts=await ApiService.posts( "female", null) as List<Post>;
                  setState(() {
                  });
                  EasyLoading.dismiss();
                  context.pop();
                },
              ),
              ListTile(
                leading: Icon(Icons.post_add_outlined),
                title: Text('My Post'),
                onTap: () {
      
                  Navigator.of(context).push(MaterialPageRoute(builder: (context)=>MyPosts(posts: posts, onDelete: onDelete,)));
                  
                },
              ),
               ListTile(
                leading: Icon(Icons.add),
                title: Text('Create Post'),
                onTap: () {
                  context.pop();
                  context.push(CreatePost.routeName);
                },
              ),
                 ListTile(
                leading: Icon(Icons.edit),
                title: Text('Edit Profile'),
                onTap: () {
                  context.pop();
                  Navigator.of(context).push(MaterialPageRoute(builder: (context)=>EditProfile()));
                },
              ),
              ListTile(
                leading: Icon(Icons.logout),
                title: Text('Logout'),
                onTap: () {
                  LoggedUser.instance.clearUser();
                  context.go("/login");
                },
              ),
            ],
          ),
        ),
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
             
              Padding(
                padding: const EdgeInsets.all(15),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Search for homes",
                    prefixIcon: IconButton(onPressed: ()async {
                      final query = _searchController.text;
                      EasyLoading.show(status: "Searching...");
                      posts = await ApiService.posts("all", query) as List<Post>;
                      setState(() {});
                      EasyLoading.dismiss();
      
                    }, icon: Icon(Icons.search)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Color.fromARGB(255, 235, 245, 192),
                  ),
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: fetchPosts,
                  child: posts.length>0?ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      log(posts[index].toString());
                      final post = posts[index];
                      if(post.user==widget.user.userId|| post.isRented!){
                        return SizedBox.shrink();
                      }
                      log(index.toString());
                      return PostItem(post: post);
                    },
                  ): Center(child: Text("No posts found")),
                ),
              ),
            ],
          ),
        ),
      
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            context.push(CreatePost.routeName);
          },
          backgroundColor: Colors.transparent,
          child: Icon(Icons.add,color: Colors.white,),
        ),
       
      ),
    );
  }
}
