import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/deposit.dart';
import '../services/deposit_api_service.dart';

/// ส่วนเลือกหักเงินมัดจำในรายการขาย/รายการซื้อ
///
/// แสดงเงินมัดจำที่ยังมียอดคงเหลือของลูกค้า/ซัพพลายเออร์ที่เลือก ให้ติ๊กเลือกได้หลายก้อน
/// และระบุยอดที่จะหักจากแต่ละก้อน (หักบางส่วนได้ ส่วนที่เหลือใช้กับรายการอื่นต่อได้)
///
/// - มัดจำ VAT (ออกใบกำกับภาษีแล้ว): ยอดเป็นก่อน VAT หักก่อนคิด VAT ใช้ได้เฉพาะรายการ VAT
/// - มัดจำไม่มี VAT: หักออกจากยอดรวมหลัง VAT
///
/// ใช้ [Key] ที่ผูกกับ partyId และ [allowVATDeposits] เพื่อให้ widget สร้างใหม่เมื่อเปลี่ยน
/// [initialApplications] ใช้ตอนสร้าง widget เท่านั้น
class DepositApplicationSection extends StatefulWidget {
  final String depositType; // Deposit.typeCustomer หรือ Deposit.typeSupplier
  final String? partyId;
  final String? currentDocId; // id ของรายการขาย/ซื้อที่กำลังแก้ไข (ไม่นับยอดที่หักไว้เดิม)
  final List<DepositApplication> initialApplications;
  final bool allowVATDeposits; // รายการเป็น VAT นอก/VAT ใน จึงใช้มัดจำ VAT ได้
  final double itemsBeforeVAT; // ยอดสินค้าก่อน VAT (เพดานหักมัดจำ VAT)
  final double totalAfterVAT; // ยอดรวมหลัง VAT หลังหักมัดจำ VAT แล้ว (เพดานหักมัดจำไม่มี VAT)
  final ValueChanged<List<DepositApplication>> onChanged;

  const DepositApplicationSection({
    super.key,
    required this.depositType,
    required this.partyId,
    this.currentDocId,
    this.initialApplications = const [],
    required this.allowVATDeposits,
    required this.itemsBeforeVAT,
    required this.totalAfterVAT,
    required this.onChanged,
  });

  @override
  State<DepositApplicationSection> createState() => _DepositApplicationSectionState();
}

class _DepositApplicationSectionState extends State<DepositApplicationSection> {
  final _currency = NumberFormat('#,##0.00', 'th');
  final _dateFormat = DateFormat('dd/MM/yyyy');

  List<Deposit> _deposits = [];
  int _hiddenVATDeposits = 0; // มัดจำ VAT ที่ใช้ไม่ได้เพราะรายการไม่ใช่ VAT
  final Set<String> _selected = {};
  final Map<String, TextEditingController> _controllers = {};
  bool _isLoading = false;
  String? _error;

  String get _partyLabel => Deposit.partyLabel(widget.depositType);

  @override
  void initState() {
    super.initState();
    for (final app in widget.initialApplications) {
      if (app.beforeVAT && !widget.allowVATDeposits) continue;
      _selected.add(app.depositId);
      _controllerFor(app.depositId).text = _formatInput(app.amount);
    }
    if (_selected.length != widget.initialApplications.length) {
      // บางรายการใช้ไม่ได้แล้ว (เช่น เปลี่ยนเป็น Non-VAT) แจ้งรายการที่เหลือกลับไป
      final kept = widget.initialApplications.where((a) => _selected.contains(a.depositId)).toList();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onChanged(kept);
      });
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
        final usable = all.where((d) => !d.isFullyUsed || _selected.contains(d.id)).toList();
        _hiddenVATDeposits = widget.allowVATDeposits ? 0 : usable.where((d) => d.isVAT).length;
        _deposits = usable
            .where((d) => widget.allowVATDeposits || !d.isVAT)
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

  Deposit? _depositById(String id) {
    for (final d in _deposits) {
      if (d.id == id) return d;
    }
    return null;
  }

