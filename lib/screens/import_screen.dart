import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import '../widgets/responsive_layout.dart';
import '../config/env_config.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({Key? key}) : super(key: key);

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  bool _isLoading = false;
  String? _selectedType;
  PlatformFile? _selectedFile;
  String? _resultMessage;
  String? _resultCsv;
  int _successCount = 0;
  int _failCount = 0;

  final List<Map<String, String>> _importTypes = [
    {'value': 'customers', 'label': 'ลูกค้า (Customers)'},
    {'value': 'products', 'label': 'สินค้า (Products)'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ResponsiveAppBar(
        title: 'Import ข้อมูล',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instructions Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        const Text(
                          'วิธีใช้งาน',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    const Text('1. ดาวน์โหลด Template CSV ตามประเภทที่ต้องการ'),
                    const Text('2. กรอกข้อมูลในไฟล์ CSV'),
                    const Text('3. เลือกประเภทและอัปโหลดไฟล์'),
                    const Text('4. ดาวน์โหลด Result CSV เพื่อดู ID ใหม่'),
                    const SizedBox(height: 16),
                    const Text(
                      '⚠️ หมายเหตุ: ข้อมูลที่ซ้ำกันจะถูกสร้างใหม่เป็น record แยก',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Download Templates
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.download, color: Colors.green[700]),
                        const SizedBox(width: 8),
                        const Text(
                          'ดาวน์โหลด Template',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _downloadTemplate('customers'),
                          icon: const Icon(Icons.business),
                          label: const Text('Template ลูกค้า'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _downloadTemplate('products'),
                          icon: const Icon(Icons.inventory_2),
                          label: const Text('Template สินค้า'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Upload Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.upload_file, color: Colors.purple[700]),
                        const SizedBox(width: 8),
                        const Text(
                          'อัปโหลดไฟล์ CSV',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Type Selection
                    DropdownButtonFormField<String>(
                      value: _selectedType,
                      decoration: const InputDecoration(
                        labelText: 'ประเภทข้อมูล',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: _importTypes.map((type) {
                        return DropdownMenuItem<String>(
                          value: type['value'],
                          child: Text(type['label']!),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedType = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // File Selection
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _selectedFile?.name ?? 'ยังไม่ได้เลือกไฟล์',
                              style: TextStyle(
                                color: _selectedFile != null ? Colors.black : Colors.grey,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: _pickFile,
                          icon: const Icon(Icons.folder_open),
                          label: const Text('เลือกไฟล์'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Upload Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading || _selectedFile == null || _selectedType == null
                            ? null
                            : _uploadFile,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.cloud_upload),
                        label: Text(_isLoading ? 'กำลังอัปโหลด...' : 'อัปโหลดและ Import'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Result Section
            if (_resultMessage != null)
              Card(
                color: _failCount == 0 ? Colors.green[50] : Colors.orange[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _failCount == 0 ? Icons.check_circle : Icons.warning,
                            color: _failCount == 0 ? Colors.green : Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'ผลลัพธ์',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      Text(_resultMessage!),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Chip(
                            label: Text('สำเร็จ: $_successCount'),
                            backgroundColor: Colors.green[100],
                          ),
                          const SizedBox(width: 8),
                          Chip(
                            label: Text('ล้มเหลว: $_failCount'),
                            backgroundColor: _failCount > 0 ? Colors.red[100] : Colors.grey[100],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_resultCsv != null)
                        ElevatedButton.icon(
                          onPressed: _downloadResultCsv,
                          icon: const Icon(Icons.download),
                          label: const Text('ดาวน์โหลด Result CSV'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFile = result.files.first;
          _resultMessage = null;
          _resultCsv = null;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    }
  }

  Future<void> _downloadTemplate(String type) async {
    final url = '${EnvConfig.apiUrl}/import/$type/template';
    
    if (kIsWeb) {
      html.window.open(url, '_blank');
    }
  }

  Future<void> _uploadFile() async {
    if (_selectedFile == null || _selectedType == null) return;

    setState(() {
      _isLoading = true;
      _resultMessage = null;
      _resultCsv = null;
    });

    try {
      final url = '${EnvConfig.apiUrl}/import/$_selectedType';
      
      final request = http.MultipartRequest('POST', Uri.parse(url));
      
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          _selectedFile!.bytes!,
          filename: _selectedFile!.name,
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        // Parse headers for counts
        final successCount = int.tryParse(response.headers['x-import-success'] ?? '0') ?? 0;
        final failCount = int.tryParse(response.headers['x-import-failed'] ?? '0') ?? 0;
        final total = successCount + failCount;

        setState(() {
          _successCount = successCount;
          _failCount = failCount;
          _resultMessage = 'Import เสร็จสิ้น: $total รายการ';
          _resultCsv = response.body;
        });
      } else {
        setState(() {
          _resultMessage = 'เกิดข้อผิดพลาด: ${response.body}';
          _failCount = 1;
          _successCount = 0;
        });
      }
    } catch (e) {
      setState(() {
        _resultMessage = 'เกิดข้อผิดพลาด: $e';
        _failCount = 1;
        _successCount = 0;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _downloadResultCsv() {
    if (_resultCsv == null) return;

    final bytes = utf8.encode(_resultCsv!);
    final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
    final url = html.Url.createObjectUrlFromBlob(blob);
    
    html.AnchorElement(href: url)
      ..setAttribute('download', '${_selectedType}_result_${DateTime.now().millisecondsSinceEpoch}.csv')
      ..click();
    
    html.Url.revokeObjectUrl(url);
  }
}

