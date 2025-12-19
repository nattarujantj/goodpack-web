import 'package:flutter/material.dart';
import '../services/export_service.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({Key? key}) : super(key: key);

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Default emails
  final List<String> _defaultEmails = [
    'nattaruja.ntj@gmail.com',
    'goodpackagingsupply@hotmail.com',
    'gamyooy@hotmail.com',
  ];
  
  late List<String> _selectedEmails;
  final TextEditingController _customEmailController = TextEditingController();
  
  // Month/Year selection
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  
  bool _isLoading = false;
  String? _statusMessage;
  bool? _isSuccess;

  @override
  void initState() {
    super.initState();
    _selectedEmails = List.from(_defaultEmails);
  }

  @override
  void dispose() {
    _customEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export รายการซื้อ/ขาย'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Icon(Icons.file_download, 
                            size: 32, 
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'ส่งออกข้อมูลทาง Email',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ระบบจะสร้างไฟล์ Excel ที่มี 2 Sheet (รายการซื้อ และ รายการขาย) แล้วส่งไปยัง Email ที่เลือก',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      const Divider(height: 32),
                      
                      // Month/Year Selection
                      const Text(
                        'เลือกเดือน/ปี',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          // Month dropdown
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: _selectedMonth,
                              decoration: const InputDecoration(
                                labelText: 'เดือน',
                                border: OutlineInputBorder(),
                              ),
                              items: List.generate(12, (index) {
                                final month = index + 1;
                                return DropdownMenuItem(
                                  value: month,
                                  child: Text(_getThaiMonthName(month)),
                                );
                              }),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _selectedMonth = value);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Year dropdown
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: _selectedYear,
                              decoration: const InputDecoration(
                                labelText: 'ปี',
                                border: OutlineInputBorder(),
                              ),
                              items: List.generate(5, (index) {
                                final year = DateTime.now().year - 2 + index;
                                return DropdownMenuItem(
                                  value: year,
                                  child: Text('${year + 543}'), // แสดงเป็น พ.ศ.
                                );
                              }),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _selectedYear = value);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Email Selection
                      const Text(
                        'ส่งไปยัง Email',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Default emails with checkboxes
                      ..._defaultEmails.map((email) => CheckboxListTile(
                        title: Text(email),
                        value: _selectedEmails.contains(email),
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              _selectedEmails.add(email);
                            } else {
                              _selectedEmails.remove(email);
                            }
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      )).toList(),
                      
                      // Custom emails
                      const SizedBox(height: 8),
                      ..._selectedEmails
                          .where((e) => !_defaultEmails.contains(e))
                          .map((email) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Chip(
                                    label: Text(email),
                                    deleteIcon: const Icon(Icons.close, size: 18),
                                    onDeleted: () {
                                      setState(() {
                                        _selectedEmails.remove(email);
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ))
                          .toList(),
                      
                      // Add custom email
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _customEmailController,
                              decoration: const InputDecoration(
                                labelText: 'เพิ่ม Email อื่น',
                                hintText: 'example@email.com',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.emailAddress,
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: _addCustomEmail,
                            icon: const Icon(Icons.add),
                            label: const Text('เพิ่ม'),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Status message
                      if (_statusMessage != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _isSuccess == true 
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _isSuccess == true 
                                  ? Colors.green 
                                  : Colors.red,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _isSuccess == true 
                                    ? Icons.check_circle 
                                    : Icons.error,
                                color: _isSuccess == true 
                                    ? Colors.green 
                                    : Colors.red,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _statusMessage!,
                                  style: TextStyle(
                                    color: _isSuccess == true 
                                        ? Colors.green[800] 
                                        : Colors.red[800],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      const SizedBox(height: 24),
                      
                      // Export button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _selectedEmails.isEmpty || _isLoading 
                              ? null 
                              : _exportAndSendEmail,
                          icon: _isLoading 
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send),
                          label: Text(
                            _isLoading 
                                ? 'กำลังส่ง...' 
                                : 'ส่ง Export ไปยัง Email',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      
                      if (_selectedEmails.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'กรุณาเลือกอย่างน้อย 1 Email',
                            style: TextStyle(
                              color: Colors.red[600],
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getThaiMonthName(int month) {
    const thaiMonths = [
      'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน',
      'พฤษภาคม', 'มิถุนายน', 'กรกฎาคม', 'สิงหาคม',
      'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม',
    ];
    return thaiMonths[month - 1];
  }

  void _addCustomEmail() {
    final email = _customEmailController.text.trim();
    if (email.isEmpty) return;
    
    // Simple email validation
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณากรอก Email ที่ถูกต้อง'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (_selectedEmails.contains(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email นี้ถูกเพิ่มแล้ว'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    setState(() {
      _selectedEmails.add(email);
      _customEmailController.clear();
    });
  }

  Future<void> _exportAndSendEmail() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
      _isSuccess = null;
    });

    try {
      final result = await ExportService.exportAndSendEmail(
        month: _selectedMonth,
        year: _selectedYear,
        emails: _selectedEmails,
      );
      
      setState(() {
        _isLoading = false;
        _isSuccess = result['success'] == true;
        _statusMessage = result['message'] ?? 
            (_isSuccess! ? 'ส่ง Email สำเร็จ!' : 'เกิดข้อผิดพลาด');
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isSuccess = false;
        _statusMessage = 'เกิดข้อผิดพลาด: $e';
      });
    }
  }
}

