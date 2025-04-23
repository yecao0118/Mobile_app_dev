
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:garagesaleapp/screen/new_post_screen_bak.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/posts.dart';
import 'post_detail_screen.dart';


import 'login_screen.dart';

class BrowsePostsScreen extends StatefulWidget {
  @override
  _BrowsePostsScreenState createState() => _BrowsePostsScreenState();
}

class _BrowsePostsScreenState extends State<BrowsePostsScreen> {
  List<Post> posts = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

Future<void> _loadPosts() async {
  setState(() {
    _isLoading = true;
  });

  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .get();

    final loaded = snapshot.docs
        .map<Post>((doc) => Post.fromDocument(doc))
        .toList();

    setState(() {
      posts = loaded;
    });

    debugPrint('🔍 Loaded ${loaded.length} posts');
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error loading posts: $e')),
    );
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}


  Future<void> _refreshPosts() => _loadPosts();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Hyper Garage Sales Posts'),
        actions: [
          if (user == null)
            IconButton(
              icon: Icon(Icons.login),
              tooltip: 'Login',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => LoginScreen()),
                );
              },
            )
          else
            IconButton(
              icon: Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Logged out')),
                );
                setState(() {}); 
              },
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : posts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.hourglass_empty, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('No posts yet', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _refreshPosts,
                  child: ListView.builder(
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      final post = posts[index];
                      return Card(
                        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        
                          child: ListTile(
                            onTap: () {
                              Navigator.push(
                                 context,
                                  MaterialPageRoute(
                                    builder: (_) => PostDetailScreen(post: post),
                            ),
                           );
                          },
                          leading: post.imageUrls.isNotEmpty
                              ? Hero(
                                  tag: post.id,
                                  child: Image.network(
                                    post.imageUrls.first,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Icon(Icons.image_not_supported),
                          title: Text(post.title),
                          subtitle: Text('\$${double.parse(post.price).toStringAsFixed(0)}'),
                          
                        ),
                         
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => NewPostScreen()),
          );
          if (result != null) {
            setState(() => posts.add(Post.fromMap(result)));
          }
        },
      ),
    );
  }
}