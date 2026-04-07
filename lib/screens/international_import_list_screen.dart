import 'package:flutter/material.dart' hide SearchBar;
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/international_import.dart';
import '../providers/international_import_provider.dart';
import '../providers/supplier_provider.dart';
import '../providers/shipping_company_provider.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/search_bar.dart';
import '../utils/date_formatter.dart';

class InternationalImportListScreen extends StatefulWidget {
  const InternationalImportListScreen({Key? key}) : super(key: key);

  @override
  State<InternationalImportListScreen> createState() => _InternationalImportListScreenState();
}

class _InternationalImportListScreenState extends State<InternationalImportListScreen> {
  String _searchQuery = '';
  String _typeFilter = 'ทั้งหมด';
  String _statusFilter = 'ทั้งหมด';
  DateTime? _startDate;
  DateTime? _endDate;
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();

  final _currencyFormat = NumberFormat('#,##0.00');

  @override
  void initState() {
    super.initState();
    _initDefaultDateRange();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InternationalImportProvider>().loadIfNeeded();
      context.read<SupplierProvider>().loadSuppliersIfNeeded();
      context.read<ShippingCompanyProvider>().loadIfNeeded();
    });
  }

  void _initDefaultDateRange() {
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month - 1, 1);
    _endDate = DateTime(now.year, now.month + 1, 0);
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  /// Flatten all imports into per-item rows
  List<_FlatRow> _buildFlatRows(List<InternationalImport> imports) {
    final rows = <_FlatRow>[];
    for (final imp in imports) {
      // Date filter
      if (_startDate != null && imp.importDate.isBefore(_startDate!)) continue;
      if (_endDate != null && imp.importDate.isAfter(_endDate!.add(const Duration(days: 1)))) continue;
      // Type filter
      if (_typeFilter != 'ทั้งหมด' && imp.importType != _typeFilter) continue;
      // Status filter
      if (_statusFilter != 'ทั้งหมด') {
        if (_statusFilter == 'draft' && imp.status != 'draft') continue;
        if (_statusFilter == 'purchased' && imp.status != 'purchased') continue;
      }

      for (final item in imp.items) {
        // Search filter
        if (_searchQuery.isNotEmpty) {
          final q = _searchQuery.toLowerCase();
          final match = item.productName.toLowerCase().contains(q) ||
              item.productCode.toLowerCase().contains(q) ||
              imp.importCode.toLowerCase().contains(q) ||
              imp.supplierName.toLowerCase().contains(q);
          if (!match) continue;
        }
        rows.add(_FlatRow(import_: imp, item: item));
      }
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ResponsiveAppBar(
        title: 'International',
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/international-form'),
            tooltip: 'สร้างรายการนำเข้า',
          ),
        ],
      ),
      body: Consumer<InternationalImportProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && !provider.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error.isNotEmpty && !provider.hasData) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(provider.error),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: provider.refresh, child: const Text('ลองใหม่')),
                ],
              ),
            );
          }

          final rows = _buildFlatRows(provider.allImports);

          return Column(
            children: [
              // Filters
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    SearchBar(
                      hintText: 'ค้นหาสินค้า, รหัสสินค้า, เลขที่รายการ, supplier...',
                      onSearchChanged: (v) => setState(() => _searchQuery = v),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          // Type filter
                          _buildFilterChip('ทั้งหมด', _typeFilter, (v) => setState(() => _typeFilter = v)),
                          const SizedBox(width: 4),
                          _buildFilterChip('LCL', _typeFilter, (v) => setState(() => _typeFilter = v)),
                          const SizedBox(width: 4),
                          _buildFilterChip('FCL', _typeFilter, (v) => setState(() => _typeFilter = v)),
                          const SizedBox(width: 12),
                          // Status filter
                          ChoiceChip(
                            label: const Text('Draft'),
                            selected: _statusFilter == 'draft',
                            onSelected: (s) => setState(() => _statusFilter = s ? 'draft' : 'ทั้งหมด'),
                          ),
                          const SizedBox(width: 4),
                          ChoiceChip(
                            label: const Text('สร้างรายการซื้อแล้ว'),
                            selected: _statusFilter == 'purchased',
                            onSelected: (s) => setState(() => _statusFilter = s ? 'purchased' : 'ทั้งหมด'),
                          ),
                          const SizedBox(width: 12),
                          // Date range
                          ActionChip(
                            avatar: const Icon(Icons.date_range, size: 18),
                            label: Text(
                              _startDate != null && _endDate != null
                                  ? '${DateFormat('dd/MM/yy').format(_startDate!)} - ${DateFormat('dd/MM/yy').format(_endDate!)}'
                                  : 'เลือกช่วงวันที่',
                            ),
                            onPressed: _pickDateRange,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Table
              Expanded(
                child: rows.isEmpty
                    ? const Center(child: Text('ไม่พบรายการ'))
                    : Scrollbar(
                        controller: _verticalScrollController,
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          controller: _verticalScrollController,
                          child: Scrollbar(
                            controller: _horizontalScrollController,
                            thumbVisibility: true,
                            notificationPredicate: (n) => n.depth == 0,
                            child: SingleChildScrollView(
                              controller: _horizontalScrollController,
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                columnSpacing: 16,
                                headingRowColor: WidgetStateProperty.all(Colors.grey[100]),
                                columns: const [
                                  DataColumn(label: Text('เลขที่')),
                                  DataColumn(label: Text('วันที่')),
                                  DataColumn(label: Text('ประเภท')),
                                  DataColumn(label: Text('Supplier')),
                                  DataColumn(label: Text('Shipping')),
                                  DataColumn(label: Text('สินค้า')),
                                  DataColumn(label: Text('จำนวน'), numeric: true),
                                  DataColumn(label: Text('CBM'), numeric: true),
                                  DataColumn(label: Text('ต้นทุน/ชิ้น\n(ก่อน VAT)'), numeric: true),
                                  DataColumn(label: Text('ต้นทุน/ชิ้น\n(หลัง VAT)'), numeric: true),
                                  DataColumn(label: Text('สถานะ')),
                                ],
                                rows: rows.map((row) {
                                  return DataRow(
                                    onSelectChanged: (_) => context.push('/international/${row.import_.id}'),
                                    cells: [
                                      DataCell(Text(row.import_.importCode, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.blue))),
                                      DataCell(Text(DateFormatter.formatDate(row.import_.importDate))),
                                      DataCell(_buildTypeBadge(row.import_.importType)),
                                      DataCell(Text(row.import_.supplierName, overflow: TextOverflow.ellipsis)),
                                      DataCell(Text(row.import_.shippingCompanyName, overflow: TextOverflow.ellipsis)),
                                      DataCell(
                                        ConstrainedBox(
                                          constraints: const BoxConstraints(maxWidth: 180),
                                          child: Text('${row.item.productCode}\n${row.item.productName}',
                                              style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis, maxLines: 2),
                                        ),
                                      ),
                                      DataCell(Text('${row.item.quantity}')),
                                      DataCell(Text(row.item.cbm.toStringAsFixed(1))),
                                      DataCell(Text(_currencyFormat.format(row.item.costPerUnitBeforeVAT))),
                                      DataCell(Text(_currencyFormat.format(row.item.costPerUnitAfterVAT))),
                                      DataCell(_buildStatusBadge(row.import_.status)),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                      ),
              ),
              // Count
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text('${rows.length} รายการ', style: TextStyle(color: Colors.grey[600])),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/international-form'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterChip(String label, String current, ValueChanged<String> onSelect) {
    return ChoiceChip(
      label: Text(label),
      selected: current == label,
      onSelected: (s) => onSelect(label),
    );
  }

  Widget _buildTypeBadge(String type) {
    final isLCL = type == 'LCL';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isLCL ? Colors.blue[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(type, style: TextStyle(color: isLCL ? Colors.blue[700] : Colors.orange[700], fontWeight: FontWeight.w500, fontSize: 12)),
    );
  }

  Widget _buildStatusBadge(String status) {
    final isPurchased = status == 'purchased';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isPurchased ? Colors.green[50] : Colors.grey[100],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isPurchased ? 'สร้างรายการซื้อแล้ว' : 'Draft',
        style: TextStyle(color: isPurchased ? Colors.green[700] : Colors.grey[600], fontWeight: FontWeight.w500, fontSize: 12),
      ),
    );
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }
}

class _FlatRow {
  final InternationalImport import_;
  final ImportItem item;
  _FlatRow({required this.import_, required this.item});
}
