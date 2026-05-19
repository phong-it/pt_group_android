import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProductImagePicker extends StatefulWidget {
  // Senior Tip: Truyền cả XFile (để upload) và bytes (để hiển thị/xử lý nhanh)
  final ValueChanged<List<XFile>> onImagesChanged;

  const ProductImagePicker({super.key, required this.onImagesChanged});

  @override
  State<ProductImagePicker> createState() => _ProductImagePickerState();
}

class _ProductImagePickerState extends State<ProductImagePicker> {
  final List<XFile> _selectedXFiles = [];
  final List<Uint8List> _displayBytes =
      []; // Lưu bytes để hiển thị trên Web/Mobile
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      final List<XFile>? images = await _picker.pickMultiImage();

      if (images == null || images.isEmpty) return;

      for (final xFile in images) {
        final bytes = await xFile.readAsBytes();
        _selectedXFiles.add(xFile);
        _displayBytes.add(bytes);
      }

      if (!mounted) return;
      setState(() {});
      widget.onImagesChanged(List<XFile>.from(_selectedXFiles));
    } catch (e) {
      debugPrint("Lỗi chọn ảnh: $e");
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedXFiles.removeAt(index);
      _displayBytes.removeAt(index);
    });
    widget.onImagesChanged(List<XFile>.from(_selectedXFiles));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hình ảnh sản phẩm *',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildAddButton(),
              const SizedBox(width: 12),
              if (_displayBytes.isNotEmpty)
                ...List.generate(_displayBytes.length, (index) {
                  return _buildImagePreview(index);
                }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.green.withOpacity(0.5), width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.add_a_photo_rounded, color: Colors.green, size: 32),
            SizedBox(height: 4),
            Text(
              'Thêm ảnh',
              style: TextStyle(
                color: Colors.green,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview(int index) {
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(right: 12),
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            // SỬA LỖI TẠI ĐÂY: Dùng Image.memory để không bị lỗi _Namespace trên Web
            child: Image.memory(
              _displayBytes[index],
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.error),
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 16,
          child: GestureDetector(
            onTap: () => _removeImage(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }
}
