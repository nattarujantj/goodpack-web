import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../models/sale.dart';
import '../models/product.dart';
import '../models/quotation.dart';
import '../providers/sale_provider.dart';
import '../providers/customer_provider.dart';
import '../providers/product_provider.dart';
import '../providers/quotation_provider.dart';
import '../services/config_service.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/customer_dropdown.dart';
import '../widgets/product_search_dropdown.dart';
import '../widgets/account_dropdown.dart';
import '../utils/error_dialog.dart';
import '../utils/date_formatter.dart';

class SaleFormScreen extends StatefulWidget {
  final Sale? sale;
  final String? saleId;
  final String? quotationId; // For pre-filling from quotation
  final String? duplicateId; // For duplicating existing sale

  const SaleFormScreen({Key? key, this.sale, this.saleId, this.quotationId, this.duplicateId}) : super(key: key);

  @override
  State<SaleFormScreen> createState() => _SaleFormScreenState();
}

class _SaleFormScreenState extends State<SaleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _saleDateController = TextEditingController();
  final _paymentMethodController = TextEditingController();
  final _paymentDateController = TextEditingController();
  final _ourAccountController = TextEditingController();
  final _warehouseNotesController = TextEditingController();
  final _notesController = TextEditingController();
  final _saleCodeController = TextEditingController();
  final _quotationCodeController = TextEditingController();
  final _shippingCostController = TextEditingController();

  String? _selectedCustomerId;
  String? _selectedAccountId;
  bool _isVAT = false;
  String _vatType = 'exclusive'; // "exclusive" (VAT นอก) or "inclusive" (VAT ใน)
  bool _isPaid = false;
  bool _isWarehouseUpdated = false;
  List<SaleItem> _saleItems = [];
  List<WarehouseItem> _warehouseItems = [];

  bool _isLoading = false;
  bool get _isEdit => widget.sale != null || widget.saleId != null;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  @override
  void dispose() {
    _saleDateController.dispose();
    _paymentMethodController.dispose();
    _paymentDateController.dispose();
    _ourAccountController.dispose();
    _warehouseNotesController.dispose();
    _notesController.dispose();
    _saleCodeController.dispose();
    _quotationCodeController.dispose();
    _shippingCostController.dispose();
    super.dispose();
  }

  Future<void> _initializeForm() async {
    print('🔄 Initializing sale form...');
    print('  - sale: ${widget.sale != null}');
    print('  - saleId: ${widget.saleId}');
    print('  - quotationId: ${widget.quotationId}');
    print('  - duplicateId: ${widget.duplicateId}');
    
    await _loadData();
    
    // Force rebuild after data loaded
    if (mounted) {
      setState(() {});
    }
    
    if (widget.sale != null) {
      print('📝 Populating from existing sale');
      _populateFields();
    } else if (widget.saleId != null) {
      print('📝 Loading sale from ID');
      _loadSaleFromId();
    } else if (widget.duplicateId != null) {
      print('📝 Duplicating sale from ID');
      _loadDuplicateSale();
    } else if (widget.quotationId != null) {
      print('📝 Loading quotation data');
      _loadQuotationData();
    } else {
      print('📝 Creating new sale');
      // ใส่ default notes สำหรับรายการขายใหม่ (ไม่มี leading space)
      _notesController.text = '''1).หลังโอนยอด จัดส่งภายใน 1-3 วันทำการ
2).ยอดชำระเกิน 30,000 บาท จัดส่งในกรุงเทพ-ปริมณฑล
3).หากสินค้ามีความเสียหายประการใด กรุณาแจ้งกลับบริษัทภายใน 7 วันทำการ
มิฉะนั้นทางบริษัทจะไม่รับผิดชอบใดๆ ทั้งสิ้น''';
    }
  }

  Future<void> _loadData() async {
    final customerProvider = context.read<CustomerProvider>();
    final productProvider = context.read<ProductProvider>();
    
    // Load only if not already loaded
    final futures = <Future>[];
    
    if (customerProvider.allCustomers.isEmpty && !customerProvider.isLoading) {
      futures.add(customerProvider.loadCustomers());
    }
    
    if (productProvider.allProducts.isEmpty && !productProvider.isLoading) {
      futures.add(productProvider.loadProducts());
    }
    
    if (!ConfigService().isLoaded) {
      futures.add(ConfigService().loadConfig());
    }
    
    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
  }

  void _loadSaleFromId() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sale = context.read<SaleProvider>().getSaleById(widget.saleId!);
      if (sale != null) {
        _populateFieldsFromSale(sale);
      }
    });
  }

  void _loadDuplicateSale() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Load sales first if not already loaded
      final saleProvider = context.read<SaleProvider>();
      if (saleProvider.sales.isEmpty) {
        await saleProvider.loadSales();
      }
      
      final sale = saleProvider.getSaleById(widget.duplicateId!);
      if (sale != null) {
        _populateFieldsForDuplicate(sale);
      }
    });
  }

  void _populateFieldsForDuplicate(Sale sale) {
    // Copy all fields except saleCode (will be generated by server)
    _saleDateController.text = _formatDate(DateTime.now()); // Use current date
    // Don't copy saleCode - will be generated for new sale
    _quotationCodeController.text = ''; // Don't copy quotation link
    _selectedCustomerId = sale.customerId;
    _isVAT = sale.isVAT;
    _vatType = sale.vatType;
    _shippingCostController.text = sale.shippingCost > 0 ? sale.shippingCost.toString() : '';
    _notesController.text = sale.notes ?? '';
    
    // Copy items
    _saleItems = sale.items.map((item) => SaleItem(
      productId: item.productId,
      productName: item.productName,
      productCode: item.productCode,
      quantity: item.quantity,
      unitPrice: item.unitPrice,
      totalPrice: item.totalPrice,
    )).toList();
    
    // Reset payment and warehouse info for new sale
    _isPaid = false;
    _paymentMethodController.text = '';
    _paymentDateController.text = '';
    _ourAccountController.text = '';
    _selectedAccountId = null;
    _isWarehouseUpdated = false;
    _warehouseNotesController.text = '';
    _warehouseItems = [];
    
    if (mounted) {
      setState(() {});
    }
  }

  void _loadQuotationData() {
    print('🔄 Loading quotation data for ID: ${widget.quotationId}');
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        // Load quotations first
        print('📥 Loading quotations...');
        await context.read<QuotationProvider>().loadQuotations();
        
        // Get quotation by ID
        print('🔍 Getting quotation by ID: ${widget.quotationId}');
        final quotation = context.read<QuotationProvider>().getQuotationById(widget.quotationId!);
        if (quotation != null) {
          print('✅ Found quotation: ${quotation.quotationCode}');
          _populateFieldsFromQuotation(quotation);
        } else {
          print('❌ Quotation not found');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('ไม่พบข้อมูล quotation'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        print('❌ Error loading quotation: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล quotation: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    });
  }

  void _populateFieldsFromSale(Sale sale) {
    _saleDateController.text = _formatDate(sale.saleDate);
    _saleCodeController.text = sale.saleCode;
    _quotationCodeController.text = sale.quotationCode ?? '';
    _selectedCustomerId = sale.customerId;
    _isVAT = sale.isVAT;
    _vatType = sale.vatType;
    _shippingCostController.text = sale.shippingCost.toString();
    _isPaid = sale.payment.isPaid;
    _paymentMethodController.text = sale.payment.paymentMethod ?? '';
    _selectedAccountId = sale.payment.ourAccount;
    _paymentDateController.text = sale.payment.paymentDate != null 
        ? _formatDate(sale.payment.paymentDate!) 
        : '';
    _isWarehouseUpdated = sale.warehouse.isUpdated;
    _warehouseNotesController.text = sale.warehouse.notes ?? '';
    _notesController.text = sale.notes ?? '';
    _saleItems = List.from(sale.items);
    _warehouseItems = List.from(sale.warehouse.items);
    
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {});
      });
    }
  }

  void _populateFieldsFromQuotation(Quotation quotation) {
    print('🔄 Pre-filling sale form from quotation: ${quotation.quotationCode}');
    
    // Pre-fill basic information from quotation
    _saleDateController.text = _formatDate(DateTime.now()); // Use current date for sale
    _quotationCodeController.text = quotation.quotationCode;
    _selectedCustomerId = quotation.customerId;
    _isVAT = quotation.isVAT;
    _shippingCostController.text = quotation.shippingCost.toStringAsFixed(2);
    _notesController.text = quotation.notes ?? '';
    
    // Convert quotation items to sale items
    _saleItems = quotation.items.map((item) => SaleItem(
      productId: item.productId,
      productName: item.productName,
      productCode: item.productCode,
      quantity: item.quantity,
      unitPrice: item.unitPrice,
      totalPrice: item.totalPrice,
    )).toList();
    
    // Initialize warehouse items as empty
    _warehouseItems = [];
    
    // Set default payment status
    _isPaid = false;
    _isWarehouseUpdated = false;
    
    print('✅ Pre-filled data:');
    print('  - Customer ID: $_selectedCustomerId');
    print('  - VAT: $_isVAT');
    print('  - Items count: ${_saleItems.length}');
    print('  - Quotation Code: ${_quotationCodeController.text}');
    
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {});
      });
    }
  }

  void _populateFields() {
    final sale = widget.sale!;
    _populateFieldsFromSale(sale);
  }

  @override
  Widget build(BuildContext context) {
    final saleId = widget.sale?.id ?? widget.saleId;
    
    return Scaffold(
      appBar: ResponsiveAppBar(
        title: _isEdit ? 'แก้ไขรายการขาย' : 'เพิ่มรายการขายใหม่',
        leading: _isEdit && saleId != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
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
                _buildBasicInfoSection(),
                const SizedBox(height: 24),
                _buildVATSection(),
                const SizedBox(height: 24),
                _buildSaleItemsSection(),
                const SizedBox(height: 24),
                _buildPaymentSection(),
                const SizedBox(height: 24),
                _buildWarehouseSection(),
                const SizedBox(height: 32),
                _buildActionButtons(_isEdit),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResponsiveText(
              'ข้อมูลพื้นฐาน',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildDateField(
              controller: _saleDateController,
              label: 'วันที่ขาย *',
              onTap: () => _selectDate(_saleDateController),
            ),
            
            const SizedBox(height: 16),
            
            _buildTextField(
              controller: _saleCodeController,
              label: 'รหัสรายการขาย',
              hint: _isEdit ? 'รหัสรายการขาย' : 'ว่างไว้ให้ระบบสร้างอัตโนมัติ',
            ),
            const SizedBox(height: 16),
            
            _buildTextField(
              controller: _quotationCodeController,
              label: 'รหัส Quotation',
              hint: 'รหัส Quotation (ถ้ามี)',
            ),
            const SizedBox(height: 16),
            
            _buildCustomerDropdown(),
            
            const SizedBox(height: 16),
            
            _buildTextField(
              controller: _shippingCostController,
              label: 'ค่าส่ง',
              hint: '0.00',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            
            const SizedBox(height: 16),
            
            _buildTextField(
              controller: _notesController,
              label: 'รายละเอียด',
              hint: 'กรอกรายละเอียดเพิ่มเติม...',
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVATSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ResponsiveText(
                  'ข้อมูล VAT *',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_isEdit)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Icon(Icons.lock, size: 16, color: Colors.grey[400]),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            // VAT Radio buttons
            Row(
              children: [
                Expanded(
                  child: RadioListTile<bool>(
                    title: Text(
                      'ไม่มี VAT',
                      style: TextStyle(
                        fontSize: 14,
                        color: _isEdit ? Colors.grey : null,
                      ),
                    ),
                    value: false,
                    groupValue: _isVAT,
                    onChanged: _isEdit ? null : (value) {
                      setState(() {
                        _isVAT = value ?? false;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
                Expanded(
                  child: RadioListTile<bool>(
                    title: Text(
                      'มี VAT (7%)',
                      style: TextStyle(
                        fontSize: 14,
                        color: _isEdit ? Colors.grey : null,
                      ),
                    ),
                    value: true,
                    groupValue: _isVAT,
                    onChanged: _isEdit ? null : (value) {
                      setState(() {
                        _isVAT = value ?? false;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
              ],
            ),
            
            // VAT Type selector (only show when VAT is selected)
            if (_isVAT) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'วิธีคำนวณ VAT${_isEdit ? ' (ไม่สามารถเปลี่ยนได้)' : ''}',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: _isEdit ? Colors.grey : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('VAT นอก', style: TextStyle(fontSize: 14)),
                            subtitle: const Text('ราคา + VAT 7%', style: TextStyle(fontSize: 12)),
                            value: 'exclusive',
                            groupValue: _vatType,
                            onChanged: _isEdit ? null : (value) {
                              setState(() {
                                _vatType = value ?? 'exclusive';
                              });
                            },
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('VAT ใน', style: TextStyle(fontSize: 14)),
                            subtitle: const Text('ราคารวม VAT แล้ว', style: TextStyle(fontSize: 12)),
                            value: 'inclusive',
                            groupValue: _vatType,
                            onChanged: _isEdit ? null : (value) {
                              setState(() {
                                _vatType = value ?? 'exclusive';
                              });
                            },
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSaleItemsSection() {
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
                  'สินค้าที่ขาย',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _addSaleItem,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('เพิ่มสินค้า'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (_saleItems.isEmpty)
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
                        'ยังไม่มีสินค้าในรายการ\nกดปุ่ม "เพิ่มสินค้า" เพื่อเพิ่มสินค้า',
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
              ...List.generate(_saleItems.length, (index) {
                return _buildSaleItemRow(index);
              }),
              
            if (_saleItems.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildTotalSummary(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResponsiveText(
              'ข้อมูลการชำระเงิน',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Payment Status Radio
            const Text(
              'สถานะการชำระเงิน *',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('ค้างชำระ', style: TextStyle(fontSize: 14)),
                    value: false,
                    groupValue: _isPaid,
                    onChanged: (value) {
                      setState(() {
                        _isPaid = value ?? false;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('รับเงินแล้ว', style: TextStyle(fontSize: 14)),
                    value: true,
                    groupValue: _isPaid,
                    onChanged: (value) {
                      setState(() {
                        _isPaid = value ?? false;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            _buildTextField(
              controller: _paymentMethodController,
              label: 'วิธีการชำระเงิน',
              hint: 'เช่น โอนเงิน, เงินสด, เช็ค',
            ),
            const SizedBox(height: 16),
            _buildAccountDropdown(),
            const SizedBox(height: 16),
            _buildDateField(
              controller: _paymentDateController,
              label: 'วันที่รับเงิน',
              onTap: () => _selectDate(_paymentDateController),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarehouseSection() {
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
                  'ข้อมูลคลังสินค้า',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _copyFromSaleItems,
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('คัดลอกจากขาย'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _addWarehouseItem,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('เพิ่มสินค้า'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            CheckboxListTile(
              title: const Text('อัปเดตคลังแล้ว'),
              value: _isWarehouseUpdated,
              onChanged: (value) {
                setState(() {
                  _isWarehouseUpdated = value ?? false;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
            ),
            
            const SizedBox(height: 16),
            _buildTextField(
              controller: _warehouseNotesController,
              label: 'หมายเหตุคลังสินค้า',
              hint: 'ข้อมูลเพิ่มเติมเกี่ยวกับการส่งสินค้า',
              maxLines: 3,
            ),
            
            const SizedBox(height: 16),
            
            if (_warehouseItems.isNotEmpty) ...[
              ResponsiveText(
                'รายการสินค้าคลัง',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...List.generate(_warehouseItems.length, (index) {
                return _buildWarehouseItemRow(index);
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerDropdown() {
    return CustomerDropdown(
      selectedCustomerId: _selectedCustomerId,
      onChanged: (value) {
        setState(() {
          _selectedCustomerId = value;
        });
      },
    );
  }

  Widget _buildAccountDropdown() {
    return AccountDropdown(
      selectedAccountId: _selectedAccountId,
      onChanged: (value) {
        setState(() {
          _selectedAccountId = value;
        });
      },
      label: 'บัญชีที่ใช้รับเงิน *',
    );
  }

  Widget _buildSaleItemRow(int index) {
    final item = _saleItems[index];
    
    // Calculate VAT based on vatType
    double vatAmount = 0.0;
    double itemTotalWithVAT = item.totalPrice;
    double priceBeforeVAT = item.totalPrice;
    
    if (_isVAT) {
      if (_vatType == 'inclusive') {
        // VAT ใน: ราคารวม VAT แล้ว, ต้องถอด VAT ออก
        // ราคาก่อน VAT = ราคารวม / 1.07
        priceBeforeVAT = item.totalPrice / 1.07;
        vatAmount = item.totalPrice - priceBeforeVAT;
        itemTotalWithVAT = item.totalPrice; // ราคาที่กรอกคือราคารวม VAT แล้ว
      } else {
        // VAT นอก: ราคา + VAT 7%
        vatAmount = item.totalPrice * 0.07;
        itemTotalWithVAT = item.totalPrice + vatAmount;
        priceBeforeVAT = item.totalPrice;
      }
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${item.productName} (${item.productCode})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _editSaleItem(index),
                icon: const Icon(Icons.edit, color: Colors.green, size: 20),
                tooltip: 'แก้ไขสินค้านี้',
              ),
              IconButton(
                onPressed: () => _removeSaleItem(index),
                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                tooltip: 'ลบสินค้านี้',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text('จำนวน: ${item.quantity}'),
              ),
              Expanded(
                child: Text('ราคาต่อชิ้น: ฿${item.unitPrice.toStringAsFixed(2)}'),
              ),
              Expanded(
                child: Text(
                  'รวม: ฿${item.totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          if (_isVAT) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'VAT (7%): ฿${vatAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'รวม VAT: ฿${itemTotalWithVAT.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTotalSummary() {
    final itemsTotal = _saleItems.fold(0.0, (sum, item) => sum + item.totalPrice);
    final shippingCost = double.tryParse(_shippingCostController.text) ?? 0.0;
    
    // Calculate VAT based on vatType
    double totalBeforeVAT = itemsTotal;
    double totalVAT = 0.0;
    double grandTotal = itemsTotal + shippingCost;
    
    if (_isVAT) {
      if (_vatType == 'inclusive') {
        // VAT ใน: ราคาที่กรอกรวม VAT แล้ว
        totalBeforeVAT = itemsTotal / 1.07;
        totalVAT = itemsTotal - totalBeforeVAT;
        grandTotal = itemsTotal + shippingCost; // ราคาที่กรอกคือราคารวม VAT แล้ว
      } else {
        // VAT นอก: ราคา + VAT 7%
        totalBeforeVAT = itemsTotal;
        totalVAT = itemsTotal * 0.07;
        grandTotal = itemsTotal + totalVAT + shippingCost;
      }
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'สรุปยอดรวม',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('ยอดรวมก่อน VAT:'),
              Text(
                '฿${totalBeforeVAT.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          if (_isVAT) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('VAT (7%):'),
                Text(
                  '฿${totalVAT.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('ค่าส่ง:'),
              Text(
                '฿${shippingCost.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ยอดรวมที่ต้องรับ:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '฿${grandTotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
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
    VoidCallback? onTap,
    bool readOnly = false,
  }) {
    final isReadOnly = readOnly && onTap == null;
    final hasOnTap = onTap != null;
    
    Widget textField = TextFormField(
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
        filled: isReadOnly,
        fillColor: isReadOnly ? Colors.grey.shade200 : null,
          ),
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          onTap: onTap,
      readOnly: isReadOnly || hasOnTap,
      style: isReadOnly ? TextStyle(color: Colors.grey.shade600) : null,
    );
    
    // Wrap with IgnorePointer if readOnly to completely block interaction
    if (isReadOnly) {
      textField = IgnorePointer(
        ignoring: true,
        child: textField,
      );
    }
    
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
        textField,
      ],
    );
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
    required VoidCallback onTap,
  }) {
    return _buildTextField(
      controller: controller,
      label: label,
      hint: 'เลือกวันที่',
      onTap: onTap,
    );
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      controller.text = _formatDate(picked);
    }
  }

  String _formatDate(DateTime date) {
    return DateFormatter.formatDate(date);
  }

  DateTime _parseDate(String dateStr) {
    try {
      final parts = dateStr.split('/');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[2]), // year
          int.parse(parts[1]), // month
          int.parse(parts[0]), // day
        );
      }
    } catch (e) {
      // Fall back to now if parsing fails
    }
    return DateTime.now();
  }

  Widget _buildActionButtons(bool isEdit) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isLoading ? null : () => context.go('/sales'),
            child: const Text('ยกเลิก'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveSale,
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

  void _addSaleItem() {
    showDialog(
      context: context,
      builder: (context) => _buildAddItemDialog(),
    );
  }

  Widget _buildAddItemDialog() {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        // แสดง loading indicator ถ้ากำลังโหลด
        if (productProvider.isLoading) {
          return AlertDialog(
            title: const Text('เพิ่มสินค้า'),
            content: const SizedBox(
              height: 100,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('กำลังโหลดข้อมูลสินค้า...'),
                  ],
                ),
              ),
            ),
          );
        }
        
        return AlertDialog(
          title: const Text('เพิ่มสินค้า'),
          content: SizedBox(
            width: double.maxFinite,
            child: _AddItemForm(
              products: productProvider.allProducts,
              onAdd: (item) {
                setState(() {
                  _saleItems.add(item);
                });
                Navigator.of(context).pop();
              },
            ),
          ),
        );
      },
    );
  }

  void _editSaleItem(int index) {
    showDialog(
      context: context,
      builder: (context) => _buildEditSaleItemDialog(index),
    );
  }

  Widget _buildEditSaleItemDialog(int index) {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        if (productProvider.isLoading) {
          return AlertDialog(
            title: const Text('แก้ไขสินค้า'),
            content: const SizedBox(
              height: 100,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('กำลังโหลดข้อมูลสินค้า...'),
                  ],
                ),
              ),
            ),
          );
        }

        return AlertDialog(
          title: const Text('แก้ไขสินค้า'),
          content: SizedBox(
            width: double.maxFinite,
            child: _AddItemForm(
              products: productProvider.allProducts,
              initialItem: _saleItems[index],
              onAdd: (item) {
                setState(() {
                  _saleItems[index] = item;
                });
                Navigator.of(context).pop();
              },
            ),
          ),
        );
      },
    );
  }

  void _removeSaleItem(int index) {
    setState(() {
      _saleItems.removeAt(index);
    });
  }

  void _copyFromSaleItems() {
    setState(() {
      _warehouseItems = _saleItems.map((item) => WarehouseItem(
        productId: item.productId,
        productName: item.productName,
        quantity: item.quantity,
        boxes: 1,
        notes: null,
      )).toList();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('คัดลอกรายการสินค้าจากการขายแล้ว'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _addWarehouseItem() {
    showDialog(
      context: context,
      builder: (context) => _buildAddWarehouseItemDialog(),
    );
  }

  Widget _buildAddWarehouseItemDialog() {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        // แสดง loading indicator ถ้ากำลังโหลด
        if (productProvider.isLoading) {
          return AlertDialog(
            title: const Text('เพิ่มสินค้าคลัง'),
            content: const SizedBox(
              height: 100,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('กำลังโหลดข้อมูลสินค้า...'),
                  ],
                ),
              ),
            ),
          );
        }
        
        return AlertDialog(
          title: const Text('เพิ่มสินค้าคลัง'),
          content: SizedBox(
            width: double.maxFinite,
            child: _AddWarehouseItemForm(
              products: productProvider.allProducts,
              onAdd: (item) {
                setState(() {
                  _warehouseItems.add(item);
                });
                Navigator.of(context).pop();
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildWarehouseItemRow(int index) {
    final item = _warehouseItems[index];
    
    return Container(
      key: ValueKey('warehouse_item_$index'),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${item.productName}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _removeWarehouseItem(index),
                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                tooltip: 'ลบสินค้านี้',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  key: ValueKey('warehouse_quantity_$index'),
                  initialValue: item.quantity.toString(),
                  decoration: const InputDecoration(
                    labelText: 'จำนวน',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final quantity = int.tryParse(value) ?? 0;
                    _warehouseItems[index] = WarehouseItem(
                      productId: _warehouseItems[index].productId,
                      productName: _warehouseItems[index].productName,
                      quantity: quantity,
                      boxes: _warehouseItems[index].boxes,
                      notes: _warehouseItems[index].notes,
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  key: ValueKey('warehouse_boxes_$index'),
                  initialValue: item.boxes.toString(),
                  decoration: const InputDecoration(
                    labelText: 'ลัง',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final boxes = int.tryParse(value) ?? 0;
                    _warehouseItems[index] = WarehouseItem(
                      productId: _warehouseItems[index].productId,
                      productName: _warehouseItems[index].productName,
                      quantity: _warehouseItems[index].quantity,
                      boxes: boxes,
                      notes: _warehouseItems[index].notes,
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            key: ValueKey('warehouse_notes_$index'),
            initialValue: item.notes ?? '',
            decoration: const InputDecoration(
              labelText: 'หมายเหตุ',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
            maxLines: 2,
            onChanged: (value) {
              _warehouseItems[index] = WarehouseItem(
                productId: _warehouseItems[index].productId,
                productName: _warehouseItems[index].productName,
                quantity: _warehouseItems[index].quantity,
                boxes: _warehouseItems[index].boxes,
                notes: value.trim().isEmpty ? null : value.trim(),
              );
            },
          ),
        ],
      ),
    );
  }

  void _removeWarehouseItem(int index) {
    setState(() {
      _warehouseItems.removeAt(index);
    });
  }

  DateTime? _parsePaymentDate() {
    final dateText = _paymentDateController.text.trim();
    if (dateText.isEmpty) return null;
    
    try {
      final parts = dateText.split('/');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    } catch (e) {
      // If parsing fails, return null
    }
    return null;
  }

  Future<void> _saveSale() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCustomerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาเลือกลูกค้า'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_saleItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาเพิ่มสินค้าในรายการ'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final saleCodeText = _saleCodeController.text.trim();
      final saleRequest = SaleRequest(
        saleCode: saleCodeText.isEmpty ? null : saleCodeText,
        saleDate: _parseDate(_saleDateController.text),
        customerId: _selectedCustomerId!,
        items: _saleItems,
        isVAT: _isVAT,
        vatType: _vatType,
        shippingCost: double.tryParse(_shippingCostController.text) ?? 0.0,
        payment: PaymentInfo(
          isPaid: _isPaid,
          paymentMethod: _paymentMethodController.text.trim().isEmpty ? null : _paymentMethodController.text.trim(),
          ourAccount: _selectedAccountId,
          paymentDate: _paymentDateController.text.trim().isEmpty ? null : _parsePaymentDate(),
        ),
        warehouse: WarehouseInfo(
          isUpdated: _isWarehouseUpdated,
          notes: _warehouseNotesController.text.trim().isEmpty ? null : _warehouseNotesController.text.trim(),
          actualShipping: 0.0,
          items: _warehouseItems.isEmpty ? [] : _warehouseItems,
        ),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        quotationCode: _quotationCodeController.text.trim().isEmpty ? null : _quotationCodeController.text.trim(),
      );

      final saleProvider = context.read<SaleProvider>();
      bool success;
      
      String? resultSaleId;
      
      if (_isEdit) {
        final saleId = widget.sale?.id ?? widget.saleId!;
        success = await saleProvider.updateSale(saleId, saleRequest);
        if (success) resultSaleId = saleId;
      } else {
        final newSale = await saleProvider.addSale(saleRequest);
        resultSaleId = newSale?.id;
      }

      if (resultSaleId != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEdit 
                  ? 'อัปเดตรายการขายเรียบร้อยแล้ว' 
                  : 'เพิ่มรายการขายเรียบร้อยแล้ว',
            ),
            backgroundColor: Colors.green,
          ),
        );
        // โหลดข้อมูลล่าสุดจาก API ก่อนไปหน้ารายละเอียด (กัน cache เก่า)
        await saleProvider.fetchSaleById(resultSaleId);
        if (mounted) context.go('/sale/$resultSaleId');
      } else if (mounted) {
        // Show error popup if not successful
        final errorMessage = saleProvider.error ?? 'เกิดข้อผิดพลาดที่ไม่ทราบสาเหตุ';
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

class _AddItemForm extends StatefulWidget {
  final List<Product> products;
  final Function(SaleItem) onAdd;
  final SaleItem? initialItem;

  const _AddItemForm({
    required this.products,
    required this.onAdd,
    this.initialItem,
  });

  @override
  State<_AddItemForm> createState() => _AddItemFormState();
}

class _AddItemFormState extends State<_AddItemForm> {
  final _formKey = GlobalKey<FormState>();
  Product? _selectedProduct;
  final _quantityController = TextEditingController();
  final _unitPriceController = TextEditingController();

  bool get _isEditMode => widget.initialItem != null;

  @override
  void initState() {
    super.initState();
    if (widget.initialItem != null) {
      final item = widget.initialItem!;
      _selectedProduct = widget.products.cast<Product?>().firstWhere(
        (p) => p!.id == item.productId,
        orElse: () => null,
      );
      _quantityController.text = item.quantity.toString();
      _unitPriceController.text = item.unitPrice.toString();
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _unitPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProductSearchDropdown(
            selectedProduct: _selectedProduct,
            products: widget.products,
            enabled: !_isEditMode,
            onChanged: (product) {
              setState(() {
                _selectedProduct = product;
              });
            },
          ),
          
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _quantityController,
            decoration: const InputDecoration(
              labelText: 'จำนวน *',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'กรุณากรอกจำนวน';
              }
              if (int.tryParse(value) == null || int.parse(value) <= 0) {
                return 'กรุณากรอกจำนวนที่ถูกต้อง';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _unitPriceController,
            decoration: const InputDecoration(
              labelText: 'ราคาต่อชิ้น *',
              border: OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'กรุณากรอกราคา';
              }
              if (double.tryParse(value) == null || double.parse(value) <= 0) {
                return 'กรุณากรอกราคาที่ถูกต้อง';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 24),
          
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('ยกเลิก'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _addItem,
                  child: Text(_isEditMode ? 'บันทึก' : 'เพิ่ม'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _addItem() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedProduct == null) {
      return;
    }

    final quantity = int.parse(_quantityController.text);
    final unitPrice = double.parse(_unitPriceController.text);
    final totalPrice = quantity * unitPrice;

    final item = SaleItem(
      productId: _selectedProduct!.id,
      productName: _selectedProduct!.name,
      productCode: _selectedProduct!.code,
      quantity: quantity,
      unitPrice: unitPrice,
      totalPrice: totalPrice,
    );

    widget.onAdd(item);
  }
}

class _AddWarehouseItemForm extends StatefulWidget {
  final List<Product> products;
  final Function(WarehouseItem) onAdd;

  const _AddWarehouseItemForm({
    required this.products,
    required this.onAdd,
  });

  @override
  State<_AddWarehouseItemForm> createState() => _AddWarehouseItemFormState();
}

class _AddWarehouseItemFormState extends State<_AddWarehouseItemForm> {
  final _formKey = GlobalKey<FormState>();
  Product? _selectedProduct;
  final _quantityController = TextEditingController();
  final _boxesController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _quantityController.dispose();
    _boxesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProductSearchDropdown(
            selectedProduct: _selectedProduct,
            products: widget.products,
            onChanged: (product) {
              setState(() {
                _selectedProduct = product;
              });
            },
          ),
          
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _quantityController,
            decoration: const InputDecoration(
              labelText: 'จำนวน *',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'กรุณากรอกจำนวน';
              }
              if (int.tryParse(value) == null || int.parse(value) <= 0) {
                return 'กรุณากรอกจำนวนที่ถูกต้อง';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _boxesController,
            decoration: const InputDecoration(
              labelText: 'จำนวนลัง',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value != null && value.trim().isNotEmpty) {
                if (int.tryParse(value) == null || int.parse(value) < 0) {
                  return 'กรุณากรอกจำนวนลังที่ถูกต้อง';
                }
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'หมายเหตุ',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          
          const SizedBox(height: 24),
          
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('ยกเลิก'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _addItem,
                  child: const Text('เพิ่ม'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _addItem() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedProduct == null) {
      return;
    }

    final quantity = int.parse(_quantityController.text);
    final boxes = int.tryParse(_boxesController.text) ?? 0;
    final notes = _notesController.text.trim().isEmpty ? null : _notesController.text.trim();

    final item = WarehouseItem(
      productId: _selectedProduct!.id,
      productName: _selectedProduct!.name,
      quantity: quantity,
      boxes: boxes,
      notes: notes,
    );

    widget.onAdd(item);
  }
}
