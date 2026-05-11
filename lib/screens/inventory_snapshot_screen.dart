import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/nav_menu_button.dart';
import '../models/inventory_snapshot.dart';
import '../providers/inventory_snapshot_provider.dart';

class InventorySnapshotScreen extends StatefulWidget {
  const InventorySnapshotScreen({Key? key}) : super(key: key);

  @override
  State<InventorySnapshotScreen> createState() => _InventorySnapshotScreenState();
}

class _InventorySnapshotScreenState extends State<InventorySnapshotScreen> {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  bool _isTaking = false;
  bool _isEditing = false;

  // Controllers for inline editing: key = productId
  final Map<String, TextEditingController> _vatControllers = {};
  final Map<String, TextEditingController> _nonVatControllers = {};
  final Map<String, TextEditingController> _actualControllers = {};

  @override
  void dispose() {
    for (final c in _vatControllers.values) c.dispose();
    for (final c in _nonVatControllers.values) c.dispose();
    for (final c in _actualControllers.values) c.dispose();
    super.dispose();
  }

  void _initEditControllers(List<ProductSnapshotItem> products) {
    for (final c in _vatControllers.values) c.dispose();
    for (final c in _nonVatControllers.values) c.dispose();
    for (final c in _actualControllers.values) c.dispose();
    _vatControllers.clear();
    _nonVatControllers.clear();
    _actualControllers.clear();

    for (final p in products) {
      _vatControllers[p.productId] = TextEditingController(text: p.vatRemaining.toString());
      _nonVatControllers[p.productId] = TextEditingController(text: p.nonVATRemaining.toString());
      _actualControllers[p.productId] = TextEditingController(text: p.actualStock.toString());
    }
  }

  Future<void> _loadSnapshot() async {
    setState(() => _isEditing = false);
    await context.read<InventorySnapshotProvider>().loadSnapshot(_selectedMonth, _selectedYear);
  }

