// lib/screens/post_detail_screen.dart

import 'package:flutter/material.dart';
import '../models/posts.dart';
import 'full_screen_image.dart';

class PostDetailScreen extends StatelessWidget {
  final Post post;

  const PostDetailScreen({Key? key, required this.post}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(post.title),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main image
            if (post.imageUrls.isNotEmpty)
              Hero(
                tag: post.imageUrls.first,
                child: Image.network(post.imageUrls.first),
              ),
            SizedBox(height: 16),

            // Details
            Text(
              post.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 8),
            Text('\$${post.price}', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text(post.description),

            SizedBox(height: 24),
            Text('Photos', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 8),

            // Thumbnails
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: post.imageUrls.map((url) {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => FullScreenImageScreen(imageUrl: url),
                    ));
                  },
                  child: Hero(
                    tag: url,
                    child: Image.network(
                      url,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
