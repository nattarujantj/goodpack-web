import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/product_provider.dart';
import '../models/product.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/qr_code_widget.dart';
import '../utils/number_formatter.dart';
import '../services/image_upload_service.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({Key? key, required this.productId}) : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  bool _isUploadingImage = false;
  double _uploadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    // Load products if not already loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ProductProvider>();
      if (provider.allProducts.isEmpty) {
        provider.loadProducts();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
        builder: (context, productProvider, child) {
          final product = productProvider.getProductById(widget.productId);
          
          if (product == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return SingleChildScrollView(
            child: ResponsivePadding(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Product Image and Basic Info
                  _buildProductHeader(product),
                  
                  const SizedBox(height: 24),
                  
                  // Product Details
                  _buildProductDetails(product),
                  
                  const SizedBox(height: 24),
                  
                  // Sales Tier Section
                  _buildSalesTierSection(product),
                  
                  const SizedBox(height: 24),
                  
                  // Price Section (Read-only)
                  _buildPriceSection(product),
                  
                  const SizedBox(height: 24),
                  
                  // Stock Section
                  _buildStockSection(product),
                  
                  const SizedBox(height: 24),
                  
                  // QR Code Section
                  _buildQrCodeSection(product),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      );
  }

  Widget _buildProductHeader(Product product) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header with Edit Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ResponsiveText(
                  'รายละเอียดสินค้า',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _editProduct(),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('แก้ไข'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Product Image
            GestureDetector(
              onTap: () => _showImageOptions(product),
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[200],
                  border: Border.all(
                    color: Colors.grey[300]!,
                    width: 1,
                  ),
                ),
                child: Stack(
                  children: [
                    // Image or placeholder
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: product.imageUrl != null
                          ? Image.network(
                              ImageUploadService.getImageUrl(product.imageUrl),
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
                            )
                          : _buildPlaceholderImage(),
                    ),
                    
                    // Upload progress overlay
                    if (_isUploadingImage)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                value: _uploadProgress,
                                color: Colors.white,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'กำลังอัพโหลด... ${(_uploadProgress * 100).toInt()}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    
                    // Upload button overlay
                    if (!_isUploadingImage)
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
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                            onPressed: () => _showImageOptions(product),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Product Name
            ResponsiveText(
              product.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 8),
            
            // Stock Status
            _buildStockStatus(product),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[200],
      ),
      child: Icon(
        Icons.inventory_2,
        size: 80,
        color: Colors.grey[400],
      ),
    );
  }

  Widget _buildStockStatus(Product product) {
    Color statusColor;
    String statusText;
    IconData statusIcon;
    
    if (product.stock == 0) {
      statusColor = Colors.red;
      statusText = 'สินค้าหมด';
      statusIcon = Icons.cancel;
    } else if (product.isLowStock) {
      statusColor = Colors.orange;
      statusText = 'สินค้าใกล้หมด';
      statusIcon = Icons.warning;
    } else {
      statusColor = Colors.green;
      statusText = 'สินค้าพร้อมจำหน่าย';
      statusIcon = Icons.check_circle;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, color: statusColor, size: 16),
          const SizedBox(width: 8),
          ResponsiveText(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductDetails(Product product) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResponsiveText(
              'ข้อมูลสินค้า',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildDetailRow('SKU ID', product.skuId),
            const SizedBox(height: 12),
            _buildDetailRow('Code', product.code),
            const SizedBox(height: 12),
            _buildDetailRow('รายละเอียด', product.description),
            const SizedBox(height: 12),
            _buildDetailRow('สี', product.color),
            const SizedBox(height: 12),
            _buildDetailRow('ขนาด', product.size),
            const SizedBox(height: 12),
            _buildDetailRow('หมวดหมู่', product.category),
            const SizedBox(height: 12),
            _buildDetailRow('สร้างเมื่อ', _formatDate(product.createdAt)),
            const SizedBox(height: 12),
            _buildDetailRow('อัปเดตล่าสุด', _formatDate(product.updatedAt)),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: ResponsiveText(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
        ),
        Expanded(
          child: ResponsiveText(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildSalesTierSection(Product product) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResponsiveText(
              'ราคาขายตาม Tier',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            if (product.price.salesTiers.isNotEmpty) ...[
              // Table Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: ResponsiveText(
                        'Tier',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: ResponsiveText(
                        'จำนวน',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: ResponsiveText(
                        'ราคาขาย',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: ResponsiveText(
                        'ราคาขายส่ง',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            
            if (product.price.salesTiers.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ResponsiveText(
                        'ยังไม่มีราคาขายตาม Tier',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              ...product.price.salesTiers.asMap().entries.map((entry) {
                final index = entry.key;
                final tier = entry.value;
                return _buildTierRow(index, tier);
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildTierRow(int index, TierPrice tier) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: ResponsiveText(
              'Tier ${index + 1}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: ResponsiveText(
              '${NumberFormatter.formatQuantity(tier.minQuantity)}${tier.maxQuantity != null ? ' - ${NumberFormatter.formatQuantity(tier.maxQuantity!)}' : '+'} ชิ้น',
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Expanded(
            flex: 2,
            child: ResponsiveText(
              NumberFormatter.formatPriceWithCurrency(tier.price.latest),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
                fontSize: 16,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: ResponsiveText(
              NumberFormatter.formatPriceWithCurrency(tier.wholesalePrice),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.orange,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSection(Product product) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResponsiveText(
              'ข้อมูลราคา',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Purchase Prices Section
            ResponsiveText(
              'ราคาซื้อ',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildPriceDetails(
                    title: 'VAT',
                    priceInfo: product.price.purchaseVAT,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildPriceDetails(
                    title: 'Non-VAT',
                    priceInfo: product.price.purchaseNonVAT,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Sale Prices Section
            ResponsiveText(
              'ราคาขาย',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildPriceDetails(
                    title: 'VAT',
                    priceInfo: product.price.saleVAT,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildPriceDetails(
                    title: 'Non-VAT',
                    priceInfo: product.price.saleNonVAT,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockSection(Product product) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResponsiveText(
              'ข้อมูลสต็อก',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // VAT Stock Section
            ResponsiveText(
              'สต็อก VAT',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildReadOnlyField(
                    label: 'ซื้อ',
                    value: NumberFormatter.formatQuantity(product.stock.vat.purchased),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildReadOnlyField(
                    label: 'ขาย',
                    value: NumberFormatter.formatQuantity(product.stock.vat.sold),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildReadOnlyField(
                    label: 'คงเหลือ',
                    value: NumberFormatter.formatQuantity(product.stock.vat.remaining),
                    isNegative: true,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Non-VAT Stock Section
            ResponsiveText(
              'สต็อก Non-VAT',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildReadOnlyField(
                    label: 'ซื้อ',
                    value: NumberFormatter.formatQuantity(product.stock.nonVAT.purchased),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildReadOnlyField(
                    label: 'ขาย',
                    value: NumberFormatter.formatQuantity(product.stock.nonVAT.sold),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildReadOnlyField(
                    label: 'คงเหลือ',
                    value: NumberFormatter.formatQuantity(product.stock.nonVAT.remaining),
                    isNegative: true,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Actual Stock
            _buildReadOnlyField(
              label: 'สินค้าคงเหลือจริง',
              value: NumberFormatter.formatQuantity(product.stock.actualStock),
              isNegative: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceDetails({
    required String title,
    required PriceInfo priceInfo,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          _buildPriceRow('ล่าสุด:', NumberFormatter.formatPrice(priceInfo.latest)),
          _buildPriceRow('ต่ำสุด:', NumberFormatter.formatPrice(priceInfo.min)),
          _buildPriceRow('สูงสุด:', NumberFormatter.formatPrice(priceInfo.max)),
          _buildPriceRow('เฉลี่ย:', NumberFormatter.formatPrice(priceInfo.average)),
          _buildPriceRow('เฉลี่ย YTD:', NumberFormatter.formatPrice(priceInfo.averageYTD)),
          _buildPriceRow('เฉลี่ย MTD:', NumberFormatter.formatPrice(priceInfo.averageMTD)),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: ResponsiveText(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: ResponsiveText(
              '฿$value',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    bool isNegative = false,
  }) {
    // Check if value is negative
    final isNegativeValue = isNegative && (int.tryParse(value) ?? 0) < 0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveText(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: isNegativeValue ? Colors.red[50] : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isNegativeValue ? Colors.red[300]! : Colors.grey[300]!,
            ),
          ),
          child: ResponsiveText(
            value,
            style: TextStyle(
              color: isNegativeValue ? Colors.red[700] : Colors.black87,
              fontSize: 16,
              fontWeight: isNegativeValue ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQrCodeSection(Product product) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ResponsiveText(
              'QR Code',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Center(
              child: QrCodeWidget(
                data: product.qrCodeData,
                size: 200,
              ),
            ),
            
            const SizedBox(height: 16),
            
            ResponsiveText(
              'สแกน QR Code เพื่อดูรายละเอียดสินค้า',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }


  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _editProduct() {
    context.go('/product-form?id=${widget.productId}');
  }

  void _showImageOptions(Product product) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('เลือกรูปจากแกลเลอรี่'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickAndUploadImage(product, ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('ถ่ายรูปใหม่'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickAndUploadImage(product, ImageSource.camera);
                },
              ),
              if (product.imageUrl != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('ลบรูปภาพ', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.of(context).pop();
                    _deleteImage(product);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text('ยกเลิก'),
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAndUploadImage(Product product, ImageSource source) async {
    try {
      XFile? imageFile;
      
      if (source == ImageSource.gallery) {
        imageFile = await ImageUploadService.pickImageFromGallery();
      } else {
        imageFile = await ImageUploadService.pickImageFromCamera();
      }

      if (imageFile != null) {
        setState(() {
          _isUploadingImage = true;
          _uploadProgress = 0.0;
        });

        final result = await ImageUploadService.uploadProductImage(
          productId: product.id,
          imageFile: imageFile,
          onProgress: (progress) {
            setState(() {
              _uploadProgress = progress;
            });
          },
        );

        setState(() {
          _isUploadingImage = false;
          _uploadProgress = 0.0;
        });

        if (result['success']) {
          // Refresh product data
          final provider = context.read<ProductProvider>();
          await provider.loadProducts();
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('อัพโหลดรูปภาพสำเร็จ'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('อัพโหลดรูปภาพไม่สำเร็จ: ${result['error']}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      setState(() {
        _isUploadingImage = false;
        _uploadProgress = 0.0;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteImage(Product product) async {
    try {
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('ลบรูปภาพ'),
          content: const Text('คุณต้องการลบรูปภาพนี้หรือไม่?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('ยกเลิก'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('ลบ', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        // Call delete image API
        final result = await ImageUploadService.deleteProductImage(
          productId: product.id,
        );
        
        if (result['success']) {
          // Refresh product data
          final provider = context.read<ProductProvider>();
          await provider.loadProducts();
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('ลบรูปภาพสำเร็จ'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('ลบรูปภาพไม่สำเร็จ: ${result['error']}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


}
