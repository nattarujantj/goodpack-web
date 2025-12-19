import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../models/purchase.dart';
import '../models/product.dart';
import '../providers/purchase_provider.dart';
import '../providers/customer_provider.dart';
import '../providers/product_provider.dart';
import '../services/config_service.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/searchable_dropdown.dart';
import '../utils/error_dialog.dart';

class PurchaseFormScreen extends StatefulWidget {
  final Purchase? purchase;
  final String? purchaseId;

  const PurchaseFormScreen({Key? key, this.purchase, this.purchaseId}) : super(key: key);

  @override
  State<PurchaseFormScreen> createState() => _PurchaseFormScreenState();
}

class _PurchaseFormScreenState extends State<PurchaseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _purchaseDateController = TextEditingController();
  final _paymentMethodController = TextEditingController();
  final _customerAccountController = TextEditingController();
  final _paymentDateController = TextEditingController();
  final _ourAccountController = TextEditingController();
  final _warehouseNotesController = TextEditingController();
  final _notesController = TextEditingController(); // ใหม่: รายละเอียด
  final _shippingCostController = TextEditingController();
  final _actualShippingController = TextEditingController();

  String? _selectedCustomerId;
  String? _selectedAccountId;
  bool _isVAT = false;
  bool _isPaid = false;
  bool _isWarehouseUpdated = false;
  List<PurchaseItem> _purchaseItems = [];
  List<WarehouseItem> _warehouseItems = [];

  bool _isLoading = false;
  bool get _isEdit => widget.purchase != null || widget.purchaseId != null;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  @override
  void dispose() {
    _purchaseDateController.dispose();
    _paymentMethodController.dispose();
    _customerAccountController.dispose();
    _paymentDateController.dispose();
    _ourAccountController.dispose();
    _warehouseNotesController.dispose();
    _notesController.dispose();
    _shippingCostController.dispose();
    _actualShippingController.dispose();
    super.dispose();
  }

  Future<void> _initializeForm() async {
    // Load data first
    await _loadData();
    
    // Then populate fields
    if (widget.purchase != null) {
      _populateFields();
    } else if (widget.purchaseId != null) {
      _loadPurchaseFromId();
    }
  }

  Future<void> _loadData() async {
    await Future.wait([
      context.read<CustomerProvider>().loadCustomers(),
      context.read<ProductProvider>().loadProducts(),
      ConfigService().loadConfig(),
    ]);
  }

  void _loadPurchaseFromId() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final purchase = context.read<PurchaseProvider>().getPurchaseById(widget.purchaseId!);
      if (purchase != null) {
        _populateFieldsFromPurchase(purchase);
      }
    });
  }

  void _populateFieldsFromPurchase(Purchase purchase) {
    _purchaseDateController.text = _formatDate(purchase.purchaseDate);
    _selectedCustomerId = purchase.customerId;
    _isVAT = purchase.isVAT;
    _isPaid = purchase.payment.isPaid;
    _paymentMethodController.text = purchase.payment.paymentMethod ?? '';
    _selectedAccountId = purchase.payment.ourAccount;
    _customerAccountController.text = purchase.payment.customerAccount ?? '';
    _paymentDateController.text = purchase.payment.paymentDate != null 
        ? _formatDate(purchase.payment.paymentDate!) 
        : '';
    _isWarehouseUpdated = purchase.warehouse.isUpdated;
    _warehouseNotesController.text = purchase.warehouse.notes ?? '';
    _notesController.text = purchase.notes ?? '';
    _shippingCostController.text = purchase.shippingCost.toString();
    _actualShippingController.text = purchase.warehouse.actualShipping.toString();
    _purchaseItems = List.from(purchase.items);
    _warehouseItems = List.from(purchase.warehouse.items);
    
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {});
      });
    }
  }

  void _populateFields() {
    final purchase = widget.purchase!;
    _populateFieldsFromPurchase(purchase);
  }

  @override
  Widget build(BuildContext context) {
    final purchaseId = widget.purchase?.id ?? widget.purchaseId;
    
    return Scaffold(
      appBar: ResponsiveAppBar(
        title: _isEdit ? 'แก้ไขรายการซื้อ' : 'เพิ่มรายการซื้อใหม่',
        leading: _isEdit && purchaseId != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/purchase/$purchaseId'),
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
                // Basic Info Section
                _buildBasicInfoSection(),
                
                const SizedBox(height: 24),
                
                // VAT Section
                _buildVATSection(),
                
                const SizedBox(height: 24),
                
                // Purchase Items Section
                _buildPurchaseItemsSection(),
                
                const SizedBox(height: 24),
                
                // Payment Section
                _buildPaymentSection(),
                
                const SizedBox(height: 24),
                
                // Warehouse Section
                _buildWarehouseSection(),
                
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
            
            // Purchase Date
            _buildDateField(
              controller: _purchaseDateController,
              label: 'วันที่ซื้อ *',
              onTap: () => _selectDate(_purchaseDateController),
            ),
            
            const SizedBox(height: 16),
            
            // Customer Selection
            _buildCustomerDropdown(),
            
            const SizedBox(height: 16),
            
            // Shipping Cost
            _buildTextField(
              controller: _shippingCostController,
              label: 'ค่าส่ง',
              hint: '0.00',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            
            const SizedBox(height: 16),
            
            // Notes
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

  Widget _buildPurchaseItemsSection() {
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
                  'สินค้าที่ซื้อ',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _addPurchaseItem,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('เพิ่มสินค้า'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (_purchaseItems.isEmpty)
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
              ...List.generate(_purchaseItems.length, (index) {
                return _buildPurchaseItemRow(index);
              }),
              
            // Total Summary
            if (_purchaseItems.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildTotalSummary(),
            ],
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
            ResponsiveText(
              'ข้อมูล VAT',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            CheckboxListTile(
              title: const Text('รายการซื้อนี้เป็น VAT (7%)'),
              value: _isVAT,
              onChanged: (value) {
                setState(() {
                  _isVAT = value ?? false;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
            ),
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
            
            CheckboxListTile(
              title: const Text('จ่ายเงินแล้ว'),
              value: _isPaid,
              onChanged: (value) {
                setState(() {
                  _isPaid = value ?? false;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
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
            _buildTextField(
              controller: _customerAccountController,
              label: 'บัญชีรับเงินของลูกค้า',
              hint: 'เลขบัญชีหรือชื่อบัญชีลูกค้า',
            ),
            const SizedBox(height: 16),
            _buildDateField(
              controller: _paymentDateController,
              label: 'วันที่จ่ายเงิน',
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
                      onPressed: _copyFromPurchaseItems,
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('คัดลอกจากซื้อ'),
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
              controller: _actualShippingController,
              label: 'ค่าส่งจริง',
              hint: '0.00',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            
            const SizedBox(height: 16),
            _buildTextField(
              controller: _warehouseNotesController,
              label: 'หมายเหตุคลังสินค้า',
              hint: 'ข้อมูลเพิ่มเติมเกี่ยวกับการรับสินค้า',
              maxLines: 3,
            ),
            
            const SizedBox(height: 16),
            
            // Warehouse Items List
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
    return Consumer<CustomerProvider>(
      builder: (context, customerProvider, child) {
        return SearchableDropdown<String>(
          value: _selectedCustomerId,
          items: customerProvider.allCustomers.map((customer) => customer.id).toList(),
          itemAsString: (customerId) {
            final customer = customerProvider.allCustomers.firstWhere((c) => c.id == customerId);
            return '${customer.companyName.isNotEmpty ? customer.companyName : customer.contactName} (${customer.customerCode})';
          },
          itemAsValue: (customerId) => customerId,
          onChanged: (value) {
            setState(() {
              _selectedCustomerId = value;
            });
          },
          hint: 'เลือกลูกค้า',
          label: 'ลูกค้า *',
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'กรุณาเลือกลูกค้า';
            }
            return null;
          },
          prefixIcon: const Icon(Icons.person),
        );
      },
    );
  }

  Widget _buildAccountDropdown() {
    final configService = ConfigService();
    
    return FutureBuilder<void>(
      future: configService.isLoaded ? Future.value() : configService.loadConfig(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ResponsiveText(
                'บัญชีที่ใช้จ่าย *',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('กำลังโหลดบัญชี...'),
                  ],
                ),
              ),
            ],
          );
        }
        
        if (snapshot.hasError) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ResponsiveText(
                'บัญชีที่ใช้จ่าย *',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.red),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Error: ${snapshot.error}'),
              ),
            ],
          );
        }
        
         final accounts = configService.accounts;

         return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResponsiveText(
              'บัญชีที่ใช้จ่าย *',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedAccountId,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              hint: const Text('เลือกบัญชี'),
              items: accounts.map((account) {
                return DropdownMenuItem<String>(
                  value: account.id,
                  child: Text(account.displayName),
                );
              }).toList(),
               onChanged: (String? newValue) {
                 setState(() {
                   _selectedAccountId = newValue;
                 });
               },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'กรุณาเลือกบัญชี';
                }
                return null;
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildPurchaseItemRow(int index) {
    final item = _purchaseItems[index];
    final vatAmount = _isVAT ? item.totalPrice * 0.07 : 0.0;
    final itemTotalWithVAT = item.totalPrice + vatAmount;
    
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
              Expanded(
                child: Text(
                  '${item.productName} (${item.productCode})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _removePurchaseItem(index),
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
    final totalBeforeVAT = _purchaseItems.fold(0.0, (sum, item) => sum + item.totalPrice);
    final totalVAT = _isVAT ? totalBeforeVAT * 0.07 : 0.0;
    final grandTotal = totalBeforeVAT + totalVAT;
    
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
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ยอดรวมที่ต้องจ่าย:',
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
                  color: Colors.blue,
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
          onTap: onTap,
          readOnly: onTap != null,
        ),
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
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Widget _buildActionButtons(bool isEdit) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isLoading ? null : () => context.go('/purchases'),
            child: const Text('ยกเลิก'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _savePurchase,
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

  void _addPurchaseItem() {
    showDialog(
      context: context,
      builder: (context) => _buildAddItemDialog(),
    );
  }

  Widget _buildAddItemDialog() {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        return AlertDialog(
          title: const Text('เพิ่มสินค้า'),
          content: SizedBox(
            width: double.maxFinite,
            child: _AddItemForm(
              products: productProvider.allProducts,
              onAdd: (item) {
                setState(() {
                  _purchaseItems.add(item);
                });
                Navigator.of(context).pop();
              },
            ),
          ),
        );
      },
    );
  }

  void _removePurchaseItem(int index) {
    setState(() {
      _purchaseItems.removeAt(index);
    });
  }

  void _copyFromPurchaseItems() {
    setState(() {
      _warehouseItems = _purchaseItems.map((item) => WarehouseItem(
        productId: item.productId,
        productName: item.productName,
        quantity: item.quantity,
        boxes: 1, // Default 1 box
        notes: null,
      )).toList();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('คัดลอกรายการสินค้าจากการซื้อแล้ว'),
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
    final quantityController = TextEditingController(text: item.quantity.toString());
    final boxesController = TextEditingController(text: item.boxes.toString());
    final notesController = TextEditingController(text: item.notes ?? '');
    
    return Container(
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
                  controller: quantityController,
                  decoration: const InputDecoration(
                    labelText: 'จำนวน',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final quantity = int.tryParse(value) ?? 0;
                    _warehouseItems[index] = WarehouseItem(
                      productId: item.productId,
                      productName: item.productName,
                      quantity: quantity,
                      boxes: item.boxes,
                      notes: item.notes,
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: boxesController,
                  decoration: const InputDecoration(
                    labelText: 'ลัง',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final boxes = int.tryParse(value) ?? 0;
                    _warehouseItems[index] = WarehouseItem(
                      productId: item.productId,
                      productName: item.productName,
                      quantity: item.quantity,
                      boxes: boxes,
                      notes: item.notes,
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: notesController,
            decoration: const InputDecoration(
              labelText: 'หมายเหตุ',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
            maxLines: 2,
            onChanged: (value) {
              _warehouseItems[index] = WarehouseItem(
                productId: item.productId,
                productName: item.productName,
                quantity: item.quantity,
                boxes: item.boxes,
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
      // Parse DD/MM/YYYY format
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

  Future<void> _savePurchase() async {
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

    if (_purchaseItems.isEmpty) {
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
      final purchaseRequest = PurchaseRequest(
        purchaseDate: DateTime.now(), // TODO: Parse from controller
        customerId: _selectedCustomerId!,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        items: _purchaseItems,
        isVAT: _isVAT,
        shippingCost: double.tryParse(_shippingCostController.text) ?? 0.0,
        payment: PaymentInfo(
          isPaid: _isPaid,
          paymentMethod: _paymentMethodController.text.trim().isEmpty ? null : _paymentMethodController.text.trim(),
          ourAccount: _selectedAccountId,
          customerAccount: _customerAccountController.text.trim().isEmpty ? null : _customerAccountController.text.trim(),
          paymentDate: _paymentDateController.text.trim().isEmpty ? null : _parsePaymentDate(),
        ),
        warehouse: WarehouseInfo(
          isUpdated: _isWarehouseUpdated,
          notes: _warehouseNotesController.text.trim().isEmpty ? null : _warehouseNotesController.text.trim(),
          actualShipping: double.tryParse(_actualShippingController.text) ?? 0.0,
          items: _warehouseItems.isEmpty ? [] : _warehouseItems,
        ),
      );

      final purchaseProvider = context.read<PurchaseProvider>();
      bool success;
      
      if (_isEdit) {
        final purchaseId = widget.purchase?.id ?? widget.purchaseId!;
        success = await purchaseProvider.updatePurchase(purchaseId, purchaseRequest);
      } else {
        success = await purchaseProvider.addPurchase(purchaseRequest);
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEdit 
                  ? 'อัปเดตรายการซื้อเรียบร้อยแล้ว' 
                  : 'เพิ่มรายการซื้อเรียบร้อยแล้ว',
            ),
            backgroundColor: Colors.green,
          ),
        );
        
        // Redirect based on edit or create
        if (_isEdit) {
          // Go back to purchase detail page
          final purchaseId = widget.purchase?.id ?? widget.purchaseId!;
          context.go('/purchase/$purchaseId');
        } else {
          // Go to purchase list
          context.go('/purchases');
        }
      } else if (mounted) {
        // Show error popup if not successful
        final errorMessage = purchaseProvider.error;
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
  final Function(PurchaseItem) onAdd;

  const _AddItemForm({
    required this.products,
    required this.onAdd,
  });

  @override
  State<_AddItemForm> createState() => _AddItemFormState();
}

class _AddItemFormState extends State<_AddItemForm> {
  final _formKey = GlobalKey<FormState>();
  Product? _selectedProduct;
  final _quantityController = TextEditingController();
  final _unitPriceController = TextEditingController();

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
          // Product Selection
          SearchableDropdown<Product>(
            value: _selectedProduct,
            items: widget.products,
            itemAsString: (product) => '${product.name} (${product.code})',
            onChanged: (product) {
              setState(() {
                _selectedProduct = product;
              });
            },
            hint: 'เลือกสินค้า',
            label: 'เลือกสินค้า *',
            validator: (value) {
              if (value == null) {
                return 'กรุณาเลือกสินค้า';
              }
              return null;
            },
            prefixIcon: const Icon(Icons.inventory),
          ),
          
          const SizedBox(height: 16),
          
          // Quantity
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
          
          // Unit Price
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
          
          // Action Buttons
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
    final unitPrice = double.parse(_unitPriceController.text);
    final totalPrice = quantity * unitPrice;

    final item = PurchaseItem(
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
          // Product Selection
          SearchableDropdown<Product>(
            value: _selectedProduct,
            items: widget.products,
            itemAsString: (product) => '${product.name} (${product.code})',
            onChanged: (product) {
              setState(() {
                _selectedProduct = product;
              });
            },
            hint: 'เลือกสินค้า',
            label: 'เลือกสินค้า *',
            validator: (value) {
              if (value == null) {
                return 'กรุณาเลือกสินค้า';
              }
              return null;
            },
            prefixIcon: const Icon(Icons.inventory),
          ),
          
          const SizedBox(height: 16),
          
          // Quantity
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
          
          // Boxes
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
          
          // Notes
          TextFormField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'หมายเหตุ',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          
          const SizedBox(height: 24),
          
          // Action Buttons
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