  /// ยอดที่เลือกหัก แยกตามมัดจำ VAT (หักก่อน VAT) หรือไม่มี VAT (หักหลัง VAT)
  double _selectedTotal({required bool vat, String? except}) {
    var total = 0.0;
    for (final id in _selected) {
      if (id == except) continue;
      final d = _depositById(id);
      if (d == null || d.isVAT != vat) continue;
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
        apps.add(DepositApplication(
            depositId: d.id, depositCode: d.depositCode, amount: amount, beforeVAT: d.isVAT));
      }
    }
    widget.onChanged(apps);
  }

  void _toggle(Deposit d, bool checked) {
    setState(() {
      if (checked) {
        _selected.add(d.id);
        // แนะนำยอดหัก = ยอดที่ยังหักได้ (ไม่เกินยอดคงเหลือของมัดจำก้อนนี้)
        final stillDue = d.isVAT
            ? widget.itemsBeforeVAT - _selectedTotal(vat: true, except: d.id)
            : widget.totalAfterVAT - _selectedTotal(vat: false, except: d.id);
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
    final hiddenNote = _hiddenVATDeposits > 0
        ? _hint('มีมัดจำแบบ VAT $_hiddenVATDeposits รายการ ใช้หักได้เฉพาะรายการที่เป็น VAT')
        : null;
    if (_deposits.isEmpty) {
      return [
        _hint('$_partyLabelนี้ไม่มีเงินมัดจำคงเหลือ'),
        if (hiddenNote != null) ...[const SizedBox(height: 4), hiddenNote],
      ];
    }

    final vatTotal = _selectedTotal(vat: true);
    final nonVatTotal = _selectedTotal(vat: false);
    Widget totalRow(String label, double value) => Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))),
              Text('฿${_currency.format(value)}',
                  style: TextStyle(fontWeight: FontWeight.bold, color: color.shade700)),
            ],
          ),
        );
    Widget warn(String text) => Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(text, style: TextStyle(color: Colors.orange.shade800, fontSize: 12)),
        );

    return [
      _hint('เลือกมัดจำที่จะหักในรายการนี้ หักบางส่วนได้ ยอดที่เหลือใช้กับรายการอื่นต่อได้\n'
          'มัดจำ VAT (ออกใบกำกับภาษีแล้ว) หักก่อนคิด VAT · มัดจำไม่มี VAT หักจากยอดรวมหลัง VAT'),
      if (hiddenNote != null) ...[const SizedBox(height: 4), hiddenNote],
      const SizedBox(height: 8),
      ..._deposits.map((d) => _buildDepositRow(d, color)),
      if (_selected.isNotEmpty) ...[
        const Divider(height: 24),
        if (vatTotal > 0) totalRow('หักมัดจำก่อน VAT', vatTotal),
        if (nonVatTotal > 0) totalRow('หักมัดจำหลัง VAT', nonVatTotal),
        if (vatTotal > widget.itemsBeforeVAT + 0.005)
          warn('ยอดหักมัดจำก่อน VAT เกินยอดสินค้าก่อน VAT (฿${_currency.format(widget.itemsBeforeVAT)})'),
        if (widget.totalAfterVAT > 0 && nonVatTotal > widget.totalAfterVAT + 0.005)
          warn('ยอดหักมัดจำเกินยอดรวมของรายการ (฿${_currency.format(widget.totalAfterVAT)})'),
      ],
    ];
  }

  Widget _badge(String text, MaterialColor color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(
          color: color.shade50,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.shade200),
        ),
        child: Text(text, style: TextStyle(fontSize: 10, color: color.shade800)),
      );

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
            title: Wrap(
              spacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(d.depositCode, style: const TextStyle(fontWeight: FontWeight.w600)),
                _badge(d.isVAT ? 'VAT · หักก่อน VAT' : 'ไม่มี VAT', d.isVAT ? Colors.green : Colors.grey),
              ],
            ),
            subtitle: Text(details, maxLines: 2, overflow: TextOverflow.ellipsis),
            secondary: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('คงเหลือ ฿${_currency.format(d.remainingAmount)}',
                    style: TextStyle(fontWeight: FontWeight.bold, color: color.shade700)),
                Text('จาก ฿${_currency.format(d.deductibleAmount)}${d.balanceUnitLabel}',
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
                  labelText: 'ยอดที่หักจาก ${d.depositCode}${d.balanceUnitLabel}',
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
