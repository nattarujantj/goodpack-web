import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/international_import.dart';
import '../models/product.dart';
import '../models/shipping_company.dart';
import '../providers/international_import_provider.dart';
import '../providers/supplier_provider.dart';
import '../providers/product_provider.dart';
import '../providers/shipping_company_provider.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/searchable_dropdown.dart';
import '../widgets/supplier_dropdown.dart';
import '../widgets/product_search_dropdown.dart';
import '../utils/error_dialog.dart';

class InternationalImportFormScreen extends StatefulWidget {
  final InternationalImport? import_;
  final String? importId;

  const InternationalImportFormScreen({Key? key, this.import_, this.importId}) : super(key: key);

  @override
  State<InternationalImportFormScreen> createState() => _InternationalImportFormScreenState();
}

class _InternationalImportFormScreenState extends State<InternationalImportFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _importDateController = TextEditingController();
  final _usdToThbRateController = TextEditingController();
  final _pricePerCBMController = TextEditingController();
  final _notesController = TextEditingController();

  String _importType = 'LCL';
  String? _selectedSupplierId;
  String? _selectedShippingCompanyId;
  List<ImportItem> _items = [];
  List<FCLCostDetail> _fclCostDetails = [];
  bool _isLoading = false;
  bool get _isEdit => widget.import_ != null || widget.importId != null;

  final _currencyFormat = NumberFormat('#,##0.00');

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  @override
  void dispose() {
    _importDateController.dispose();
    _usdToThbRateController.dispose();
    _pricePerCBMController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _initializeForm() async {
    await _loadData();
    if (mounted) setState(() {});

    if (widget.import_ != null) {
      _populateFields(widget.import_!);
    } else if (widget.importId != null) {
      _loadFromId();
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    await Future.wait([
      context.read<SupplierProvider>().loadSuppliersIfNeeded(),
      context.read<ProductProvider>().loadProducts(),
      context.read<ShippingCompanyProvider>().loadIfNeeded(),
    ]);
  }

  void _loadFromId() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<InternationalImportProvider>();
      var imp = provider.getById(widget.importId!);
      imp ??= await provider.fetchById(widget.importId!);
      if (imp != null && mounted) {
        _populateFields(imp);
      }
    });
  }

  void _populateFields(InternationalImport imp) {
    setState(() {
      _importDateController.text = DateFormat('dd/MM/yyyy').format(imp.importDate);
      _importType = imp.importType;
      _selectedSupplierId = imp.supplierId;
      _selectedShippingCompanyId = imp.shippingCompanyId;
      _usdToThbRateController.text = imp.usdToThbRate.toString();
      _pricePerCBMController.text = imp.pricePerCBM.toString();
      _fclCostDetails = List.from(imp.fclCostDetails);
      _items = List.from(imp.items);
      _notesController.text = imp.notes ?? '';
    });
  }

  DateTime _parseDate(String text) {
    try {
      return DateFormat('dd/MM/yyyy').parse(text);
    } catch (_) {
      return DateTime.now();
    }
  }

  // --- CBM & cost calculations (client-side preview) ---

  double _calcItemCBM(ImportItem item) {
    int ppb = item.piecesPerBox > 0 ? item.piecesPerBox : 1;
    double numBoxes = (item.quantity / ppb).ceilToDouble();
    double raw = numBoxes * item.boxWidth * item.boxLength * item.boxHeight / 1000000;
    return (raw * 10).ceilToDouble() / 10;
  }

  double get _totalCBM => _items.fold(0.0, (s, i) => s + _calcItemCBM(i));

  double get _totalFCLCost => _fclCostDetails.fold(0.0, (s, d) => s + d.amount);

  double _shippingPerUnit(ImportItem item) {
    double cbm = _calcItemCBM(item);
    double pricePerCBM = double.tryParse(_pricePerCBMController.text) ?? 0;
    if (_importType == 'LCL') {
      return item.quantity > 0 ? (cbm * pricePerCBM) / item.quantity : 0;
    } else {
      double total = _totalCBM;
      return (total > 0 && item.quantity > 0)
          ? (cbm / total) * _totalFCLCost / item.quantity
          : 0;
    }
  }

  double _costBeforeVAT(ImportItem item) {
    double rate = double.tryParse(_usdToThbRateController.text) ?? 0;
    return item.usdPricePerUnit * rate + _shippingPerUnit(item) + item.commission;
  }

  double _costAfterVAT(ImportItem item) => _costBeforeVAT(item) * 1.07;

  // --- Build ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ResponsiveAppBar(title: _isEdit ? 'แก้ไขรายการนำเข้า' : 'สร้างรายการนำเข้า'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildBasicInfoCard(),
                        const SizedBox(height: 16),
                        _buildShippingCostCard(),
                        const SizedBox(height: 16),
                        _buildItemsCard(),
                        const SizedBox(height: 16),
                        _buildSummaryCard(),
                        const SizedBox(height: 16),
                        _buildNotesCard(),
                        const SizedBox(height: 24),
                        _buildActionButtons(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  // ----- Section 1: Basic Info -----

  Widget _buildBasicInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ข้อมูลหลัก', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            // Date
            TextFormField(
              controller: _importDateController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'วันที่นำเข้า *',
                prefixIcon: Icon(Icons.calendar_today),
              ),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _importDateController.text.isNotEmpty
                      ? _parseDate(_importDateController.text)
                      : DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  _importDateController.text = DateFormat('dd/MM/yyyy').format(picked);
                }
              },
              validator: (v) => (v == null || v.isEmpty) ? 'กรุณาเลือกวันที่' : null,
            ),
            const SizedBox(height: 16),
            // Import type
            const Text('ประเภทการนำเข้า *', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'LCL', label: Text('LCL (แชร์ตู้)')),
                ButtonSegment(value: 'FCL', label: Text('FCL (เต็มตู้)')),
              ],
              selected: {_importType},
              onSelectionChanged: (v) => setState(() => _importType = v.first),
            ),
            const SizedBox(height: 16),
            // Supplier dropdown
            SupplierDropdown(
              selectedSupplierId: _selectedSupplierId,
              onChanged: (value) => setState(() => _selectedSupplierId = value),
              label: 'Supplier *',
              hint: 'เลือก Supplier',
            ),
            const SizedBox(height: 16),
            // Shipping dropdown with add button
            Consumer<ShippingCompanyProvider>(
              builder: (context, shippingProvider, _) {
                final companies = shippingProvider.companies;
                ShippingCompany? selected;
                try {
                  selected = companies.firstWhere((c) => c.id == _selectedShippingCompanyId);
                } catch (_) {
                  selected = null;
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: SearchableDropdown<ShippingCompany>(
                        label: 'Shipping Company *',
                        hint: 'เลือก Shipping Company',
                        value: selected,
                        items: companies,
                        itemAsString: (c) => c.name,
                        onChanged: (c) => setState(() => _selectedShippingCompanyId = c?.id),
                        validator: (c) => c == null ? 'กรุณาเลือก Shipping' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: IconButton.filled(
                        icon: const Icon(Icons.add),
                        tooltip: 'เพิ่ม Shipping Company',
                        onPressed: _addShippingCompany,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            // Exchange rate
            TextFormField(
              controller: _usdToThbRateController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'อัตราแลกเปลี่ยน USD/THB *',
                prefixIcon: Icon(Icons.currency_exchange),
              ),
              onChanged: (_) => setState(() {}),
              validator: (v) {
                if (v == null || v.isEmpty) return 'กรุณากรอกอัตราแลกเปลี่ยน';
                if (double.tryParse(v) == null || double.parse(v) <= 0) return 'กรุณากรอกตัวเลขที่ถูกต้อง';
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  // ----- Section 2: Shipping Cost -----

  Widget _buildShippingCostCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ราคาค่าส่ง', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (_importType == 'LCL') ...[
              TextFormField(
                controller: _pricePerCBMController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'ราคาต่อคิว (THB/CBM) *',
                  prefixIcon: Icon(Icons.local_shipping),
                ),
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  if (_importType != 'LCL') return null;
                  if (v == null || v.isEmpty) return 'กรุณากรอกราคาต่อคิว';
                  if (double.tryParse(v) == null) return 'กรุณากรอกตัวเลขที่ถูกต้อง';
                  return null;
                },
              ),
            ] else ...[
              // FCL cost details
              ..._fclCostDetails.asMap().entries.map((entry) {
                final idx = entry.key;
                final detail = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(detail.name, style: const TextStyle(fontSize: 14)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '${_currencyFormat.format(detail.amount)} บาท',
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        onPressed: () => _editFCLCostDetail(idx),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                        onPressed: () => setState(() => _fclCostDetails.removeAt(idx)),
                      ),
                    ],
                  ),
                );
              }),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'รวมค่าตู้: ${_currencyFormat.format(_totalFCLCost)} บาท',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('เพิ่มรายการ'),
                    onPressed: _addFCLCostDetail,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ----- Section 3: Items -----

  Widget _buildItemsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('รายการสินค้า', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('เพิ่มสินค้า'),
                  onPressed: _addItem,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: Text('ยังไม่มีรายการสินค้า', style: TextStyle(color: Colors.grey))),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 12,
                  columns: const [
                    DataColumn(label: Text('#')),
                    DataColumn(label: Text('สินค้า')),
                    DataColumn(label: Text('USD/ชิ้น'), numeric: true),
                    DataColumn(label: Text('จำนวน'), numeric: true),
                    DataColumn(label: Text('ชิ้น/ลัง'), numeric: true),
                    DataColumn(label: Text('กล่อง (กxยxส cm)')),
                    DataColumn(label: Text('CBM'), numeric: true),
                    DataColumn(label: Text('ค่าส่ง/ชิ้น'), numeric: true),
                    DataColumn(label: Text('Commission'), numeric: true),
                    DataColumn(label: Text('จ่าย Comm.')),
                    DataColumn(label: Text('ต้นทุน/ชิ้น\n(ก่อน VAT)'), numeric: true),
                    DataColumn(label: Text('ต้นทุน/ชิ้น\n(หลัง VAT)'), numeric: true),
                    DataColumn(label: Text('')),
                  ],
                  rows: _items.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final item = entry.value;
                    final cbm = _calcItemCBM(item);
                    final shipPU = _shippingPerUnit(item);
                    final costBV = _costBeforeVAT(item);
                    final costAV = _costAfterVAT(item);
                    return DataRow(cells: [
                      DataCell(Text('${idx + 1}')),
                      DataCell(Text('${item.productCode}\n${item.productName}', style: const TextStyle(fontSize: 12))),
                      DataCell(Text(_currencyFormat.format(item.usdPricePerUnit))),
                      DataCell(Text('${item.quantity}')),
                      DataCell(Text('${item.piecesPerBox}')),
                      DataCell(Text('${item.boxWidth}x${item.boxLength}x${item.boxHeight}')),
                      DataCell(Text(cbm.toStringAsFixed(1))),
                      DataCell(Text(_currencyFormat.format(shipPU))),
                      DataCell(Text(_currencyFormat.format(item.commission))),
                      DataCell(Checkbox(
                        value: item.commissionPaid,
                        onChanged: (v) => setState(() {
                          _items[idx] = item.copyWith(commissionPaid: v ?? false);
                        }),
                      )),
                      DataCell(Text(_currencyFormat.format(costBV))),
                      DataCell(Text(_currencyFormat.format(costAV))),
                      DataCell(Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () => _editItem(idx)),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                            onPressed: () => setState(() => _items.removeAt(idx)),
                          ),
                        ],
                      )),
                    ]);
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ----- Section 4: Summary -----

  Widget _buildSummaryCard() {
    double rate = double.tryParse(_usdToThbRateController.text) ?? 0;
    double totalCBM = _totalCBM;
    double totalProductCost = _items.fold(0.0, (s, i) => s + i.usdPricePerUnit * rate * i.quantity);
    double totalShipping = _items.fold(0.0, (s, i) => s + _shippingPerUnit(i) * i.quantity);
    double totalCommission = _items.fold(0.0, (s, i) => s + i.commission * i.quantity);
    double totalBeforeVAT = _items.fold(0.0, (s, i) => s + _costBeforeVAT(i) * i.quantity);
    double totalVAT = totalBeforeVAT * 0.07;
    double grandTotal = totalBeforeVAT + totalVAT;

    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('สรุป', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _summaryRow('รวม CBM', '${totalCBM.toStringAsFixed(1)} คิว'),
            _summaryRow('รวมต้นทุนสินค้า', '${_currencyFormat.format(totalProductCost)} บาท'),
            _summaryRow('รวมค่าส่ง', '${_currencyFormat.format(totalShipping)} บาท'),
            _summaryRow('รวมค่าคอมมิชชั่น', '${_currencyFormat.format(totalCommission)} บาท'),
            const Divider(),
            _summaryRow('รวมก่อน VAT', '${_currencyFormat.format(totalBeforeVAT)} บาท'),
            _summaryRow('VAT 7%', '${_currencyFormat.format(totalVAT)} บาท'),
            _summaryRow('รวมทั้งหมด', '${_currencyFormat.format(grandTotal)} บาท',
                isBold: true, fontSize: 18),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isBold = false, double fontSize = 14}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : null, fontSize: fontSize)),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.w500, fontSize: fontSize)),
        ],
      ),
    );
  }

  // ----- Notes -----

  Widget _buildNotesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TextFormField(
          controller: _notesController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'หมายเหตุ',
            border: OutlineInputBorder(),
          ),
        ),
      ),
    );
  }

  // ----- Actions -----

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => context.pop(),
            child: const Text('ยกเลิก'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _save,
            child: Text(_isEdit ? 'บันทึก' : 'สร้างรายการนำเข้า'),
          ),
        ),
      ],
    );
  }

  // ----- Dialogs -----

  void _addShippingCompany() {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('เพิ่ม Shipping Company'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'ชื่อบริษัท'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              final provider = context.read<ShippingCompanyProvider>();
              final company = await provider.create(ShippingCompanyRequest(name: name));
              if (company != null && mounted) {
                setState(() => _selectedShippingCompanyId = company.id);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );
  }

  void _addFCLCostDetail() {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('เพิ่มรายการค่าใช้จ่าย'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'รายการ (เช่น ค่าเคลียแลนซ์)')),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'จำนวนเงิน (บาท)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              final amount = double.tryParse(amountCtrl.text) ?? 0;
              if (name.isEmpty) return;
              setState(() => _fclCostDetails.add(FCLCostDetail(name: name, amount: amount)));
              Navigator.pop(ctx);
            },
            child: const Text('เพิ่ม'),
          ),
        ],
      ),
    );
  }

  void _editFCLCostDetail(int index) {
    final detail = _fclCostDetails[index];
    final nameCtrl = TextEditingController(text: detail.name);
    final amountCtrl = TextEditingController(text: detail.amount.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('แก้ไขรายการค่าใช้จ่าย'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'รายการ')),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'จำนวนเงิน (บาท)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _fclCostDetails[index] = FCLCostDetail(
                  name: nameCtrl.text.trim(),
                  amount: double.tryParse(amountCtrl.text) ?? 0,
                );
              });
              Navigator.pop(ctx);
            },
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );
  }

  void _addItem() {
    _showItemDialog(null, null);
  }

  void _editItem(int index) {
    _showItemDialog(_items[index], index);
  }

  void _showItemDialog(ImportItem? existing, int? index) {
    showDialog(
      context: context,
      builder: (ctx) => _AddItemDialog(
        existing: existing,
        onSave: (item) {
          setState(() {
            if (index != null) {
              _items[index] = item;
            } else {
              _items.add(item);
            }
          });
        },
      ),
    );
  }

  // ----- Save -----

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSupplierId == null) {
      ErrorDialog.showValidationError(context, 'กรุณาเลือก Supplier');
      return;
    }
    if (_selectedShippingCompanyId == null) {
      ErrorDialog.showValidationError(context, 'กรุณาเลือก Shipping Company');
      return;
    }
    if (_items.isEmpty) {
      ErrorDialog.showValidationError(context, 'กรุณาเพิ่มสินค้าอย่างน้อย 1 รายการ');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final request = InternationalImportRequest(
        importDate: _parseDate(_importDateController.text),
        importType: _importType,
        supplierId: _selectedSupplierId!,
        shippingCompanyId: _selectedShippingCompanyId!,
        usdToThbRate: double.tryParse(_usdToThbRateController.text) ?? 0,
        pricePerCBM: double.tryParse(_pricePerCBMController.text) ?? 0,
        fclCostDetails: _importType == 'FCL' ? _fclCostDetails : [],
        items: _items,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      final provider = context.read<InternationalImportProvider>();
      if (_isEdit) {
        final id = widget.import_?.id ?? widget.importId!;
        final success = await provider.update(id, request);
        if (success && mounted) {
          await provider.fetchById(id);
          context.go('/international/$id');
        } else if (mounted) {
          ErrorDialog.showServerError(context, provider.error);
        }
      } else {
        final result = await provider.create(request);
        if (result != null && mounted) {
          context.go('/international/${result.id}');
        } else if (mounted) {
          ErrorDialog.showServerError(context, provider.error);
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

// ----- Add/Edit Item Dialog -----

class _AddItemDialog extends StatefulWidget {
  final ImportItem? existing;
  final void Function(ImportItem) onSave;

  const _AddItemDialog({this.existing, required this.onSave});

  @override
  State<_AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<_AddItemDialog> {
  final _formKey = GlobalKey<FormState>();
  Product? _selectedProduct;
  final _usdPriceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _widthController = TextEditingController();
  final _lengthController = TextEditingController();
  final _heightController = TextEditingController();
  final _piecesPerBoxController = TextEditingController(text: '1');
  final _commissionController = TextEditingController();
  bool _commissionPaid = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final e = widget.existing!;
      _usdPriceController.text = e.usdPricePerUnit.toString();
      _quantityController.text = e.quantity.toString();
      _piecesPerBoxController.text = e.piecesPerBox.toString();
      _widthController.text = e.boxWidth.toString();
      _lengthController.text = e.boxLength.toString();
      _heightController.text = e.boxHeight.toString();
      _commissionController.text = e.commission.toString();
      _commissionPaid = e.commissionPaid;
    }
  }

  @override
  void dispose() {
    _usdPriceController.dispose();
    _quantityController.dispose();
    _piecesPerBoxController.dispose();
    _widthController.dispose();
    _lengthController.dispose();
    _heightController.dispose();
    _commissionController.dispose();
    super.dispose();
  }

  double get _cbmPreview {
    double w = double.tryParse(_widthController.text) ?? 0;
    double l = double.tryParse(_lengthController.text) ?? 0;
    double h = double.tryParse(_heightController.text) ?? 0;
    int qty = int.tryParse(_quantityController.text) ?? 0;
    int ppb = int.tryParse(_piecesPerBoxController.text) ?? 1;
    if (ppb <= 0) ppb = 1;
    double numBoxes = (qty / ppb).ceilToDouble();
    double raw = numBoxes * w * l * h / 1000000;
    return (raw * 10).ceilToDouble() / 10;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing != null ? 'แก้ไขสินค้า' : 'เพิ่มสินค้า'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Product selection
                if (widget.existing == null)
                  Consumer<ProductProvider>(
                    builder: (context, productProvider, _) {
                      return ProductSearchDropdown(
                        label: 'สินค้า *',
                        hint: 'เลือกสินค้า',
                        selectedProduct: _selectedProduct,
                        products: productProvider.allProducts,
                        itemAsString: (p) => '${p.code} - ${p.name}',
                        onChanged: (p) => setState(() => _selectedProduct = p),
                      );
                    },
                  )
                else
                  Text('${widget.existing!.productCode} - ${widget.existing!.productName}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _usdPriceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'ราคา USD/ชิ้น *'),
                  validator: (v) => (v == null || v.isEmpty || double.tryParse(v) == null) ? 'กรุณากรอกราคา' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'จำนวน (ชิ้น) *'),
                  onChanged: (_) => setState(() {}),
                  validator: (v) => (v == null || v.isEmpty || int.tryParse(v) == null || int.parse(v) <= 0)
                      ? 'กรุณากรอกจำนวน'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _piecesPerBoxController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'จำนวนชิ้นต่อลัง *'),
                  onChanged: (_) => setState(() {}),
                  validator: (v) => (v == null || v.isEmpty || int.tryParse(v) == null || int.parse(v) <= 0)
                      ? 'กรุณากรอกจำนวนชิ้นต่อลัง'
                      : null,
                ),
                const SizedBox(height: 12),
                const Align(alignment: Alignment.centerLeft, child: Text('ขนาดกล่อง (cm)', style: TextStyle(fontWeight: FontWeight.w500))),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _widthController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'กว้าง'),
                        onChanged: (_) => setState(() {}),
                        validator: (v) => (v == null || v.isEmpty) ? 'กรอก' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _lengthController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'ยาว'),
                        onChanged: (_) => setState(() {}),
                        validator: (v) => (v == null || v.isEmpty) ? 'กรอก' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _heightController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'สูง'),
                        onChanged: (_) => setState(() {}),
                        validator: (v) => (v == null || v.isEmpty) ? 'กรอก' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('CBM (ปัดขึ้น): ${_cbmPreview.toStringAsFixed(1)}',
                      style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.w500)),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _commissionController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'ค่าคอมมิชชั่น (บาท/ชิ้น)'),
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  title: const Text('จ่ายค่าคอมมิชชั่นแล้ว'),
                  value: _commissionPaid,
                  onChanged: (v) => setState(() => _commissionPaid = v ?? false),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('ยกเลิก')),
        ElevatedButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            if (widget.existing == null && _selectedProduct == null) return;

            final product = _selectedProduct;
            final item = ImportItem(
              productId: product?.id ?? widget.existing!.productId,
              productName: product?.name ?? widget.existing!.productName,
              productCode: product?.code ?? widget.existing!.productCode,
              usdPricePerUnit: double.parse(_usdPriceController.text),
              quantity: int.parse(_quantityController.text),
              piecesPerBox: int.tryParse(_piecesPerBoxController.text) ?? 1,
              boxWidth: double.tryParse(_widthController.text) ?? 0,
              boxLength: double.tryParse(_lengthController.text) ?? 0,
              boxHeight: double.tryParse(_heightController.text) ?? 0,
              cbm: _cbmPreview,
              shippingCostPerUnit: 0,
              commission: double.tryParse(_commissionController.text) ?? 0,
              commissionPaid: _commissionPaid,
              costPerUnitBeforeVAT: 0,
              vatPerUnit: 0,
              costPerUnitAfterVAT: 0,
              totalCost: 0,
            );

            widget.onSave(item);
            Navigator.pop(context);
          },
          child: Text(widget.existing != null ? 'บันทึก' : 'เพิ่ม'),
        ),
      ],
    );
  }
}
