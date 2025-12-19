import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../models/product.dart';
import '../providers/product_provider.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/smart_dropdown_field.dart';
import '../services/config_service.dart';
import '../utils/error_dialog.dart';

class ProductFormScreen extends StatefulWidget {
  final Product? product;
  final String? productId;
  final String? duplicateId;

  const ProductFormScreen({Key? key, this.product, this.productId, this.duplicateId}) : super(key: key);

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _colorController = TextEditingController();
  final _sizeController = TextEditingController();
  final _categoryController = TextEditingController();
  
  // Sales tier controllers
  final List<TextEditingController> _tierMinControllers = [];
  final List<TextEditingController> _tierMaxControllers = [];
  final List<TextEditingController> _tierPriceControllers = [];
  final List<TextEditingController> _tierWholesalePriceControllers = [];

  bool _isLoading = false;
  bool get _isEdit => widget.product != null || widget.productId != null;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  Future<void> _initializeForm() async {
    // Load config first
    await _loadConfig();
    
    // Then populate fields
    if (widget.product != null) {
      _populateFields();
    } else if (widget.productId != null) {
      _loadProductFromId();
    } else if (widget.duplicateId != null) {
      _loadDuplicateProduct();
    }
  }

  void _loadDuplicateProduct() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final productProvider = context.read<ProductProvider>();
      
      if (productProvider.allProducts.isEmpty) {
        await productProvider.loadProducts();
      }
      
