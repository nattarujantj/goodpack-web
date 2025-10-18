import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../widgets/responsive_layout.dart';
import '../config/app_config.dart';

class QrPrintScreen extends StatefulWidget {
  const QrPrintScreen({Key? key}) : super(key: key);

  @override
  State<QrPrintScreen> createState() => _QrPrintScreenState();
}

class _QrPrintScreenState extends State<QrPrintScreen> {
  List<String> _selectedProducts = [];
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ResponsiveAppBar(
        title: 'ปริ๊น QR Code',
        actions: [
          if (_selectedProducts.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.print),
              onPressed: _isGenerating ? null : _printSelectedQRCodes,
              tooltip: 'ปริ๊น QR Code ที่เลือก',
            ),
        ],
      ),
      body: Consumer<ProductProvider>(
        builder: (context, productProvider, child) {
          if (productProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (productProvider.error.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(productProvider.error),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => productProvider.refresh(),
                    child: const Text('ลองใหม่'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Selection Summary
              if (_selectedProducts.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        'เลือกแล้ว ${_selectedProducts.length} รายการ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _clearSelection,
                        child: const Text('ล้างการเลือก'),
                      ),
                    ],
                  ),
                ),

              // Product List
              Expanded(
                child: ListView.builder(
                  itemCount: productProvider.allProducts.length,
                  itemBuilder: (context, index) {
                    final product = productProvider.allProducts[index];
                    final isSelected = _selectedProducts.contains(product.id);

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: CheckboxListTile(
                        value: isSelected,
                        onChanged: (value) => _toggleProductSelection(product.id),
                        title: Text(product.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ID: ${product.id}'),
                            Text('สต็อก: ${product.stock} ชิ้น'),
                            if (product.category != null)
                              Text('หมวดหมู่: ${product.category}'),
                          ],
                        ),
                        secondary: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.qr_code,
                              color: isSelected 
                                  ? Theme.of(context).primaryColor 
                                  : Colors.grey,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'QR Code',
                              style: TextStyle(
                                fontSize: 10,
                                color: isSelected 
                                    ? Theme.of(context).primaryColor 
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Action Buttons
              if (productProvider.allProducts.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _selectAll,
                          icon: const Icon(Icons.select_all),
                          label: const Text('เลือกทั้งหมด'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _selectedProducts.isNotEmpty && !_isGenerating
                              ? _printSelectedQRCodes
                              : null,
                          icon: _isGenerating
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.print),
                          label: Text(_isGenerating ? 'กำลังสร้าง...' : 'ปริ๊น QR Code'),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _toggleProductSelection(String productId) {
    setState(() {
      if (_selectedProducts.contains(productId)) {
        _selectedProducts.remove(productId);
      } else {
        _selectedProducts.add(productId);
      }
    });
  }

  void _selectAll() {
    final allProducts = context.read<ProductProvider>().allProducts;
    setState(() {
      _selectedProducts = allProducts.map((p) => p.id).toList();
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedProducts.clear();
    });
  }

  Future<void> _printSelectedQRCodes() async {
    if (_selectedProducts.isEmpty) return;

    setState(() {
      _isGenerating = true;
    });

    try {
      // Generate download links for each selected product
      for (String productId in _selectedProducts) {
        final qrImageUrl = '${AppConfig.baseUrl}/qr-codes/$productId/image';
        
        // Open QR code image in new tab for download
        // Note: In a real app, you might want to use a proper print service
        print('QR Code for product $productId: $qrImageUrl');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('กำลังเปิด QR Code สำหรับ ${_selectedProducts.length} รายการ'),
            backgroundColor: Colors.green,
          ),
        );
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
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }
}
