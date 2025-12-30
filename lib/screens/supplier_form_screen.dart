import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../models/supplier.dart';
import '../models/contact.dart';
import '../providers/supplier_provider.dart';
import '../widgets/responsive_layout.dart';
import '../utils/error_dialog.dart';

class SupplierFormScreen extends StatefulWidget {
  final Supplier? supplier;
  final String? supplierId;
  final String? duplicateId;

  const SupplierFormScreen({Key? key, this.supplier, this.supplierId, this.duplicateId}) : super(key: key);

  @override
  State<SupplierFormScreen> createState() => _SupplierFormScreenState();
}

class _SupplierFormScreenState extends State<SupplierFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _taxIdController = TextEditingController();
  final _addressController = TextEditingController();
  final _contactMethodController = TextEditingController();

  // รายการผู้ติดต่อ
  List<Contact> _contacts = [];

  bool _isLoading = false;
  bool get _isEdit => widget.supplier != null || widget.supplierId != null;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.supplier != null) {
      _populateFields();
    } else if (widget.supplierId != null) {
      _loadSupplierFromId();
    } else if (widget.duplicateId != null) {
      _loadDuplicateSupplier();
    } else {
      // สร้างผู้ติดต่อหลักเริ่มต้นสำหรับซัพพลายเออร์ใหม่
      _contacts = [Contact(name: '', phone: '', isDefault: true)];
    }
  }

  void _loadDuplicateSupplier() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final supplierProvider = context.read<SupplierProvider>();
      
      if (supplierProvider.allSuppliers.isEmpty) {
        await supplierProvider.loadSuppliers();
      }
      
      final supplier = supplierProvider.getSupplierById(widget.duplicateId!);
      if (supplier != null) {
        _populateFieldsForDuplicate(supplier);
      }
    });
  }

  void _populateFieldsForDuplicate(Supplier supplier) {
    _companyNameController.text = '${supplier.companyName} (สำเนา)';
    _taxIdController.text = '';
    _addressController.text = supplier.address;
    _contactMethodController.text = supplier.contactMethod;
    
    // Copy contacts
    if (supplier.contacts.isNotEmpty) {
      _contacts = supplier.contacts.map((c) => Contact(
        name: c.name,
        phone: c.phone,
        isDefault: c.isDefault,
      )).toList();
    } else if (supplier.contactName.isNotEmpty) {
      _contacts = [Contact(name: supplier.contactName, phone: supplier.phone, isDefault: true)];
    } else {
      _contacts = [Contact(name: '', phone: '', isDefault: true)];
    }
    
    if (mounted) setState(() {});
  }

  void _loadSupplierFromId() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final supplier = context.read<SupplierProvider>().getSupplierById(widget.supplierId!);
      if (supplier != null) {
        _populateFieldsFromSupplier(supplier);
      }
    });
  }

  void _populateFieldsFromSupplier(Supplier supplier) {
    _companyNameController.text = supplier.companyName;
    _taxIdController.text = supplier.taxId;
    _addressController.text = supplier.address;
    _contactMethodController.text = supplier.contactMethod;
    
    // Load contacts
    if (supplier.contacts.isNotEmpty) {
      _contacts = supplier.contacts.map((c) => Contact(
        name: c.name,
        phone: c.phone,
        isDefault: c.isDefault,
      )).toList();
    } else if (supplier.contactName.isNotEmpty) {
      // Migrate legacy data
      _contacts = [Contact(name: supplier.contactName, phone: supplier.phone, isDefault: true)];
    } else {
      _contacts = [Contact(name: '', phone: '', isDefault: true)];
    }
    
    if (mounted) setState(() {});
  }

  void _populateFields() {
    final supplier = widget.supplier!;
    _populateFieldsFromSupplier(supplier);
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _taxIdController.dispose();
    _addressController.dispose();
    _contactMethodController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final supplierId = widget.supplier?.id ?? widget.supplierId;
    
    return Scaffold(
      appBar: ResponsiveAppBar(
        title: _isEdit ? 'แก้ไขซัพพลายเออร์' : 'เพิ่มซัพพลายเออร์ใหม่',
        leading: _isEdit && supplierId != null
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
                // ข้อมูลบริษัท
                _buildCompanyInfoCard(),
                
                const SizedBox(height: 16),
                
                // ผู้ติดต่อ
                _buildContactsCard(),
                
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

  Widget _buildCompanyInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResponsiveText(
              'ข้อมูลซัพพลายเออร์',
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
            
            // Tax ID
            _buildTextField(
              controller: _taxIdController,
              label: 'เลขที่ผู้เสียภาษี',
              hint: 'กรอกเลขที่ผู้เสียภาษี',
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

  Widget _buildContactsCard() {
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
                  'ผู้ติดต่อ',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: _addContact,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('เพิ่มผู้ติดต่อ'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Contact List
            ..._contacts.asMap().entries.map((entry) {
              final index = entry.key;
              final contact = entry.value;
              return _buildContactItem(index, contact);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem(int index, Contact contact) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: contact.isDefault ? Colors.blue : Colors.grey.shade300,
          width: contact.isDefault ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
        color: contact.isDefault ? Colors.blue.shade50 : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with default badge and actions
          Row(
            children: [
              if (contact.isDefault)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '⭐ หลัก',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                )
              else
                TextButton.icon(
                  onPressed: () => _setDefaultContact(index),
                  icon: const Icon(Icons.star_border, size: 16),
                  label: const Text('ตั้งเป็นหลัก', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              const Spacer(),
              if (_contacts.length > 1)
                IconButton(
                  onPressed: () => _removeContact(index),
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  tooltip: 'ลบผู้ติดต่อ',
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Name field
          TextFormField(
            initialValue: contact.name,
            decoration: InputDecoration(
              labelText: 'ชื่อผู้ติดต่อ ${contact.isDefault ? '*' : ''}',
              hintText: 'กรอกชื่อผู้ติดต่อ',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              isDense: true,
            ),
            validator: contact.isDefault 
                ? (value) => value?.trim().isEmpty == true ? 'กรุณากรอกชื่อผู้ติดต่อหลัก' : null
                : null,
            onChanged: (value) {
              _contacts[index] = contact.copyWith(name: value);
            },
          ),
          
          const SizedBox(height: 12),
          
          // Phone field
          TextFormField(
            initialValue: contact.phone,
            decoration: InputDecoration(
              labelText: 'เบอร์โทร ${contact.isDefault ? '*' : ''}',
              hintText: 'กรอกเบอร์โทร',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              isDense: true,
            ),
            keyboardType: TextInputType.phone,
            validator: contact.isDefault 
                ? (value) => value?.trim().isEmpty == true ? 'กรุณากรอกเบอร์โทรหลัก' : null
                : null,
            onChanged: (value) {
              _contacts[index] = contact.copyWith(phone: value);
            },
          ),
        ],
      ),
    );
  }

  void _addContact() {
    setState(() {
      _contacts.add(Contact(name: '', phone: '', isDefault: false));
    });
  }

  void _removeContact(int index) {
    if (_contacts.length <= 1) return;
    
    final wasDefault = _contacts[index].isDefault;
    setState(() {
      _contacts.removeAt(index);
      // If removed contact was default, set first one as default
      if (wasDefault && _contacts.isNotEmpty) {
        _contacts[0] = _contacts[0].copyWith(isDefault: true);
      }
    });
  }

  void _setDefaultContact(int index) {
    setState(() {
      _contacts = _contacts.asMap().entries.map((entry) {
        return entry.value.copyWith(isDefault: entry.key == index);
      }).toList();
    });
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
            onPressed: _isLoading ? null : () => context.go('/suppliers'),
            child: const Text('ยกเลิก'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveSupplier,
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

  Future<void> _saveSupplier() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Filter out empty contacts
    final validContacts = _contacts.where((c) => c.name.trim().isNotEmpty || c.phone.trim().isNotEmpty).toList();
    
    if (validContacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาเพิ่มผู้ติดต่ออย่างน้อย 1 คน'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Ensure at least one default contact
    if (!validContacts.any((c) => c.isDefault)) {
      validContacts[0] = validContacts[0].copyWith(isDefault: true);
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get primary contact for legacy fields
      final primaryContact = validContacts.firstWhere((c) => c.isDefault, orElse: () => validContacts.first);
      
      final supplierRequest = SupplierRequest(
        companyName: _companyNameController.text.trim(),
        contactName: primaryContact.name.trim(),
        taxId: _taxIdController.text.trim(),
        phone: primaryContact.phone.trim(),
        address: _addressController.text.trim(),
        contactMethod: _contactMethodController.text.trim(),
        contacts: validContacts,
      );

      final supplierProvider = context.read<SupplierProvider>();
      String? resultSupplierId;
      
      if (_isEdit) {
        final supplierId = widget.supplier?.id ?? widget.supplierId!;
        final success = await supplierProvider.updateSupplier(supplierId, supplierRequest);
        if (success) resultSupplierId = supplierId;
      } else {
        final newSupplier = await supplierProvider.addSupplier(supplierRequest);
        resultSupplierId = newSupplier?.id;
      }

      if (resultSupplierId != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEdit 
                  ? 'อัปเดตซัพพลายเออร์เรียบร้อยแล้ว' 
                  : 'เพิ่มซัพพลายเออร์เรียบร้อยแล้ว',
            ),
            backgroundColor: Colors.green,
          ),
        );
        
        context.go('/supplier/$resultSupplierId');
      } else if (mounted) {
        final errorMessage = supplierProvider.error;
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
