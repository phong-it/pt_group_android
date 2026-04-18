import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../service/product_service.dart';
import '../models/product_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; 
import 'location_picker_screen.dart'; 

class AddProductScreen extends StatefulWidget {
// Thêm biến này: Nếu null là Tạo mới, nếu có data là Sửa
  final ProductModel? existingProduct;
  
  const AddProductScreen({super.key, this.existingProduct});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descController = TextEditingController();
  LatLng? _selectedLocation;

  @override
  void initState() {
    super.initState();
    // ĐỔ TEXT VÀO Ô NHẬP LIỆU
    if (widget.existingProduct != null) {
      final p = widget.existingProduct!;
      _nameController.text = p.name;
      _priceController.text = p.price.toStringAsFixed(0);
      _descController.text = p.description;
      _selectedCategory = p.category;
      _conditionPercent = p.conditionPercent.toDouble();
      
      // Không cần load ảnh. Trả mảng ảnh về rỗng để bắt người dùng chọn lại.
    }
  }
  
  String _selectedCategory = 'Điện tử';
  double _conditionPercent = 90; // Mặc định độ mới là 90%
  
  final List<String> _categories = ['Điện tử', 'Thời trang', 'Nội thất', 'Sách', 'Khác'];
  
  // Biến lưu ảnh được chọn
  List<File> _selectedImages = [];
  bool _isLoading = false;