  Future<void> _takeSnapshot() async {
    setState(() => _isTaking = true);
    final ok = await context.read<InventorySnapshotProvider>().takeManualSnapshot(_selectedMonth, _selectedYear);
    setState(() => _isTaking = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'สร้าง Snapshot สำเร็จ' : 'เกิดข้อผิดพลาด'),
        backgroundColor: ok ? Colors.green : Colors.red,
      ),
    );
  }

  void _startEditing(List<ProductSnapshotItem> products) {
    _initEditControllers(products);
    setState(() => _isEditing = true);
  }

  void _cancelEditing() {
    setState(() => _isEditing = false);
  }

  Future<void> _saveEditing(InventorySnapshot snapshot) async {
    final products = snapshot.products.map((p) {
      return p.copyWith(
        vatRemaining: int.tryParse(_vatControllers[p.productId]?.text ?? '') ?? p.vatRemaining,
        nonVATRemaining: int.tryParse(_nonVatControllers[p.productId]?.text ?? '') ?? p.nonVATRemaining,
        actualStock: int.tryParse(_actualControllers[p.productId]?.text ?? '') ?? p.actualStock,
      ).toJson();
    }).toList();

    final ok = await context.read<InventorySnapshotProvider>().updateSnapshot(
      snapshot.month,
      snapshot.year,
      products,
    );

    if (!mounted) return;
    if (ok) {
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('บันทึกสำเร็จ'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('บันทึกไม่สำเร็จ กรุณาลองใหม่'), backgroundColor: Colors.red),
      );
    }
  }

  static const _thaiMonths = [
    'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน',
    'พฤษภาคม', 'มิถุนายน', 'กรกฎาคม', 'สิงหาคม',
    'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม',
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<InventorySnapshotProvider>(
      builder: (context, provider, _) {
        final snapshot = provider.selectedSnapshot;

        return Scaffold(
          appBar: AppBar(
            leading: const NavMenuButton(),
            title: const Text('สินค้าคงคลังรายเดือน'),
            actions: [
              if (snapshot != null && !_isEditing)
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'แก้ไข Snapshot',
                  onPressed: () => _startEditing(snapshot.products),
                ),
              if (_isEditing) ...[
                TextButton(
                  onPressed: _cancelEditing,
                  child: const Text('ยกเลิก', style: TextStyle(color: Colors.white)),
                ),
                TextButton(
                  onPressed: provider.isLoading ? null : () => _saveEditing(snapshot!),
                  child: provider.isLoading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('บันทึก', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'รีเฟรช',
                onPressed: snapshot != null ? _loadSnapshot : null,
              ),
            ],
          ),
          body: Column(
            children: [
              _buildMonthYearPicker(provider),
              if (snapshot != null) _buildInfoCard(snapshot),
              Expanded(
                child: provider.isLoading && snapshot == null
                    ? const Center(child: CircularProgressIndicator())
                    : snapshot == null
                        ? _buildEmptyState(provider)
                        : _buildTable(snapshot, provider.isLoading),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMonthYearPicker(InventorySnapshotProvider provider) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<int>(
              value: _selectedMonth,
              decoration: const InputDecoration(labelText: 'เดือน', border: OutlineInputBorder(), isDense: true),
              items: List.generate(12, (i) => DropdownMenuItem(
                value: i + 1,
                child: Text(_thaiMonths[i]),
              )),
              onChanged: (v) { if (v != null) setState(() => _selectedMonth = v); },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<int>(
              value: _selectedYear,
              decoration: const InputDecoration(labelText: 'ปี', border: OutlineInputBorder(), isDense: true),
              items: List.generate(6, (i) {
                final y = DateTime.now().year - 2 + i;
                return DropdownMenuItem(value: y, child: Text('${y + 543}'));
              }),
              onChanged: (v) { if (v != null) setState(() => _selectedYear = v); },
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: provider.isLoading ? null : _loadSnapshot,
            child: const Text('ดู'),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: (_isTaking || provider.isLoading) ? null : _takeSnapshot,
            icon: _isTaking
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.camera_alt, size: 18),
            label: const Text('สร้าง Snapshot'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(InventorySnapshot snapshot) {
    final dateStr = '${snapshot.snapshotDate.day.toString().padLeft(2, '0')}/'
        '${snapshot.snapshotDate.month.toString().padLeft(2, '0')}/'
        '${snapshot.snapshotDate.year + 543} '
        '${snapshot.snapshotDate.hour.toString().padLeft(2, '0')}:'
        '${snapshot.snapshotDate.minute.toString().padLeft(2, '0')}';

    return Container(
      color: Colors.orange.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                Text('📅 บันทึกเมื่อ: $dateStr', style: const TextStyle(fontSize: 13)),
                Text('👤 สร้างโดย: ${snapshot.createdBy == "system" ? "ระบบอัตโนมัติ" : snapshot.createdBy}',
                    style: const TextStyle(fontSize: 13)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: snapshot.isManual ? Colors.blue.shade100 : Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    snapshot.isManual ? 'Manual' : 'Auto',
                    style: TextStyle(fontSize: 12, color: snapshot.isManual ? Colors.blue.shade800 : Colors.green.shade800),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Wrap(
            spacing: 16,
            children: [
              _summaryChip('VAT', snapshot.totalVATStock, Colors.blue),
              _summaryChip('Non-VAT', snapshot.totalNonVATStock, Colors.orange),
              _summaryChip('จริง', snapshot.totalActualStock, Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryChip(String label, int value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
        Text(
          value.toString(),
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _buildEmptyState(InventorySnapshotProvider provider) {
    if (provider.isLoading) return const Center(child: CircularProgressIndicator());
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'ยังไม่มี Snapshot สำหรับ ${_thaiMonths[_selectedMonth - 1]} ${_selectedYear + 543}',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'กด "สร้าง Snapshot" เพื่อบันทึกสถานะสินค้าคงคลังตอนนี้',
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _isTaking ? null : _takeSnapshot,
            icon: const Icon(Icons.camera_alt),
            label: const Text('สร้าง Snapshot'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(InventorySnapshot snapshot, bool loading) {
    return Stack(
      children: [
        Card(
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.grey[300]!),
          ),
          child: Scrollbar(
            thumbVisibility: true,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(Colors.grey[100]),
                  columnSpacing: 12,
                  columns: const [
                    DataColumn(label: Text('#', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('รหัส SKU', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('รหัสสินค้า', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('ชื่อสินค้า', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('หมวดหมู่', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('สี', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('ขนาด', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('คงเหลือ VAT', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                    DataColumn(label: Text('คงเหลือ Non-VAT', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                    DataColumn(label: Text('คงเหลือจริง', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                  ],
                  rows: [
                    ...snapshot.products.asMap().entries.map((entry) {
                      final i = entry.key;
                      final p = entry.value;
                      return _buildDataRow(i, p);
                    }),
                    _buildSummaryRow(snapshot),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (loading)
          const Positioned.fill(
            child: ColoredBox(
              color: Color(0x55FFFFFF),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }

  DataRow _buildDataRow(int index, ProductSnapshotItem p) {
    TextStyle? negativeStyle(int v) =>
        v < 0 ? const TextStyle(color: Colors.red, fontWeight: FontWeight.bold) : null;

    if (_isEditing) {
      return DataRow(cells: [
        DataCell(Text('${index + 1}')),
        DataCell(Text(p.skuId, style: const TextStyle(fontSize: 13))),
        DataCell(Text(p.code, style: const TextStyle(fontSize: 13))),
        DataCell(SizedBox(width: 160, child: Text(p.name, style: const TextStyle(fontSize: 13)))),
        DataCell(Text(p.category, style: const TextStyle(fontSize: 13))),
        DataCell(Text(p.color, style: const TextStyle(fontSize: 13))),
        DataCell(Text(p.size, style: const TextStyle(fontSize: 13))),
        DataCell(_editCell(_vatControllers[p.productId]!)),
        DataCell(_editCell(_nonVatControllers[p.productId]!)),
        DataCell(_editCell(_actualControllers[p.productId]!)),
      ]);
    }

    return DataRow(cells: [
      DataCell(Text('${index + 1}')),
      DataCell(Text(p.skuId, style: const TextStyle(fontSize: 13))),
      DataCell(Text(p.code, style: const TextStyle(fontSize: 13))),
      DataCell(SizedBox(width: 160, child: Text(p.name, style: const TextStyle(fontSize: 13)))),
      DataCell(Text(p.category, style: const TextStyle(fontSize: 13))),
      DataCell(Text(p.color, style: const TextStyle(fontSize: 13))),
      DataCell(Text(p.size, style: const TextStyle(fontSize: 13))),
      DataCell(Text(p.vatRemaining.toString(), style: negativeStyle(p.vatRemaining))),
      DataCell(Text(p.nonVATRemaining.toString(), style: negativeStyle(p.nonVATRemaining))),
      DataCell(Text(p.actualStock.toString(), style: negativeStyle(p.actualStock))),
    ]);
  }

  Widget _editCell(TextEditingController controller) {
    return SizedBox(
      width: 70,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.blue.shade50,
        ),
        style: const TextStyle(fontSize: 13),
      ),
    );
  }

  DataRow _buildSummaryRow(InventorySnapshot snapshot) {
    final bold = const TextStyle(fontWeight: FontWeight.bold, fontSize: 13);
    return DataRow(
      color: MaterialStateProperty.all(Colors.grey[50]),
      cells: [
        const DataCell(Text('')),
        const DataCell(Text('')),
        const DataCell(Text('')),
        DataCell(Text('รวม ${snapshot.totalProducts} รายการ', style: bold)),
        const DataCell(Text('')),
        const DataCell(Text('')),
        const DataCell(Text('')),
        DataCell(Text(snapshot.totalVATStock.toString(), style: bold.copyWith(color: Colors.blue))),
        DataCell(Text(snapshot.totalNonVATStock.toString(), style: bold.copyWith(color: Colors.orange))),
        DataCell(Text(snapshot.totalActualStock.toString(), style: bold.copyWith(color: Colors.green))),
      ],
    );
  }
}
