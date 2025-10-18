import 'package:flutter/material.dart';
import '../config/env_config.dart';
import '../widgets/responsive_layout.dart';

class ImagePickerWidget extends StatelessWidget {
  final String? initialImageUrl;
  final Function(String) onImageSelected;

  const ImagePickerWidget({
    Key? key,
    this.initialImageUrl,
    required this.onImageSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey[300]!,
          style: BorderStyle.solid,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: initialImageUrl != null
          ? _buildImagePreview()
          : _buildPlaceholder(),
    );
  }

  Widget _buildImagePreview() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.network(
            initialImageUrl!,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.close,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () => onImageSelected(''),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return InkWell(
      onTap: _showImagePicker,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 8),
            ResponsiveText(
              'คลิกเพื่อเลือกรูปภาพ',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            ResponsiveText(
              'หรือลากไฟล์มาวางที่นี่',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImagePicker() {
    // For now, we'll simulate image selection
    // In a real app, you would use image_picker package
    onImageSelected(EnvConfig.placeholderImageUrl);
  }
}