  // Hàm gọi thư viện để chọn ảnh
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    // Cho phép chọn nhiều ảnh cùng lúc
    final List<XFile> images = await picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images.map((img) => File(img.path)));
      });
    }
  }

  // Hàm xóa ảnh lỡ chọn nhầm
  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
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
        title: Text(widget.existingProduct != null ? 'Sửa thông tin' : 'Đăng bán món đồ', style: TextStyle(fontWeight: FontWeight.bold)),    
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0, // Bỏ bóng đổ của AppBar cho phẳng
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KHU VỰC 1: UP ẢNH (UX: Nổi bật, dễ bấm)
            const Text('Hình ảnh sản phẩm *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Nút bấm thêm ảnh
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green, width: 1.5, style: BorderStyle.solid), // Hoặc dùng thư viện dotted_border để làm nét đứt
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
                  // Hiển thị danh sách ảnh đã chọn
                  ...List.generate(_selectedImages.length, (index) {
                    return Stack(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(right: 10),
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: FileImage(_selectedImages[index]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        // Nút X để xóa ảnh
                        Positioned(
                          top: 0,
                          right: 10,
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
            const SizedBox(height: 24),

            // KHU VỰC 2: THÔNG TIN CƠ BẢN (UX: Input không viền, nền xám nhạt)
            _buildModernInput(label: 'Tên món đồ *', controller: _nameController, hint: 'Vd: Laptop Dell Inspiron cũ'),
            const SizedBox(height: 16),
            _buildModernInput(label: 'Giá bán (VNĐ) *', controller: _priceController, hint: 'Vd: 5000000', isNumber: true),
            const SizedBox(height: 16),

            // KHU VỰC 3: DANH MỤC & TÌNH TRẠNG
            const Text('Danh mục *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  items: _categories.map((String value) {
                    return DropdownMenuItem<String>(value: value, child: Text(value));
                  }).toList(),
                  onChanged: (newValue) => setState(() => _selectedCategory = newValue!),
                ),
              ),
            ),
            const SizedBox(height: 24),

            const Text('Vị trí hiển thị trên bản đồ *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.location_on, color: Colors.red),
              title: Text(_selectedLocation == null ? 'Chưa chọn vị trí' : 'Đã ghim vị trí'),
              subtitle: Text(_selectedLocation == null ? 'Bấm để chọn vị trí bán hàng' : 'Tọa độ: ${_selectedLocation!.latitude.toStringAsFixed(3)}...'),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[200], foregroundColor: Colors.black),
                onPressed: () async {
                  // MỞ TRANG BẢN ĐỒ VÀ CHỜ KẾT QUẢ TRẢ VỀ
                  final LatLng? result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LocationPickerScreen()),
                  );
                  // NẾU CÓ KẾT QUẢ THÌ LƯU VÀO BIẾN
                  if (result != null) {
                    setState(() {
                      _selectedLocation = result;
                    });
                  }
                },
                child: const Text('Mở Bản đồ'),
              ),
            ),
            const SizedBox(height: 24),

            // UX: Dùng Slider thay vì bắt người dùng gõ số cho phần Tình trạng
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tình trạng mới', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('${_conditionPercent.toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 18)),
              ],
            ),
            Slider(
              value: _conditionPercent,
              min: 10,
              max: 100,
              divisions: 9, // Tương ứng 10%, 20%... 100%
              activeColor: Colors.orange,
              onChanged: (value) => setState(() => _conditionPercent = value),
            ),
            const SizedBox(height: 16),

            // KHU VỰC 4: MÔ TẢ
            _buildModernInput(label: 'Mô tả chi tiết *', controller: _descController, hint: 'Nêu rõ nguồn gốc, tình trạng thực tế, lỗi (nếu có)...', maxLines: 4),
            const SizedBox(height: 40), // Dành khoảng trống cho nút bấm dưới cùng
          ],
        ),
      ),
      
      // NÚT BẤM DÍNH CHẶT Ở DƯỚI (Sticky Bottom Bar)
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, -5))],
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _isLoading ? null : () async {
              // Bắt buộc phải chọn ảnh (_selectedImages không được rỗng)
              if (_nameController.text.isEmpty || _priceController.text.isEmpty || _selectedImages.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập đủ thông tin và chọn lại ảnh!'), backgroundColor: Colors.red));
                return;
              }

              setState(() => _isLoading = true);
              final productService = ProductService();             
              String? errorMessage;              
              final currentUser = FirebaseAuth.instance.currentUser;
              
              // Bảo mật UX: Lỡ máy bị lỗi văng đăng nhập thì báo đỏ chứ không cho up data rác
              if (currentUser == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Lỗi: Bạn chưa đăng nhập!'), backgroundColor: Colors.red)
                );
                setState(() => _isLoading = false);
                return; 
              }             
              // Gán ID thật vào biến
              String currentUserId = currentUser.uid;              

              if (widget.existingProduct != null) {
                // RẼ NHÁNH SỬA
                errorMessage = await productService.updateProduct(
                  productId: widget.existingProduct!.id, 
                  name: _nameController.text.trim(),
                  category: _selectedCategory,
                  description: _descController.text.trim(),
                  price: double.tryParse(_priceController.text.trim()) ?? 0,
                  conditionPercent: _conditionPercent.toInt(),
                  newImages: _selectedImages, // Đẩy cái mảng ảnh vừa chọn vào
                  lat: _selectedLocation!.latitude,
                  lng: _selectedLocation!.longitude,
                );
              } else {
                // RẼ NHÁNH THÊM MỚI
                errorMessage = await productService.uploadProduct(
                  sellerId: currentUserId,
                  name: _nameController.text.trim(),
                  category: _selectedCategory,
                  description: _descController.text.trim(),
                  price: double.tryParse(_priceController.text.trim()) ?? 0,
                  conditionPercent: _conditionPercent.toInt(),
                  images: _selectedImages, 
                  lat: _selectedLocation!.latitude,
                  lng: _selectedLocation!.longitude,
                );
              }

              setState(() => _isLoading = false);

              if (_selectedLocation == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng ghim vị trí bán hàng trên bản đồ!'), backgroundColor: Colors.red));
                return;
              }

              if (errorMessage != null) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage), backgroundColor: Colors.red));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.existingProduct != null ? 'Cập nhật thành công!' : 'Đăng bán thành công!'), backgroundColor: Colors.green));
                Navigator.pop(context); 
              }
            },
            child: _isLoading 
                ? const CircularProgressIndicator(color: Colors.white) 
                : Text(widget.existingProduct != null ? 'CẬP NHẬT' : 'ĐĂNG BÁN NGAY', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
      ),
    );
  }

  // Hàm tiện ích tạo ô nhập liệu phong cách hiện đại (Nền xám nhạt, không viền)
  Widget _buildModernInput({required String label, required TextEditingController controller, required String hint, bool isNumber = false, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: Colors.grey[100], // Màu nền xám nhạt
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), // Không có viền
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.green, width: 2)), // Khi bấm vào mới hiện viền xanh
          ),
        ),
      ],
    );
  }
}