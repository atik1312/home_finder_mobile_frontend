import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:go_router/go_router.dart';
import 'package:home_finder_/auth/api_service.dart';
import 'package:home_finder_/auth/loggedUser.dart';
import 'package:home_finder_/models/posts.dart';
import 'package:home_finder_/widgets/postItem.dart';

class MyPosts extends StatefulWidget {
  const MyPosts({super.key, required this.posts, required this.onDelete});
  final List<Post> posts;
  final Function onDelete;
  @override
  State<MyPosts> createState() => _MyPostsState();
}

class _MyPostsState extends State<MyPosts> {
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("My Posts"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: widget.posts.length,
                      itemBuilder: (context, index) {
                        log(widget.posts[index].toString());
                        final post = widget.posts[index];
                        if(post.user!=LoggedUser.instance.user?.userId){
                          return SizedBox.shrink();
                        }
                        log(index.toString());
                        return Dismissible(
                          key: Key(post.id.toString()),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: Color.fromARGB(255, 243, 247, 198),
                            alignment: Alignment.centerRight,
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: Icon(Icons.delete, color: Colors.red,size: 50,),
                          ),
                          onDismissed: (direction) async {
                            EasyLoading.show(status: "Deleting Post...");
                            final success = await ApiService.deletePost(post.id!);
                            if (success) {
                              widget.onDelete();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Post deleted successfully')),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to delete post')),
                              );
                            }
                            EasyLoading.dismiss();
                          },
                          child: PostItem(post: post));
                      },
                    ),
          ),
          ElevatedButton(onPressed: (){
           context.push("/create-post");
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 243, 247, 198),
            foregroundColor: Colors.black,  
            elevation: 10,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0)
            )
           )
          
          , child: Text("Create New Post"))
        ],
      )
      );
    
  }
}