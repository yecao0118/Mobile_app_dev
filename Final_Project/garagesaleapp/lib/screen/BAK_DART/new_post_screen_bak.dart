import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path/path.dart' as path;

class NewPostScreen extends StatefulWidget {
  @override
  _NewPostScreenState createState() => _NewPostScreenState();
}

class _NewPostScreenState extends State<NewPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  List<XFile> _images = [];
  bool _isLoading = false;
  double? _uploadProgress;

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (pickedFile != null && _images.length < 4) {
        setState(() => _images.add(pickedFile));
      }
    } catch (e) {
      _showErrorSnackBar('Image picker error: ${e.toString()}');
    }
  }

  Future<void> _takePhoto() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (pickedFile != null && _images.length < 4) {
        setState(() => _images.add(pickedFile));
      }
    } catch (e) {
      _showErrorSnackBar('Camera error: ${e.toString()}');
    }
  }

  void _showSuccessSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Post created successfully!'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<List<String>> _uploadImages(String postId) async {
    List<String> imageUrls = [];
    try {
      for (var image in _images) {
        final file = File(image.path);
        final fileExtension = path.extension(image.path);
        final contentType = _getContentType(fileExtension);

        final metadata = SettableMetadata(
          contentType: contentType,
          cacheControl: 'public,max-age=31536000',
          customMetadata: {
            'uploaded_by': FirebaseAuth.instance.currentUser?.uid ?? 'unknown',
            'original_filename': path.basename(image.path),
          },
        );

        final ref = FirebaseStorage.instance
            .ref()
            .child('post_images/$postId/${DateTime.now().millisecondsSinceEpoch}$fileExtension');

        setState(() => _uploadProgress = 0);
        
        final uploadTask = ref.putFile(file, metadata);
        uploadTask.snapshotEvents.listen((taskSnapshot) {
          setState(() {
            _uploadProgress = taskSnapshot.bytesTransferred.toDouble() / 
                            taskSnapshot.totalBytes.toDouble();
          });
        });

        await uploadTask;
        final url = await ref.getDownloadURL();
        imageUrls.add(url);
      }
    } catch (e) {
      throw Exception('Image upload failed: $e');
    } finally {
      setState(() => _uploadProgress = null);
    }
    return imageUrls;
  }

  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      default:
        return 'application/octet-stream';
    }
  }

  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final postId = FirebaseFirestore.instance.collection('posts').doc().id;
      final imageUrls = _images.isNotEmpty ? await _uploadImages(postId) : [];

      await FirebaseFirestore.instance.collection('posts').doc(postId).set({
        'title': _titleController.text.trim(),
        'price': double.parse(_priceController.text.trim()),
        'description': _descriptionController.text.trim(),
        'imageUrls': imageUrls,
        'userId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'status': 'active', // Add post status
      });

      _showSuccessSnackBar();
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _showErrorSnackBar('Failed to create post: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showImageSourceDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Image'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('New Post'),
        actions: [
          IconButton(
            icon: Icon(Icons.check),
            onPressed: _isLoading ? null : _submitPost,
            tooltip: 'Submit Post',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a title' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(
                  labelText: 'Price',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value!.isEmpty) return 'Please enter a price';
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a description' : null,
              ),
              SizedBox(height: 20),
              Text(
                'Images (${_images.length}/4)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              if (_images.isEmpty)
                Text('No images added', style: TextStyle(color: Colors.grey)),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._images.map((image) => Stack(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: FileImage(File(image.path)),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: IconButton(
                          icon: Icon(Icons.close, size: 18),
                          color: Colors.red,
                          onPressed: () => setState(() => _images.remove(image)),
                        ),
                      ),
                    ],
                  )).toList(),
                  if (_images.length < 4)
                    GestureDetector(
                      onTap: _showImageSourceDialog,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.add_photo_alternate,
                          size: 32,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                ],
              ),
              if (_uploadProgress != null) ...[
                SizedBox(height: 16),
                LinearProgressIndicator(
                  value: _uploadProgress,
                  minHeight: 6,
                ),
                SizedBox(height: 8),
                Text(
                  'Uploading ${((_uploadProgress ?? 0) * 100).toStringAsFixed(0)}%',
                  textAlign: TextAlign.center,
                  
                ),
              ],
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitPost,
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text('Post Item'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}