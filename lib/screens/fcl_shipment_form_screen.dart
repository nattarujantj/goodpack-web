import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/fcl_shipment.dart';
import '../models/shipping_company.dart';
import '../providers/fcl_shipment_provider.dart';
import '../providers/shipping_company_provider.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/searchable_dropdown.dart';
import '../utils/error_dialog.dart';

class FclShipmentFormScreen extends StatefulWidget {
  final String? shipmentId;
  const FclShipmentFormScreen({Key? key, this.shipmentId}) : super(key: key);

  @override
  State<FclShipmentFormScreen> createState() => _FclShipmentFormScreenState();
}

class _FclShipmentFormScreenState extends State<FclShipmentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _usdRateController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedShippingCompanyId;
  List<FclCostLine> _costLines = [];
  bool _isLoading = false;
  bool get _isEdit => widget.shipmentId != null;

  final _currencyFormat = NumberFormat('#,##0.00');

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<ShippingCompanyProvider>().loadIfNeeded();
      if (_isEdit) _loadExisting();
    });
  }

  @override
  void dispose() {
    _dateController.dispose();
    _usdRateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _loadExisting() async {
    final provider = context.read<FclShipmentProvider>();
    var s = provider.getById(widget.shipmentId!);
    s ??= await provider.fetchById(widget.shipmentId!);
    if (s != null && mounted) {
      setState(() {
        _dateController.text = DateFormat('dd/MM/yyyy').format(s!.shipmentDate);
        _selectedShippingCompanyId = s.shippingCompanyId;
        _usdRateController.text = s.usdToThbRate == 0 ? '' : s.usdToThbRate.toString();
        _costLines = List.from(s.costLines);
        _notesController.text = s.notes ?? '';
      });
    }
  }

  double get _defaultRate => double.tryParse(_usdRateController.text) ?? 0;
  double get _totalCostThb =>
      _costLines.fold(0.0, (s, l) => s + l.computeThb(_defaultRate));

  DateTime _parseDate(String text) {
    try {
      return DateFormat('dd/MM/yyyy').parse(text);
    } catch (_) {
      return DateTime.now();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ResponsiveAppBar(title: _isEdit ? 'แก้ไขตู้ FCL' : 'สร้างตู้ FCL'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 820),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildInfoCard(),
                        const SizedBox(height: 16),
                        _buildCostCard(),
                        const SizedBox(height: 16),
                        _buildNotesCard(),
                        const SizedBox(height: 24),
                        Row(
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
                                child: Text(_isEdit ? 'บันทึก' : 'สร้างตู้'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ข้อมูลตู้', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _dateController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'วันที่ *',
                prefixIcon: Icon(Icons.calendar_today),
              ),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _parseDate(_dateController.text),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  _dateController.text = DateFormat('dd/MM/yyyy').format(picked);
                }
              },
              validator: (v) => (v == null || v.isEmpty) ? 'กรุณาเลือกวันที่' : null,
            ),
            const SizedBox(height: 16),
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
            TextFormField(
              controller: _usdRateController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'เรทกลาง USD/THB (ใช้กับรายการที่เป็น USD)',
                prefixIcon: Icon(Icons.currency_exchange),
                helperText: 'ถ้ารายการ USD ไม่ได้ใส่เรทเอง จะใช้เรทนี้',
              ),
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCostCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('ค่าตู้ (เหมาทั้งตู้)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('เพิ่มรายการ'),
                  onPressed: () => _editCostLine(null),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_costLines.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text('ยังไม่มีรายการค่าตู้', style: TextStyle(color: Colors.grey))),
              )
            else
              ..._costLines.asMap().entries.map((entry) {
                final idx = entry.key;
                final line = entry.value;
                final thb = line.computeThb(_defaultRate);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(line.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                            if (line.currency == 'USD')
                              Text(
                                '\$${_currencyFormat.format(line.amount)} × ${line.usdRate > 0 ? line.usdRate : _defaultRate}',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '${_currencyFormat.format(thb)} ฿',
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        onPressed: () => _editCostLine(idx),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                        onPressed: () => setState(() => _costLines.removeAt(idx)),
                      ),
                    ],
                  ),
                );
              }),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'ค่าตู้รวม: ${_currencyFormat.format(_totalCostThb)} บาท',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

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

  void _editCostLine(int? index) {
    final existing = index != null ? _costLines[index] : null;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final amountCtrl = TextEditingController(
        text: existing != null ? existing.amount.toString() : '');
    final rateCtrl = TextEditingController(
        text: (existing != null && existing.usdRate > 0) ? existing.usdRate.toString() : '');
    String currency = existing?.currency ?? 'THB';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(index == null ? 'เพิ่มรายการค่าตู้' : 'แก้ไขรายการค่าตู้'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'รายการ (เช่น ค่าระวางเรือ, THC)'),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'THB', label: Text('฿ THB')),
                  ButtonSegment(value: 'USD', label: Text('\$ USD')),
                ],
                selected: {currency},
                onSelectionChanged: (v) => setDialogState(() => currency = v.first),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: currency == 'USD' ? 'จำนวน (USD)' : 'จำนวน (บาท)',
                ),
              ),
              if (currency == 'USD') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: rateCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'เรท USD/THB (เว้นว่าง = ใช้เรทกลาง ${_defaultRate > 0 ? _defaultRate : "-"})',
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
            ElevatedButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                final line = FclCostLine(
                  name: name,
                  currency: currency,
                  amount: double.tryParse(amountCtrl.text) ?? 0,
                  usdRate: currency == 'USD' ? (double.tryParse(rateCtrl.text) ?? 0) : 0,
                );
                setState(() {
                  if (index == null) {
                    _costLines.add(line);
                  } else {
                    _costLines[index] = line;
                  }
                });
                Navigator.pop(ctx);
              },
              child: Text(index == null ? 'เพิ่ม' : 'บันทึก'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedShippingCompanyId == null) {
      ErrorDialog.showValidationError(context, 'กรุณาเลือก Shipping Company');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final request = FclShipmentRequest(
        shipmentDate: _parseDate(_dateController.text),
        shippingCompanyId: _selectedShippingCompanyId!,
        usdToThbRate: _defaultRate,
        costLines: _costLines,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      final provider = context.read<FclShipmentProvider>();
      if (_isEdit) {
        final ok = await provider.update(widget.shipmentId!, request);
        if (ok && mounted) {
          context.go('/fcl-shipment/${widget.shipmentId}');
        } else if (mounted) {
          ErrorDialog.showServerError(context, provider.error);
        }
      } else {
        final created = await provider.create(request);
        if (created != null && mounted) {
          context.go('/fcl-shipment/${created.id}');
        } else if (mounted) {
          ErrorDialog.showServerError(context, provider.error);
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
