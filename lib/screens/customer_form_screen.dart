import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../models/customer.dart';
import '../providers/customer_provider.dart';
import '../widgets/responsive_layout.dart';
import '../utils/error_dialog.dart';

class CustomerFormScreen extends StatefulWidget {
  final Customer? customer;
  final String? customerId;

  const CustomerFormScreen({Key? key, this.customer, this.customerId}) : super(key: key);

  @override
  State<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _taxIdController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _contactMethodController = TextEditingController();

  bool _isLoading = false;
  bool get _isEdit => widget.customer != null || widget.customerId != null;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.customer != null) {
      _populateFields();
    } else if (widget.customerId != null) {
      _loadCustomerFromId();
    }
  }

  void _loadCustomerFromId() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final customer = context.read<CustomerProvider>().getCustomerById(widget.customerId!);
      if (customer != null) {
        _populateFieldsFromCustomer(customer);
      }
    });
  }

  void _populateFieldsFromCustomer(Customer customer) {
    _companyNameController.text = customer.companyName;
    _contactNameController.text = customer.contactName;
    _taxIdController.text = customer.taxId;
    _phoneController.text = customer.phone;
    _addressController.text = customer.address;
    _contactMethodController.text = customer.contactMethod;
    
    if (mounted) {
      setState(() {});
    }
  }

  void _populateFields() {
    final customer = widget.customer!;
    _populateFieldsFromCustomer(customer);
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _contactNameController.dispose();
    _taxIdController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _contactMethodController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ResponsiveAppBar(
        title: _isEdit ? 'แก้ไขลูกค้า' : 'เพิ่มลูกค้าใหม่',
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
              'ข้อมูลลูกค้า/ซัพพลายเออร์',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Company Name
            _buildTextField(
              controller: _companyNameController,
              label: 'ชื่อบริษัท',
              hint: 'กรอกชื่อบริษัท',
            ),
            
            const SizedBox(height: 16),
            
            // Contact Name
            _buildTextField(
              controller: _contactNameController,
              label: 'ชื่อผู้ติดต่อ *',
              hint: 'กรอกชื่อผู้ติดต่อ',
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'กรุณากรอกชื่อผู้ติดต่อ';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Tax ID
            _buildTextField(
              controller: _taxIdController,
              label: 'เลขที่ผู้เสียภาษี',
              hint: 'กรอกเลขที่ผู้เสียภาษี',
            ),
            
            const SizedBox(height: 16),
            
            // Phone
            _buildTextField(
              controller: _phoneController,
              label: 'เบอร์โทร *',
              hint: 'กรอกเบอร์โทร',
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'กรุณากรอกเบอร์โทร';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Address
            _buildTextField(
              controller: _addressController,
              label: 'ที่อยู่',
              hint: 'กรอกที่อยู่',
              maxLines: 3,
            ),
            
            const SizedBox(height: 16),
            
            // Contact Method
            _buildTextField(
              controller: _contactMethodController,
              label: 'ช่องทางติดต่อ',
              hint: 'เช่น อีเมล, Line, Facebook',
            ),
          ],
        ),
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
            onPressed: _isLoading ? null : () => context.go('/customers'),
            child: const Text('ยกเลิก'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveCustomer,
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

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final customerRequest = CustomerRequest(
        companyName: _companyNameController.text.trim(),
        contactName: _contactNameController.text.trim(),
        taxId: _taxIdController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        contactMethod: _contactMethodController.text.trim(),
      );

      final customerProvider = context.read<CustomerProvider>();
      bool success;
      
      if (_isEdit) {
        final customerId = widget.customer?.id ?? widget.customerId!;
        success = await customerProvider.updateCustomer(customerId, customerRequest);
      } else {
        success = await customerProvider.addCustomer(customerRequest);
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEdit 
                  ? 'อัปเดตลูกค้าเรียบร้อยแล้ว' 
                  : 'เพิ่มลูกค้าเรียบร้อยแล้ว',
            ),
            backgroundColor: Colors.green,
          ),
        );
        
        // Redirect based on edit or create
        if (_isEdit) {
          // Go back to customer detail page
          final customerId = widget.customer?.id ?? widget.customerId!;
          context.go('/customer/$customerId');
        } else {
          // Go to customer list
          context.go('/customers');
        }
      } else if (mounted) {
        // Show error popup if not successful
        final errorMessage = customerProvider.error;
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
