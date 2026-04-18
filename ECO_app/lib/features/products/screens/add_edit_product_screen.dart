import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; 
import '../models/product_model.dart';
import '../providers/product_provider.dart'; // Import Provider
import 'location_picker_screen.dart'; 
import '../service/product_image_picker.dart'; // Import file vừa tách

class AddProductScreen extends StatefulWidget {
  final ProductModel? existingProduct;
  const AddProductScreen({super.key, this.existingProduct});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descController = TextEditingController();
  
  String _selectedCategory = 'Điện tử';
  double _conditionPercent = 90;
  LatLng? _selectedLocation;
  List<File> _selectedImages = []; // Biến lưu ảnh lấy từ file con
  
  final List<String> _categories = ['Điện tử', 'Thời trang', 'Nội thất', 'Sách', 'Khác'];

  @override
  void initState() {
    super.initState();
    if (widget.existingProduct != null) {
      final p = widget.existingProduct!;
      _nameController.text = p.name;
      _priceController.text = p.price.toStringAsFixed(0);
      _descController.text = p.description;
      _selectedCategory = p.category;
      _conditionPercent = p.conditionPercent.toDouble();
      
      // ĐÃ FIX: Nạp lại tọa độ cũ để tránh lỗi Null
      _selectedLocation = LatLng(p.lat, p.lng); 
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.existingProduct != null ? 'Sửa thông tin' : 'Đăng bán món đồ', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. GỌI COMPONENT CHỌN ẢNH VÀO ĐÂY (Siêu gọn)
            ProductImagePicker(
              onImagesChanged: (images) {
                setState(() => _selectedImages = images);
              },
            ),
            const SizedBox(height: 24),

            // 2. CÁC INPUT THÔNG TIN
            _buildModernInput(label: 'Tên món đồ *', controller: _nameController, hint: 'Vd: Laptop Dell Inspiron cũ'),
            const SizedBox(height: 16),
            _buildModernInput(label: 'Giá bán (VNĐ) *', controller: _priceController, hint: 'Vd: 5000000', isNumber: true),
            const SizedBox(height: 16),

            // 3. DANH MỤC
            const Text('Danh mục *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory, isExpanded: true,
                  items: _categories.map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
                  onChanged: (newValue) => setState(() => _selectedCategory = newValue!),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 4. BẢN ĐỒ
            const Text('Vị trí hiển thị trên bản đồ *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.location_on, color: Colors.red),
              title: Text(_selectedLocation == null ? 'Chưa chọn vị trí' : 'Đã ghim vị trí'),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[200], foregroundColor: Colors.black),
                onPressed: () async {
                  final LatLng? result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const LocationPickerScreen()));
                  if (result != null) setState(() => _selectedLocation = result);
                },
                child: const Text('Mở Bản đồ'),
              ),
            ),
            const SizedBox(height: 24),

            // 5. TÌNH TRẠNG & MÔ TẢ
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tình trạng mới', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('${_conditionPercent.toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 18)),
              ],
            ),
            Slider(
              value: _conditionPercent, min: 10, max: 100, divisions: 9, activeColor: Colors.orange,
              onChanged: (value) => setState(() => _conditionPercent = value),
            ),
            const SizedBox(height: 16),
            _buildModernInput(label: 'Mô tả chi tiết *', controller: _descController, hint: 'Nêu rõ tình trạng...', maxLines: 4),
            const SizedBox(height: 40),
          ],
        ),
      ),
      
      // THÀNH PHẦN BOTTOM BAR DÙNG PROVIDER
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, -5))]),
          child: Consumer<ProductProvider>(
            builder: (context, provider, child) {
              return ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: provider.isLoading ? null : () => _submitForm(context, provider),
                child: provider.isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                    : Text(widget.existingProduct != null ? 'CẬP NHẬT' : 'ĐĂNG BÁN NGAY', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              );
            }
          ),
        ),
      ),
    );
  }

  // Hàm xử lý Logic Submit (Tách ra đây cho build đỡ dài)
  Future<void> _submitForm(BuildContext context, ProductProvider provider) async {
    // ĐÃ FIX: Check Validate Location trước khi gọi Tọa độ
    if (_nameController.text.isEmpty || _priceController.text.isEmpty || _selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập đủ thông tin và chọn lại ảnh!'), backgroundColor: Colors.red));
      return;
    }
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng ghim vị trí bán hàng!'), backgroundColor: Colors.red));
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    String? errorMessage;
    if (widget.existingProduct != null) {
      errorMessage = await provider.updateProduct(
        productId: widget.existingProduct!.id, name: _nameController.text.trim(),
        category: _selectedCategory, description: _descController.text.trim(),
        price: double.tryParse(_priceController.text.trim()) ?? 0,
        conditionPercent: _conditionPercent.toInt(), newImages: _selectedImages,
        lat: _selectedLocation!.latitude, lng: _selectedLocation!.longitude,
      );
    } else {
      errorMessage = await provider.addProduct(
        sellerId: currentUser.uid, name: _nameController.text.trim(),
        category: _selectedCategory, description: _descController.text.trim(),
        price: double.tryParse(_priceController.text.trim()) ?? 0,
        conditionPercent: _conditionPercent.toInt(), images: _selectedImages,
        lat: _selectedLocation!.latitude, lng: _selectedLocation!.longitude,
      );
    }

    if (!context.mounted) return;
    if (errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage), backgroundColor: Colors.red));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.existingProduct != null ? 'Cập nhật thành công!' : 'Đăng bán thành công!'), backgroundColor: Colors.green));
      Navigator.pop(context);
    }
  }

  // Hàm tiện ích UI
  Widget _buildModernInput({required String label, required TextEditingController controller, required String hint, bool isNumber = false, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        TextField(
          controller: controller, keyboardType: isNumber ? TextInputType.number : TextInputType.text, maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint, hintStyle: const TextStyle(color: Colors.grey),
            filled: true, fillColor: Colors.grey[100],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.green, width: 2)),
          ),
        ),
      ],
    );
  }
}