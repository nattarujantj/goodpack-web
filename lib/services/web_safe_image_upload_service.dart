import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../config/env_config.dart';

class ImageUploadService {
  static final ImagePicker _picker = ImagePicker();

  // Upload product image - web safe version without compression
  static Future<Map<String, dynamic>> uploadProductImage({
    required String productId,
    required XFile imageFile,
    Function(double)? onProgress,
  }) async {
    try {
      print('Starting web-safe image upload for product: $productId');
      
      // Read file bytes directly
      final fileBytes = await imageFile.readAsBytes();
      print('File bytes read: ${fileBytes.length} bytes');
      
      // Debug: Check file signature
      if (fileBytes.length >= 3) {
        print('File signature: ${fileBytes[0].toRadixString(16).padLeft(2, '0')} ${fileBytes[1].toRadixString(16).padLeft(2, '0')} ${fileBytes[2].toRadixString(16).padLeft(2, '0')}');
        if (fileBytes[0] == 0xFF && fileBytes[1] == 0xD8 && fileBytes[2] == 0xFF) {
          print('Detected JPEG file');
        } else if (fileBytes[0] == 0x89 && fileBytes[1] == 0x50) {
          print('Detected PNG file');
        } else {
          print('Unknown file type');
        }
      }
      
      // Generate filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'product_${productId}_$timestamp.jpg';
      
      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${EnvConfig.apiUrl}/products/$productId/image'),
      );
      
      // Add headers
      request.headers.addAll({
        'Accept': 'application/json',
      });
      
      // Add file to request
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          fileBytes,
          filename: filename,
        ),
      );
      
      print('Sending request to: ${request.url}');
      
      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        try {
          final responseData = json.decode(response.body);
          return {
            'success': true,
            'data': responseData,
          };
        } catch (e) {
          print('Error parsing response JSON: $e');
          return {
            'success': true,
            'data': {'message': 'Image uploaded successfully'},
          };
        }
      } else {
        return {
          'success': false,
          'error': 'Upload failed with status: ${response.statusCode} - ${response.body}',
        };
      }
    } catch (e) {
      print('Web-safe image upload error: $e');
      return {
        'success': false,
        'error': 'Upload error: ${e.toString()}',
      };
    }
  }

  // Pick image from gallery
  static Future<XFile?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      print('Error picking image from gallery: $e');
      return null;
    }
  }

  // Pick image from camera
  static Future<XFile?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      print('Error picking image from camera: $e');
      return null;
    }
  }

  // Get image URL for display
  static String getImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return '';
    }
    
    // If it's already a full URL, return as is
    if (imagePath.startsWith('http')) {
      return imagePath;
    }
    
    // If it's a relative path, prepend the base URL
    return '${EnvConfig.apiUrl}$imagePath';
  }
}
