import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class CloudinaryService {
  /// Uploads an image to Cloudinary using an unsigned upload preset.
  /// 
  /// [imageBytes] The image data as bytes.
  /// [cloudName] The Cloudinary cloud name.
  /// [uploadPreset] The unsigned upload preset configured in Cloudinary.
  /// [fileName] Optional file name for the image.
  /// 
  /// Returns the secure URL of the uploaded image.
  static Future<String?> uploadImage({
    required List<int> imageBytes,
    required String cloudName,
    required String uploadPreset,
    String? fileName,
  }) async {
    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
    
    try {
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(
          http.MultipartFile.fromBytes(
            'file',
            imageBytes,
            filename: fileName ?? 'upload_${DateTime.now().millisecondsSinceEpoch}.jpg',
            contentType: MediaType('image', 'jpeg'),
          ),
        );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        final jsonMap = json.decode(responseBody);
        return jsonMap['secure_url'] as String?;
      } else {
        debugPrint('Cloudinary upload failed: ${response.statusCode} - $responseBody');
        return null;
      }
    } catch (e) {
      debugPrint('Error uploading to Cloudinary: $e');
      return null;
    }
  }
}