      final product = productProvider.getProductById(widget.duplicateId!);
      if (product != null) {
        _populateFieldsForDuplicate(product);
      }
    });
  }

  void _populateFieldsForDuplicate(Product product) {
    // Copy all fields except code (user should enter new code)
    _nameController.text = '${product.name} (สำเนา)';
    _codeController.text = ''; // Empty code for new product
    _descriptionController.text = product.description;
    _colorController.text = product.color;
    _sizeController.text = product.size;
    _categoryController.text = product.category;
    
    // Sales tiers
    _populateSalesTiers(product.price.salesTiers);
    
    // Trigger rebuild to update UI
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadConfig() async {
    await ConfigService().loadConfig();
  }

  void _loadProductFromId() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final product = context.read<ProductProvider>().getProductById(widget.productId!);
      if (product != null) {
        _populateFieldsFromProduct(product);
      }
    });
  }

  void _populateFieldsFromProduct(Product product) {
    _nameController.text = product.name;
    _codeController.text = product.code;
    _descriptionController.text = product.description;
    _colorController.text = product.color;
    _sizeController.text = product.size;
    _categoryController.text = product.category;
    
    // Sales tiers
    _populateSalesTiers(product.price.salesTiers);
    
    
    // Trigger rebuild to update UI
    if (mounted) {
      setState(() {});
    }
  }

  void _populateFields() {
    final product = widget.product!;
    _populateFieldsFromProduct(product);
  }

  void _populateSalesTiers(List<TierPrice> salesTiers) {
    // Clear existing controllers
    _clearTierControllers();
    
    // Create controllers for existing tiers
    for (int i = 0; i < salesTiers.length; i++) {
      _addTierControllers();
      _tierMinControllers[i].text = salesTiers[i].minQuantity.toString();
      _tierMaxControllers[i].text = salesTiers[i].maxQuantity?.toString() ?? '';
      _tierPriceControllers[i].text = salesTiers[i].price.latest.toString();
      _tierWholesalePriceControllers[i].text = salesTiers[i].wholesalePrice.toString();
    }
  }

  void _clearTierControllers() {
    for (var controller in _tierMinControllers) {
      controller.dispose();
    }
    for (var controller in _tierMaxControllers) {
      controller.dispose();
    }
    for (var controller in _tierPriceControllers) {
      controller.dispose();
    }
    for (var controller in _tierWholesalePriceControllers) {
      controller.dispose();
    }
    _tierMinControllers.clear();
    _tierMaxControllers.clear();
    _tierPriceControllers.clear();
    _tierWholesalePriceControllers.clear();
  }

  void _addTierControllers() {
    _tierMinControllers.add(TextEditingController());
    _tierMaxControllers.add(TextEditingController());
    _tierPriceControllers.add(TextEditingController());
    _tierWholesalePriceControllers.add(TextEditingController());
  }

  void _addSalesTier() {
    setState(() {
      _addTierControllers();
    });
  }

  void _removeSalesTier(int index) {
    if (index < _tierMinControllers.length) {
      setState(() {
        _tierMinControllers[index].dispose();
        _tierMaxControllers[index].dispose();
        _tierPriceControllers[index].dispose();
        _tierWholesalePriceControllers[index].dispose();
        _tierMinControllers.removeAt(index);
        _tierMaxControllers.removeAt(index);
        _tierPriceControllers.removeAt(index);
        _tierWholesalePriceControllers.removeAt(index);
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    _colorController.dispose();
    _sizeController.dispose();
    _categoryController.dispose();
    
    // Dispose tier controllers
    _clearTierControllers();
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    
    final productId = widget.product?.id ?? widget.productId;
    
    return Scaffold(
      appBar: ResponsiveAppBar(
        title: _isEdit ? 'แก้ไขสินค้า' : 'เพิ่มสินค้าใหม่',
        leading: _isEdit && productId != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/product/$productId'),
                tooltip: 'กลับไปหน้ารายละเอียด',
              )
            : null,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ResponsivePadding(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Form Fields
                _buildFormFields(),
                
                const SizedBox(height: 32),
                
                // Action Buttons
                _buildActionButtons(_isEdit),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildFormFields() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResponsiveText(
              'ข้อมูลสินค้า',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Product Name
            _buildTextField(
              controller: _nameController,
              label: 'ชื่อสินค้า *',
              hint: 'กรอกชื่อสินค้า',
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'กรุณากรอกชื่อสินค้า';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Product Code (แสดงเฉพาะตอนแก้ไข)
            if (_isEdit)
              _buildTextField(
                controller: _codeController,
                label: 'รหัสสินค้า (Code)',
                hint: 'รหัสสินค้า',
              ),
            
            if (_isEdit) const SizedBox(height: 16),
            
            // Description
            _buildTextField(
              controller: _descriptionController,
              label: 'รายละเอียด',
              hint: 'กรอกรายละเอียดสินค้า',
              maxLines: 3,
            ),
            
            const SizedBox(height: 16),
            
            // Color and Size Row
            Row(
              children: [
                Expanded(
                  child: SmartDropdownField(
                    controller: _colorController,
                    label: 'สี *',
                    hint: 'กรอกหรือเลือกสีสินค้า',
                    configType: 'colors',
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'กรุณากรอกสี';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _sizeController,
                    label: 'ขนาด *',
                    hint: 'กรอกขนาดสินค้า',
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'กรุณากรอกขนาด';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Category
            SmartDropdownField(
              controller: _categoryController,
              label: 'หมวดหมู่ *',
              hint: 'กรอกหรือเลือกหมวดหมู่สินค้า',
              configType: 'categories',
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'กรุณากรอกหมวดหมู่';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 24),
            
            // Sales Tier Section
            _buildSalesTierSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesTierSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ResponsiveText(
                  'ราคาขายตาม Tier',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _addSalesTier,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('เพิ่ม Tier'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (_tierMinControllers.isEmpty)
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
                        'ยังไม่มีราคาขายตาม Tier\nกดปุ่ม "เพิ่ม Tier" เพื่อเพิ่มราคาขายตามจำนวน',
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
              ...List.generate(_tierMinControllers.length, (index) {
                return _buildTierRow(index);
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildTierRow(int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              ResponsiveText(
                'Tier ${index + 1}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => _removeSalesTier(index),
                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                tooltip: 'ลบ Tier นี้',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _tierMinControllers[index],
                  label: 'จำนวนขั้นต่ำ',
                  hint: '0',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTextField(
                  controller: _tierMaxControllers[index],
                  label: 'จำนวนสูงสุด',
                  hint: '999',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _tierPriceControllers[index],
                  label: 'ราคาขาย (บาท)',
                  hint: '0.00',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTextField(
                  controller: _tierWholesalePriceControllers[index],
                  label: 'ราคาขายส่ง (บาท)',
                  hint: '0.00',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveText(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
        ),
      ],
    );
  }


  Widget _buildActionButtons(bool isEdit) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isLoading ? null : () => context.go('/'),
            child: const Text('ยกเลิก'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveProduct,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(isEdit ? 'อัปเดต' : 'บันทึก'),
          ),
        ),
      ],
    );
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Validate ID for edit mode
      if (_isEdit && (widget.product?.id.isEmpty ?? true) && (widget.productId?.isEmpty ?? true)) {
        throw Exception('Product ID is required for editing');
      }
      // Create Sales Tiers
      final salesTiers = <TierPrice>[];
      for (int i = 0; i < _tierMinControllers.length; i++) {
        final minQty = int.tryParse(_tierMinControllers[i].text) ?? 0;
        final maxQty = int.tryParse(_tierMaxControllers[i].text) ?? 0;
        final price = double.tryParse(_tierPriceControllers[i].text) ?? 0.0;
        final wholesalePrice = double.tryParse(_tierWholesalePriceControllers[i].text) ?? 0.0;
        
        if (minQty > 0 || maxQty > 0 || price > 0 || wholesalePrice > 0) {
          salesTiers.add(TierPrice(
            minQuantity: minQty,
            maxQuantity: maxQty > 0 ? maxQty : null,
            price: PriceInfo(
              latest: price,
              min: 0.0,
              max: 0.0,
              average: 0.0,
              averageYTD: 0.0,
              averageMTD: 0.0,
              ytdCount: 0,
              ytdTotal: 0.0,
              ytdYear: 0,
              mtdCount: 0,
              mtdTotal: 0.0,
              mtdMonth: 0,
              mtdYear: 0,
            ),
            wholesalePrice: wholesalePrice,
          ));
        }
      }

      // Create Price object (with default values)
      final price = Price(
        purchaseVAT: PriceInfo(
          latest: 0.0,
          min: 0.0,
          max: 0.0,
          average: 0.0,
          averageYTD: 0.0,
          averageMTD: 0.0,
          ytdCount: 0,
          ytdTotal: 0.0,
          ytdYear: 0,
          mtdCount: 0,
          mtdTotal: 0.0,
          mtdMonth: 0,
          mtdYear: 0,
        ),
        purchaseNonVAT: PriceInfo(
          latest: 0.0,
          min: 0.0,
          max: 0.0,
          average: 0.0,
          averageYTD: 0.0,
          averageMTD: 0.0,
          ytdCount: 0,
          ytdTotal: 0.0,
          ytdYear: 0,
          mtdCount: 0,
          mtdTotal: 0.0,
          mtdMonth: 0,
          mtdYear: 0,
        ),
        saleVAT: PriceInfo(
          latest: 0.0,
          min: 0.0,
          max: 0.0,
          average: 0.0,
          averageYTD: 0.0,
          averageMTD: 0.0,
          ytdCount: 0,
          ytdTotal: 0.0,
          ytdYear: 0,
          mtdCount: 0,
          mtdTotal: 0.0,
          mtdMonth: 0,
          mtdYear: 0,
        ),
        saleNonVAT: PriceInfo(
          latest: 0.0,
          min: 0.0,
          max: 0.0,
          average: 0.0,
          averageYTD: 0.0,
          averageMTD: 0.0,
          ytdCount: 0,
          ytdTotal: 0.0,
          ytdYear: 0,
          mtdCount: 0,
          mtdTotal: 0.0,
          mtdMonth: 0,
          mtdYear: 0,
        ),
        salesTiers: salesTiers,
      );

      // Create Stock object (with default values)
      final stock = Stock(
        vat: StockInfo(
          initialStock: 0,
          purchased: 0,
          sold: 0,
          remaining: 0,
        ),
        nonVAT: StockInfo(
          initialStock: 0,
          purchased: 0,
          sold: 0,
          remaining: 0,
        ),
        actualStockInitial: 0,
        actualStock: 0,
      );

      final product = Product(
        id: widget.product?.id ?? widget.productId ?? '',
        skuId: widget.product?.skuId ?? '', // Will be generated by server
        code: _isEdit ? _codeController.text.trim() : '', // ใช้ค่าจาก controller ถ้าแก้ไข
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        color: _colorController.text.trim(),
        size: _sizeController.text.trim(),
        category: _categoryController.text.trim(),
        qrData: widget.product?.qrData ?? '', // Will be generated by server
        imageUrl: widget.product?.imageUrl,
        price: price,
        stock: stock,
        createdAt: widget.product?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final productProvider = context.read<ProductProvider>();
      bool success;
      
      if (_isEdit) {
        success = await productProvider.updateProduct(product);
      } else {
        success = await productProvider.addProduct(product);
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEdit 
                  ? 'อัปเดตสินค้าเรียบร้อยแล้ว' 
                  : 'เพิ่มสินค้าเรียบร้อยแล้ว',
            ),
            backgroundColor: Colors.green,
          ),
        );
        
        // Redirect based on edit or create
        if (_isEdit) {
          // Go back to product detail page
          context.go('/product/${product.id}');
        } else {
          // Go to product list
          context.go('/');
        }
      } else if (mounted) {
        // Show error popup if not successful
        final errorMessage = productProvider.error;
        ErrorDialog.showServerError(context, errorMessage);
      }
    } catch (e) {
      if (mounted) {
        ErrorDialog.showServerError(context, 'เกิดข้อผิดพลาด: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
