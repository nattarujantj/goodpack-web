import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../models/expense.dart';
import '../services/expense_api_service.dart';
import '../services/image_upload_service.dart';
import '../widgets/responsive_layout.dart';

/// A file selected in the form before the expense has been saved.
class _PendingAttachment {
  final String fileName;
  final List<int> bytes;
  final String fileType; // "pdf" or "image"

  _PendingAttachment({
    required this.fileName,
    required this.bytes,
    required this.fileType,
  });
}

class ExpenseFormScreen extends StatefulWidget {
  final String? expenseId;

  const ExpenseFormScreen({Key? key, this.expenseId}) : super(key: key);

  @override
  State<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedCategory = '';
  DateTime _expenseDate = DateTime.now();
  bool _isLoading = false;
  bool _isEdit = false;
  List<String> _categories = [];

  // Attachment state
  List<ExpenseAttachment> _attachments = [];
  final List<_PendingAttachment> _pendingAttachments = [];
  bool _isUploadingAttachment = false;

  static const _allowedExtensions = ['pdf', 'jpg', 'jpeg', 'png', 'gif', 'webp'];

  @override
  void initState() {
    super.initState();
    _isEdit = widget.expenseId != null;
    _loadCategories();
    if (_isEdit) {
      _loadExpense();
    }
  }

  Future<void> _loadCategories() async {
    final cats = await ExpenseApiService.getCategories();
    if (mounted) {
      setState(() {
        _categories = cats;
        if (_selectedCategory.isEmpty && cats.isNotEmpty) {
          _selectedCategory = cats.first;
        }
      });
    }
  }

