import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProductImagePicker extends StatefulWidget {
  final Function(List<File>) onImagesChanged;

  const ProductImagePicker({super.key, required this.onImagesChanged});

  @override
  State<ProductImagePicker> createState() => _ProductImagePickerState();
}

class _ProductImagePickerState extends State<ProductImagePicker> {
  final List<File> _selectedImages = [];

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images.map((img) => File(img.path)));
      });
      // Bắn mảng ảnh mới về cho file chính
      widget.onImagesChanged(_selectedImages); 
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
    // Bắn mảng ảnh cập nhật về cho file chính
    widget.onImagesChanged(_selectedImages);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Hình ảnh sản phẩm *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // Nút thêm ảnh
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    color: Colors.green[50], borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green, width: 1.5),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo, color: Colors.green, size: 30),
                      SizedBox(height: 5),
                      Text('Thêm ảnh', style: TextStyle(color: Colors.green, fontSize: 12)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // List ảnh đã chọn
              ...List.generate(_selectedImages.length, (index) {
                return Stack(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(right: 10),
                      width: 100, height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(image: FileImage(_selectedImages[index]), fit: BoxFit.cover),
                      ),
                    ),
                    Positioned(
                      top: 0, right: 10,
                      child: GestureDetector(
                        onTap: () => _removeImage(index),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          child: const Icon(Icons.close, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
                );
              })
            ],
          ),
        ),
      ],
    );
  }
}