import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String title;
  final String description;
  final String userId;
  final String price;      
  final List<String> imageUrls;
  final DateTime createdAt;

  Post({
    required this.id,
    required this.title,
    required this.description,
    required this.userId,
    required this.price,
    required this.imageUrls,
    required this.createdAt,
  });

  /// Firestore → Post
  factory Post.fromDocument(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return Post(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      price: data['price']?.toString() ?? '',  // convert to String
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }


  factory Post.fromMap(Map<String, dynamic> map) {
    return Post(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      userId: map['userId'] as String,
      price: map['price']?.toString() ?? '',
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : map['createdAt'] as DateTime,
    );
  }


  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'userId': userId,
      'price': price,    
      'imageUrls': imageUrls,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
