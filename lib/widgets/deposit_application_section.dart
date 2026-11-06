import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/deposit.dart';
import '../services/deposit_api_service.dart';

/// ส่วนเลือกหักเงินมัดจำในรายการขาย/รายการซื้อ
///
/// แสดงเงินมัดจำที่ยังมียอดคงเหลือของลูกค้า/ซัพพลายเออร์ที่เลือก ให้ติ๊กเลือกได้หลายก้อน
/// และระบุยอดที่จะหักจากแต่ละก้อน (หักบางส่วนได้ ส่วนที่เหลือใช้กับรายการอื่นต่อได้)
///
/// ใช้ [Key] ที่ผูกกับ partyId เพื่อให้ widget สร้างใหม่เมื่อเปลี่ยนคู่ค้า
/// [initialApplications] ใช้ตอนสร้าง widget เท่านั้น
class DepositApplicationSection extends StatefulWidget {
  final String depositType; // Deposit.typeCustomer หรือ Deposit.typeSupplier
  final String? partyId;
  final String? currentDocId; // id ของรายการขาย/ซื้อที่กำลังแก้ไข (ไม่นับยอดที่หักไว้เดิม)
  final List<DepositApplication> initialApplications;
  final double amountDue; // ยอดที่ต้องชำระก่อนหักมัดจำ (ใช้แนะนำยอดหัก/เตือนหักเกิน)
  final ValueChanged<List<DepositApplication>> onChanged;

  const DepositApplicationSection({
    super.key,
    required this.depositType,
    required this.partyId,
    this.currentDocId,
    this.initialApplications = const [],
    required this.amountDue,
    required this.onChanged,
  });

  @override
  State<DepositApplicationSection> createState() => _DepositApplicationSectionState();
}

class _DepositApplicationSectionState extends State<DepositApplicationSection> {
  final _currency = NumberFormat('#,##0.00', 'th');
  final _dateFormat = DateFormat('dd/MM/yyyy');

  List<Deposit> _deposits = [];
  final Set<String> _selected = {};
  final Map<String, TextEditingController> _controllers = {};
  bool _isLoading = false;
  String? _error;

  String get _partyLabel => Deposit.partyLabel(widget.depositType);

