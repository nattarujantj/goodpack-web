import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../models/quotation.dart';
import '../models/product.dart';
import '../providers/quotation_provider.dart';
import '../providers/customer_provider.dart';
import '../providers/product_provider.dart';
import '../providers/bank_account_provider.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/searchable_dropdown.dart';
import '../widgets/bank_account_selector.dart';
import '../models/bank_account.dart';
import '../utils/error_dialog.dart';

class QuotationFormScreen extends StatefulWidget {
  final Quotation? quotation;
  final String? quotationId;

  const QuotationFormScreen({Key? key, this.quotation, this.quotationId}) : super(key: key);

  @override
  State<QuotationFormScreen> createState() => _QuotationFormScreenState();
}

class _QuotationFormScreenState extends State<QuotationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quotationDateController = TextEditingController();
  final _notesController = TextEditingController();
  final _quotationCodeController = TextEditingController();
  final _shippingCostController = TextEditingController();
  final _validUntilController = TextEditingController();

  String? _selectedCustomerId;
  BankAccount? _selectedBankAccount;
  bool _isVAT = false;
  String _status = 'draft';
  List<QuotationItem> _quotationItems = [];

  bool _isLoading = false;
  bool get _isEdit => widget.quotation != null || widget.quotationId != null;

  @override
  void initState() {
    super.initState();
    _initializeForm();
    _loadData();
  }

  void _initializeForm() {
    _quotationDateController.text = _formatDate(DateTime.now());
    _shippingCostController.text = ''; // ปล่อยว่างให้ user กรอกเอง
    _validUntilController.text = _formatDate(DateTime.now().add(const Duration(days: 30)));
    
    // ใส่ default notes สำหรับใบเสนอราคาใหม่ (ไม่ใช่ Edit)
    if (!_isEdit) {
      _notesController.text = '''ใบเสนอราคา ใช้ได้ 10 วัน ทำการ
ลูกค้าได้ตกลงสีของสินค้าและสั่งผลิต
ระยะเวลาผลิต 25 วัน หลังชำระมัดจำ
ชำระเงินมัดจำก่อนผลิต 50% และอีก 50% ก่อนจัดส่งสินค้า''';
    }
  }

  void _loadData() async {
    final customerProvider = context.read<CustomerProvider>();
    final productProvider = context.read<ProductProvider>();
    
    if (_isEdit) {
      setState(() => _isLoading = true);
      
      try {
        // Load customers and products only if not already loaded
        final futures = <Future>[];
        
        if (customerProvider.allCustomers.isEmpty && !customerProvider.isLoading) {
          futures.add(customerProvider.loadCustomers());
        }
        
        if (productProvider.allProducts.isEmpty && !productProvider.isLoading) {
          futures.add(productProvider.loadProducts());
        }
        
        if (futures.isNotEmpty) {
          await Future.wait(futures);
        }

        // Load quotation data if editing
        if (widget.quotationId != null) {
          final quotation = context.read<QuotationProvider>().getQuotationById(widget.quotationId!);
          if (quotation != null) {
            _populateForm(quotation);
          }
        } else if (widget.quotation != null) {
          _populateForm(widget.quotation!);
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
          setState(() => _isLoading = false);
        }
      }
    } else {
      // Load customers and products for new quotation only if not already loaded
      final futures = <Future>[];
      
      if (customerProvider.allCustomers.isEmpty && !customerProvider.isLoading) {
        futures.add(customerProvider.loadCustomers());
      }
      
      if (productProvider.allProducts.isEmpty && !productProvider.isLoading) {
        futures.add(productProvider.loadProducts());
      }
      
      if (futures.isNotEmpty) {
        await Future.wait(futures);
        // Force rebuild after data loaded
        if (mounted) {
          setState(() {});
        }
      }
    }
  }

  void _populateForm(Quotation quotation) {
    _quotationDateController.text = _formatDate(quotation.quotationDate);
    _selectedCustomerId = quotation.customerId;
    _isVAT = quotation.isVAT;
    _status = quotation.status;
    _shippingCostController.text = quotation.shippingCost.toStringAsFixed(2);
    _notesController.text = quotation.notes ?? '';
    _quotationCodeController.text = quotation.quotationCode;
    _quotationItems = List.from(quotation.items);
    
    // Set selected bank account if exists
    if (quotation.bankAccountId != null) {
      try {
        final bankAccountProvider = context.read<BankAccountProvider>();
        _selectedBankAccount = bankAccountProvider.getBankAccountById(quotation.bankAccountId!);
      } catch (e) {
        // If account not found, set to null
        _selectedBankAccount = null;
      }
    }
    
    if (quotation.validUntil != null) {
      _validUntilController.text = _formatDate(quotation.validUntil!);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  DateTime? _parseDate(String dateStr) {
    try {
      final parts = dateStr.split('/');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      }
    } catch (e) {
      // Invalid date format
    }
    return null;
  }

  @override
  void dispose() {
    _quotationDateController.dispose();
    _notesController.dispose();
    _quotationCodeController.dispose();
    _shippingCostController.dispose();
    _validUntilController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quotationId = widget.quotation?.id ?? widget.quotationId;
    
    return Scaffold(
      appBar: ResponsiveAppBar(
        title: _isEdit ? 'แก้ไขเสนอราคา' : 'เพิ่มเสนอราคา',
        leading: _isEdit && quotationId != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/quotation/$quotationId'),
                tooltip: 'กลับไปหน้ารายละเอียด',
              )
            : null,
        actions: [
          if (_isEdit)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _showDeleteDialog,
              tooltip: 'ลบ',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Basic Information Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ResponsiveText(
                              'ข้อมูลพื้นฐาน',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Quotation Code (read-only if editing)
                            if (_isEdit) ...[
                              _buildTextField(
                                controller: _quotationCodeController,
                                label: 'รหัสเสนอราคา',
                                enabled: false,
                                prefixIcon: const Icon(Icons.description),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Quotation Date
                            _buildTextField(
                              controller: _quotationDateController,
                              label: 'วันที่เสนอราคา *',
                              prefixIcon: const Icon(Icons.calendar_today),
                              onTap: () => _selectDate(_quotationDateController),
                            ),
                            const SizedBox(height: 16),

                            // Valid Until Date
                            _buildTextField(
                              controller: _validUntilController,
                              label: 'ราคาใช้ได้ถึง',
                              prefixIcon: const Icon(Icons.event),
                              onTap: () => _selectDate(_validUntilController),
                            ),
                            const SizedBox(height: 16),

                            // Customer Selection
                            _buildCustomerDropdown(),
                            const SizedBox(height: 16),

                            // Bank Account Selection
                            BankAccountSelector(
                              selectedAccount: _selectedBankAccount,
                              onChanged: (account) {
                                setState(() {
                                  _selectedBankAccount = account;
                                });
                              },
                              label: 'บัญชีรับเงิน',
                            ),
                            const SizedBox(height: 16),

                            // VAT Checkbox
                            Row(
                              children: [
                                Checkbox(
                                  value: _isVAT,
                                  onChanged: _isEdit ? null : (value) {
                                    setState(() {
                                      _isVAT = value ?? false;
                                    });
                                  },
                                ),
                                Text(
                                  'มี VAT (7%)',
                                  style: TextStyle(
                                    color: _isEdit ? Colors.grey : null,
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

                            // Status Dropdown
                            DropdownButtonFormField<String>(
                              value: _status,
                              decoration: const InputDecoration(
                                labelText: 'สถานะ *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.flag),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'draft', child: Text('ร่าง')),
                                DropdownMenuItem(value: 'sent', child: Text('ส่งแล้ว')),
                                DropdownMenuItem(value: 'accepted', child: Text('ยอมรับ')),
                                DropdownMenuItem(value: 'rejected', child: Text('ปฏิเสธ')),
                                DropdownMenuItem(value: 'expired', child: Text('หมดอายุ')),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _status = value ?? 'draft';
                                });
                              },
                            ),
                            const SizedBox(height: 16),

                            // Shipping Cost
                            _buildTextField(
                              controller: _shippingCostController,
                              label: 'ค่าขนส่ง (บาท)',
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              prefixIcon: const Icon(Icons.local_shipping),
                            ),
                            const SizedBox(height: 16),

                            // Notes
                            _buildTextField(
                              controller: _notesController,
                              label: 'หมายเหตุ',
                              maxLines: 3,
                              prefixIcon: const Icon(Icons.note),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Items Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                ResponsiveText(
                                  'รายการสินค้า',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: _addItem,
                                  icon: const Icon(Icons.add),
                                  label: const Text('เพิ่มสินค้า'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            if (_quotationItems.isEmpty)
                              Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.inventory_2_outlined,
                                      size: 64,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'ยังไม่มีรายการสินค้า',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'กดปุ่ม "เพิ่มสินค้า" เพื่อเพิ่มรายการ',
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              ..._quotationItems.asMap().entries.map((entry) {
                                final index = entry.key;
                                final item = entry.value;
                                return _buildItemCard(index, item);
                              }),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Summary Card
                    if (_quotationItems.isNotEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ResponsiveText(
                                'สรุปยอดรวม',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildSummaryRow(),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 32),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => context.go('/quotations'),
                            child: const Text('ยกเลิก'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _saveQuotation,
                            child: Text(_isEdit ? 'อัปเดต' : 'บันทึก'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool enabled = true,
    TextInputType? keyboardType,
    int maxLines = 1,
    Widget? prefixIcon,
    VoidCallback? onTap,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon,
        border: const OutlineInputBorder(),
      ),
      onTap: onTap,
      validator: (value) {
        if (label.contains('*') && (value == null || value.isEmpty)) {
          return 'กรุณากรอกข้อมูล';
        }
        return null;
      },
    );
  }

  Widget _buildCustomerDropdown() {
    return Consumer<CustomerProvider>(
      builder: (context, customerProvider, child) {
        // แสดง loading indicator ถ้ากำลังโหลด
        if (customerProvider.isLoading) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ลูกค้า *',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.person, color: Colors.grey),
                    SizedBox(width: 12),
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('กำลังโหลดข้อมูลลูกค้า...', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ],
          );
        }
        
        return SearchableDropdown<String>(
          value: _selectedCustomerId,
          items: customerProvider.allCustomers.map((customer) => customer.id).toList(),
          itemAsString: (customerId) {
            final customer = customerProvider.allCustomers.firstWhere((c) => c.id == customerId);
            return '${customer.companyName.isNotEmpty ? customer.companyName : customer.contactName} (${customer.customerCode})';
          },
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

  Widget _buildItemCard(int index, QuotationItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.productName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeItem(index),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text('รหัส: ${item.productCode}'),
                ),
                Expanded(
                  child: Text('จำนวน: ${item.quantity}'),
                ),
                Expanded(
                  child: Text('ราคา: ฿${item.unitPrice.toStringAsFixed(2)}'),
                ),
                Expanded(
                  child: Text(
                    'รวม: ฿${item.totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow() {
    final subtotal = _quotationItems.fold(0.0, (sum, item) => sum + item.totalPrice);
    final vatAmount = _isVAT ? subtotal * 0.07 : 0.0;
    final shippingCost = double.tryParse(_shippingCostController.text) ?? 0.0;
    final grandTotal = subtotal + vatAmount + shippingCost;

    return Column(
      children: [
        _buildSummaryItem('ยอดรวมก่อน VAT', subtotal),
        if (_isVAT) _buildSummaryItem('VAT (7%)', vatAmount),
        _buildSummaryItem('ค่าขนส่ง', shippingCost),
        const Divider(),
        _buildSummaryItem('ยอดรวมทั้งสิ้น', grandTotal, isTotal: true),
      ],
    );
  }

  Widget _buildSummaryItem(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '฿${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Theme.of(context).primaryColor : null,
            ),
          ),
        ],
      ),
    );
  }

  void _selectDate(TextEditingController controller) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _parseDate(controller.text) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (date != null) {
      controller.text = _formatDate(date);
    }
  }

  void _addItem() {
    showDialog(
      context: context,
      builder: (dialogContext) {
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
            
            return _AddItemDialog(
              products: productProvider.allProducts,
              onAdd: (item) {
                setState(() {
                  _quotationItems.add(item);
                });
              },
            );
          },
        );
      },
    );
  }

  void _removeItem(int index) {
    setState(() {
      _quotationItems.removeAt(index);
    });
  }

  void _saveQuotation() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_quotationItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาเพิ่มรายการสินค้าอย่างน้อย 1 รายการ'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final quotationRequest = QuotationRequest(
        quotationDate: _parseDate(_quotationDateController.text) ?? DateTime.now(),
        customerId: _selectedCustomerId!,
        items: _quotationItems,
        isVAT: _isVAT,
        shippingCost: double.tryParse(_shippingCostController.text) ?? 0.0,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        validUntil: _validUntilController.text.isNotEmpty 
            ? _parseDate(_validUntilController.text) 
            : null,
        status: _status,
        bankAccountId: _selectedBankAccount?.id,
        bankName: _selectedBankAccount?.bankName,
        bankAccountName: _selectedBankAccount?.bankAccountName,
        bankAccountNumber: _selectedBankAccount?.accountNumber,
      );

      bool success;
      if (_isEdit) {
        final id = widget.quotationId ?? widget.quotation?.id;
        success = await context.read<QuotationProvider>().updateQuotation(id!, quotationRequest);
      } else {
        success = await context.read<QuotationProvider>().addQuotation(quotationRequest);
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit ? 'อัปเดตเสนอราคาเรียบร้อยแล้ว' : 'เพิ่มเสนอราคาเรียบร้อยแล้ว'),
            backgroundColor: Colors.green,
          ),
        );
        // Redirect to quotation list
        context.go('/quotations');
      } else if (mounted) {
        // Show error popup if not successful
        final quotationProvider = context.read<QuotationProvider>();
        final errorMessage = quotationProvider.error ?? 'เกิดข้อผิดพลาดที่ไม่ทราบสาเหตุ';
        ErrorDialog.showServerError(context, errorMessage);
      }
    } catch (e) {
      if (mounted) {
        ErrorDialog.showServerError(context, 'เกิดข้อผิดพลาด: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: const Text('คุณต้องการลบเสนอราคานี้หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final id = widget.quotationId ?? widget.quotation?.id;
              if (id != null) {
                final success = await context.read<QuotationProvider>().deleteQuotation(id);
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('ลบเสนอราคาเรียบร้อยแล้ว'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  context.pop();
                }
              }
            },
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
  }
}

class _AddItemDialog extends StatefulWidget {
  final List<Product> products;
  final Function(QuotationItem) onAdd;

  const _AddItemDialog({
    required this.products,
    required this.onAdd,
  });

  @override
  State<_AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<_AddItemDialog> {
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
    return AlertDialog(
      title: const Text('เพิ่มสินค้า'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          SearchableDropdown<Product>(
            value: _selectedProduct,
            items: widget.products,
            itemAsString: (product) => '${product.name} (${product.code})',
            onChanged: (product) {
              setState(() {
                _selectedProduct = product;
                // ไม่ prefill ราคา ให้ user กรอกเอง
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
          TextFormField(
            controller: _quantityController,
            keyboardType: const TextInputType.numberWithOptions(decimal: false),
            decoration: const InputDecoration(
              labelText: 'จำนวน *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.numbers),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
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
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'ราคาต่อหน่วย (บาท) *',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'กรุณากรอกราคา';
              }
              if (double.tryParse(value) == null || double.parse(value) < 0) {
                return 'กรุณากรอกราคาที่ถูกต้อง';
              }
              return null;
            },
          ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('ยกเลิก'),
        ),
        ElevatedButton(
          onPressed: _addItem,
          child: const Text('เพิ่ม'),
        ),
      ],
    );
  }

  void _addItem() {
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาเลือกสินค้า'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final quantity = int.tryParse(_quantityController.text);
    final unitPrice = double.tryParse(_unitPriceController.text);

    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณากรอกจำนวนที่ถูกต้อง'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (unitPrice == null || unitPrice < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณากรอกราคาที่ถูกต้อง'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final item = QuotationItem(
      productId: _selectedProduct!.id,
      productName: _selectedProduct!.name,
      productCode: _selectedProduct!.code,
      quantity: quantity,
      unitPrice: unitPrice,
      totalPrice: quantity * unitPrice,
    );

    widget.onAdd(item);
    Navigator.of(context).pop();
  }
}