  Future<void> _loadExpense() async {
    final provider = context.read<ExpenseProvider>();
    var expense = provider.getExpenseById(widget.expenseId!);
    expense ??= await provider.fetchExpenseById(widget.expenseId!);

    if (expense != null && mounted) {
      setState(() {
        _selectedCategory = expense!.category;
        _descriptionController.text = expense.description;
        _amountController.text = expense.amount.toString();
        _notesController.text = expense.notes;
        _expenseDate = expense.expenseDate;
        _attachments = List<ExpenseAttachment>.from(expense.attachments);
      });
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final request = ExpenseRequest(
      category: _selectedCategory,
      description: _descriptionController.text.trim(),
      amount: double.tryParse(_amountController.text) ?? 0,
      expenseDate: DateFormat('yyyy-MM-dd').format(_expenseDate),
      notes: _notesController.text.trim(),
    );

    final provider = context.read<ExpenseProvider>();
    Expense? result;

    if (_isEdit) {
      result = await provider.updateExpense(widget.expenseId!, request);
    } else {
      result = await provider.createExpense(request);
    }

    // Upload any files that were selected before the expense existed.
    if (result != null && _pendingAttachments.isNotEmpty) {
      for (final pending in _pendingAttachments) {
        await provider.uploadAttachment(
          result.id,
          pending.bytes,
          pending.fileName,
        );
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEdit ? 'แก้ไขสำเร็จ' : 'เพิ่มค่าใช้จ่ายสำเร็จ')),
        );
        context.go('/expenses');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: ${provider.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expenseDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _expenseDate = picked);
    }
  }

  String _fileTypeFromName(String name) {
    return name.toLowerCase().endsWith('.pdf') ? 'pdf' : 'image';
  }

  Future<void> _pickAndAddFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: _allowedExtensions,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;
    final picked = result.files.first;
    final bytes = picked.bytes;
    if (bytes == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ไม่สามารถอ่านไฟล์ได้'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final fileType = _fileTypeFromName(picked.name);

    // In edit mode the expense already exists, so upload immediately.
    if (_isEdit && widget.expenseId != null) {
      setState(() => _isUploadingAttachment = true);
      final provider = context.read<ExpenseProvider>();
      final attachment = await provider.uploadAttachment(
        widget.expenseId!,
        bytes,
        picked.name,
      );
      if (mounted) {
        setState(() {
          _isUploadingAttachment = false;
          if (attachment != null) {
            _attachments.add(attachment);
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(attachment != null
                ? 'อัพโหลดไฟล์สำเร็จ'
                : 'อัพโหลดไฟล์ไม่สำเร็จ: ${provider.error}'),
            backgroundColor: attachment != null ? null : Colors.red,
          ),
        );
      }
    } else {
      // Create mode: hold the file until the expense is saved.
      setState(() {
        _pendingAttachments.add(_PendingAttachment(
          fileName: picked.name,
          bytes: bytes,
          fileType: fileType,
        ));
      });
    }
  }

  Future<void> _deleteAttachment(ExpenseAttachment attachment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ลบไฟล์แนบ'),
        content: Text('ต้องการลบ "${attachment.fileName}" ใช่ไหม?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final provider = context.read<ExpenseProvider>();
    final ok = await provider.deleteAttachment(widget.expenseId!, attachment.id);
    if (mounted && ok) {
      setState(() => _attachments.removeWhere((a) => a.id == attachment.id));
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ลบไฟล์ไม่สำเร็จ: ${provider.error}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _viewAttachment(ExpenseAttachment attachment) {
    final url = ImageUploadService.getImageUrl(attachment.fileUrl);
    if (attachment.isImage) {
      showDialog<void>(
        context: context,
        builder: (ctx) => Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        attachment.fileName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.open_in_new),
                      tooltip: 'เปิดในแท็บใหม่',
                      onPressed: () => html.window.open(url, '_blank'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: InteractiveViewer(
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('ไม่สามารถแสดงรูปภาพได้'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // PDFs open in a new browser tab.
      html.window.open(url, '_blank');
    }
  }

  String _formatSize(int bytes) {
    if (bytes <= 0) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Widget _buildAttachmentSection() {
    final hasAny = _attachments.isNotEmpty || _pendingAttachments.isNotEmpty;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.attach_file, size: 18),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'ไฟล์แนบ (บิล/ใบเสร็จ)',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
                if (_isUploadingAttachment)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  TextButton.icon(
                    onPressed: _pickAndAddFile,
                    icon: const Icon(Icons.upload_file, size: 18),
                    label: const Text('อัพโหลด'),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'รองรับไฟล์ PDF และรูปภาพ (ขนาดไม่เกิน 10MB)',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
            if (!_isEdit)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'ไฟล์จะถูกอัพโหลดเมื่อกดบันทึกรายการ',
                  style: TextStyle(fontSize: 11, color: Colors.orange),
                ),
              ),
            const SizedBox(height: 8),
            if (!hasAny)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'ยังไม่มีไฟล์แนบ',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
            ..._attachments.map(_buildSavedAttachmentTile),
            ..._pendingAttachments.map(_buildPendingAttachmentTile),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedAttachmentTile(ExpenseAttachment attachment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(
          attachment.isPdf ? Icons.picture_as_pdf : Icons.image,
          color: attachment.isPdf ? Colors.red.shade400 : Colors.blue.shade400,
        ),
        title: Text(
          attachment.fileName,
          style: const TextStyle(fontSize: 13),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: attachment.size > 0
            ? Text(_formatSize(attachment.size),
                style: const TextStyle(fontSize: 11))
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.visibility, size: 20),
              tooltip: 'เปิดดูไฟล์',
              onPressed: () => _viewAttachment(attachment),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, size: 20, color: Colors.red.shade300),
              tooltip: 'ลบ',
              onPressed: () => _deleteAttachment(attachment),
            ),
          ],
        ),
        onTap: () => _viewAttachment(attachment),
      ),
    );
  }

  Widget _buildPendingAttachmentTile(_PendingAttachment pending) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.orange.shade200),
        borderRadius: BorderRadius.circular(8),
        color: Colors.orange.shade50,
      ),
      child: ListTile(
        dense: true,
        leading: Icon(
          pending.fileType == 'pdf' ? Icons.picture_as_pdf : Icons.image,
          color: Colors.orange.shade700,
        ),
        title: Text(
          pending.fileName,
          style: const TextStyle(fontSize: 13),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: const Text('รอการอัพโหลด', style: TextStyle(fontSize: 11)),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline, size: 20, color: Colors.red.shade300),
          tooltip: 'นำออก',
          onPressed: () =>
              setState(() => _pendingAttachments.remove(pending)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ResponsiveAppBar(
        title: _isEdit ? 'แก้ไขค่าใช้จ่าย' : 'เพิ่มค่าใช้จ่าย',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/expenses');
            }
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('หมวดหมู่',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600, fontSize: 14)),
                                const SizedBox(height: 8),
                                if (_categories.isNotEmpty)
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: _categories.map((cat) {
                                      final isSelected = _selectedCategory == cat;
                                      return ChoiceChip(
                                        label: Text(cat),
                                        selected: isSelected,
                                        onSelected: (selected) {
                                          if (selected) {
                                            setState(() => _selectedCategory = cat);
                                          }
                                        },
                                        selectedColor:
                                            Theme.of(context).primaryColor.withOpacity(0.2),
                                      );
                                    }).toList(),
                                  )
                                else
                                  const CircularProgressIndicator(),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextFormField(
                                  controller: _descriptionController,
                                  decoration: const InputDecoration(
                                    labelText: 'รายละเอียด',
                                    hintText: 'เช่น ค่าน้ำมันรถส่งของ',
                                    prefixIcon: Icon(Icons.description),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _amountController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(
                                    labelText: 'จำนวนเงิน (บาท) *',
                                    hintText: '0.00',
                                    prefixIcon: Icon(Icons.attach_money),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return 'กรุณากรอกจำนวนเงิน';
                                    final amount = double.tryParse(v);
                                    if (amount == null || amount <= 0) {
                                      return 'กรุณากรอกจำนวนเงินที่ถูกต้อง';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                InkWell(
                                  onTap: _pickDate,
                                  child: InputDecorator(
                                    decoration: const InputDecoration(
                                      labelText: 'วันที่',
                                      prefixIcon: Icon(Icons.calendar_today),
                                    ),
                                    child: Text(
                                      DateFormat('dd/MM/yyyy').format(_expenseDate),
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _notesController,
                                  maxLines: 3,
                                  decoration: const InputDecoration(
                                    labelText: 'หมายเหตุ',
                                    hintText: 'หมายเหตุเพิ่มเติม (ถ้ามี)',
                                    prefixIcon: Icon(Icons.note),
                                    alignLabelWithHint: true,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildAttachmentSection(),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  if (context.canPop()) {
                                    context.pop();
                                  } else {
                                    context.go('/expenses');
                                  }
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: const Text('ยกเลิก'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: FilledButton.icon(
                                onPressed: _isLoading ? null : _saveExpense,
                                icon: Icon(_isEdit ? Icons.save : Icons.add),
                                label: Text(_isEdit ? 'บันทึก' : 'เพิ่มค่าใช้จ่าย'),
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