  @override
  void initState() {
    super.initState();
    for (final app in widget.initialApplications) {
      _selected.add(app.depositId);
      _controllerFor(app.depositId).text = _formatInput(app.amount);
    }
    _load();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerFor(String id) =>
      _controllers.putIfAbsent(id, () => TextEditingController());

  String _formatInput(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  double _parse(String text) => double.tryParse(text.replaceAll(',', '').trim()) ?? 0.0;

  Future<void> _load() async {
    final partyId = widget.partyId;
    if (partyId == null || partyId.isEmpty) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final all = await DepositApiService.getDeposits(
        type: widget.depositType,
        partyId: partyId,
        excludeDocId: widget.currentDocId,
      );
      if (!mounted) return;
      setState(() {
        // แสดงเฉพาะมัดจำที่ยังมียอดเหลือ หรือที่รายการนี้หักไว้อยู่แล้ว
        _deposits = all
            .where((d) => !d.isFullyUsed || _selected.contains(d.id))
            .toList()
          ..sort((a, b) => a.depositDate.compareTo(b.depositDate));
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  double _selectedTotal({String? except}) {
    var total = 0.0;
    for (final id in _selected) {
      if (id == except) continue;
      total += _parse(_controllerFor(id).text);
    }
    return total;
  }

  void _notify() {
    final apps = <DepositApplication>[];
    for (final d in _deposits) {
      if (!_selected.contains(d.id)) continue;
      final amount = _parse(_controllerFor(d.id).text);
      if (amount > 0) {
        apps.add(DepositApplication(depositId: d.id, depositCode: d.depositCode, amount: amount));
      }
    }
    widget.onChanged(apps);
  }

  void _toggle(Deposit d, bool checked) {
    setState(() {
      if (checked) {
        _selected.add(d.id);
        // แนะนำยอดหัก = ยอดที่ยังต้องชำระ (ไม่เกินยอดคงเหลือของมัดจำก้อนนี้)
        final stillDue = widget.amountDue - _selectedTotal(except: d.id);
        var suggest = d.remainingAmount;
        if (stillDue > 0 && stillDue < suggest) suggest = stillDue;
        _controllerFor(d.id).text = _formatInput(double.parse(suggest.toStringAsFixed(2)));
      } else {
        _selected.remove(d.id);
        _controllerFor(d.id).clear();
      }
    });
    _notify();
  }

  @override
  Widget build(BuildContext context) {
    final isCustomer = widget.depositType == Deposit.typeCustomer;
    final color = isCustomer ? Colors.teal : Colors.indigo;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.savings_outlined, color: color.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isCustomer ? 'หักเงินมัดจำของลูกค้า' : 'หักเงินมัดจำที่วางไว้กับซัพพลายเออร์',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                if (widget.partyId != null && widget.partyId!.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    tooltip: 'โหลดใหม่',
                    onPressed: _isLoading ? null : _load,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            ..._buildBody(color),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBody(MaterialColor color) {
    if (widget.partyId == null || widget.partyId!.isEmpty) {
      return [_hint('เลือก$_partyLabelก่อน เพื่อดูเงินมัดจำที่ใช้หักได้')];
    }
    if (_isLoading) {
      return [const Padding(padding: EdgeInsets.all(8), child: LinearProgressIndicator())];
    }
    if (_error != null) {
      return [Text(_error!, style: const TextStyle(color: Colors.red))];
    }
    if (_deposits.isEmpty) {
      return [_hint('$_partyLabelนี้ไม่มีเงินมัดจำคงเหลือ')];
    }

    final total = _selectedTotal();
    return [
      _hint('เลือกมัดจำที่จะหักในรายการนี้ หักบางส่วนได้ ยอดที่เหลือใช้กับรายการอื่นต่อได้'),
      const SizedBox(height: 8),
      ..._deposits.map((d) => _buildDepositRow(d, color)),
      if (_selected.isNotEmpty) ...[
        const Divider(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('รวมหักมัดจำ', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('฿${_currency.format(total)}',
                style: TextStyle(fontWeight: FontWeight.bold, color: color.shade700)),
          ],
        ),
        if (widget.amountDue > 0 && total > widget.amountDue + 0.005)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'ยอดหักมัดจำเกินยอดรวมของรายการ (฿${_currency.format(widget.amountDue)})',
              style: TextStyle(color: Colors.orange.shade800, fontSize: 12),
            ),
          ),
      ],
    ];
  }

  Widget _hint(String text) =>
      Text(text, style: TextStyle(color: Colors.grey[600], fontSize: 13));

  Widget _buildDepositRow(Deposit d, MaterialColor color) {
    final checked = _selected.contains(d.id);
    final details = <String>[
      _dateFormat.format(d.depositDate),
      if (d.reference.isNotEmpty) 'อ้างอิง ${d.reference}',
      if (d.notes.isNotEmpty) d.notes,
    ].join(' · ');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(color: checked ? color.shade300 : Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: checked ? color.shade50 : null,
      ),
      child: Column(
        children: [
          CheckboxListTile(
            value: checked,
            onChanged: (v) => _toggle(d, v ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            dense: true,
            title: Text(d.depositCode, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(details, maxLines: 2, overflow: TextOverflow.ellipsis),
            secondary: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('คงเหลือ ฿${_currency.format(d.remainingAmount)}',
                    style: TextStyle(fontWeight: FontWeight.bold, color: color.shade700)),
                Text('จาก ฿${_currency.format(d.amount)}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              ],
            ),
          ),
          if (checked)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: TextFormField(
                controller: _controllerFor(d.id),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'ยอดที่หักจาก ${d.depositCode}',
                  prefixText: '฿ ',
                  isDense: true,
                  border: const OutlineInputBorder(),
                  suffixIcon: TextButton(
                    onPressed: () {
                      _controllerFor(d.id).text = _formatInput(d.remainingAmount);
                      setState(() {});
                      _notify();
                    },
                    child: const Text('หักทั้งหมด'),
                  ),
                ),
                onChanged: (_) {
                  setState(() {});
                  _notify();
                },
                validator: (value) {
                  final amount = _parse(value ?? '');
                  if (amount <= 0) return 'กรุณาระบุยอดที่หัก (หรือเอาเครื่องหมายเลือกออก)';
                  if (amount > d.remainingAmount + 0.005) {
                    return 'เกินยอดคงเหลือ ฿${_currency.format(d.remainingAmount)}';
                  }
                  return null;
                },
              ),
            ),
        ],
      ),
    );
  }
}
