import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/deposit.dart';
import '../providers/deposit_provider.dart';
import '../providers/customer_provider.dart';
import '../providers/supplier_provider.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/customer_dropdown.dart';
import '../widgets/supplier_dropdown.dart';
import '../widgets/account_dropdown.dart';
import '../utils/error_dialog.dart';

/// ฟอร์มบันทึก/แก้ไขเงินมัดจำ และดูประวัติการหักมัดจำในรายการขาย/ซื้อ
class DepositFormScreen extends StatefulWidget {
  final String? depositId;
  final String? initialType;

  const DepositFormScreen({Key? key, this.depositId, this.initialType}) : super(key: key);

  @override
  State<DepositFormScreen> createState() => _DepositFormScreenState();
}

class _DepositFormScreenState extends State<DepositFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();
  final _currency = NumberFormat('#,##0.00', 'th');
  final _dateFormat = DateFormat('dd/MM/yyyy');

  late String _type;
  String? _partyId;
  String? _ourAccount;
  DateTime _depositDate = DateTime.now();
  Deposit? _deposit;
  bool _isLoading = false;
  bool _isSaving = false;

  bool get _isEdit => widget.depositId != null;
  bool get _isCustomer => _type == Deposit.typeCustomer;
  bool get _isUsed => (_deposit?.usages.isNotEmpty ?? false);
  MaterialColor get _color => _isCustomer ? Colors.teal : Colors.indigo;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType == Deposit.typeSupplier ? Deposit.typeSupplier : Deposit.typeCustomer;
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  @override
  void dispose() {
    _codeController.dispose();
    _amountController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final customerProvider = context.read<CustomerProvider>();
    final supplierProvider = context.read<SupplierProvider>();
    if (customerProvider.allCustomers.isEmpty && !customerProvider.isLoading) {
      customerProvider.loadCustomers();
    }
    if (supplierProvider.allSuppliers.isEmpty && !supplierProvider.isLoading) {
      supplierProvider.loadSuppliers();
    }
    if (_isEdit) await _loadDeposit();
  }

  Future<void> _loadDeposit() async {
    setState(() => _isLoading = true);
    try {
      final d = await context.read<DepositProvider>().fetchById(widget.depositId!);
      if (!mounted) return;
      setState(() {
        _deposit = d;
        _type = d.type;
        _partyId = d.partyId;
        _ourAccount = d.ourAccount;
        _depositDate = d.depositDate;
        _codeController.text = d.depositCode;
        _amountController.text = d.amount == d.amount.roundToDouble()
            ? d.amount.toStringAsFixed(0)
            : d.amount.toStringAsFixed(2);
        _referenceController.text = d.reference;
        _notesController.text = d.notes;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ErrorDialog.showServerError(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _goBack() => context.go('/deposits?type=$_type');

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _depositDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _depositDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_partyId == null || _partyId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('กรุณาเลือก${Deposit.partyLabel(_type)}'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    final request = DepositRequest(
      depositCode: _codeController.text.trim().isEmpty ? null : _codeController.text.trim(),
      type: _type,
      partyId: _partyId!,
      amount: double.parse(_amountController.text.replaceAll(',', '').trim()),
      depositDate: DateTime(_depositDate.year, _depositDate.month, _depositDate.day),
      ourAccount: _ourAccount,
      reference: _referenceController.text.trim(),
      notes: _notesController.text.trim(),
    );

    setState(() => _isSaving = true);
    try {
      final provider = context.read<DepositProvider>();
      if (_isEdit) {
        await provider.update(widget.depositId!, request);
      } else {
        await provider.create(request);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isEdit ? 'อัปเดตเงินมัดจำเรียบร้อยแล้ว' : 'บันทึกเงินมัดจำเรียบร้อยแล้ว'),
        backgroundColor: Colors.green,
      ));
      _goBack();
    } catch (e) {
      if (mounted) ErrorDialog.showServerError(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ลบเงินมัดจำ'),
        content: Text('ต้องการลบ ${_deposit?.depositCode ?? ''} ใช่ไหม?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await context.read<DepositProvider>().delete(widget.depositId!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ลบเงินมัดจำแล้ว')));
      _goBack();
    } catch (e) {
      if (mounted) ErrorDialog.showServerError(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ResponsiveAppBar(
        title: _isEdit ? 'เงินมัดจำ ${_deposit?.depositCode ?? ''}' : 'บันทึกเงินมัดจำ',
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: _goBack),
        actions: [
          if (_isEdit && _deposit != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: _isUsed ? 'ลบไม่ได้ เพราะถูกหักในรายการซื้อ/ขายแล้ว' : 'ลบ',
              onPressed: _isUsed ? null : _delete,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ResponsivePadding(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_deposit != null) ...[
                        _buildBalanceCard(_deposit!),
                        const SizedBox(height: 16),
                      ],
                      _buildInfoCard(),
                      if (_deposit != null) ...[
                        const SizedBox(height: 16),
                        _buildUsageCard(_deposit!),
                      ],
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isSaving ? null : _goBack,
                              child: const Text('ยกเลิก'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _save,
                              child: _isSaving
                                  ? const SizedBox(
                                      width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                  : Text(_isEdit ? 'บันทึกการแก้ไข' : 'บันทึก'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('ข้อมูลเงินมัดจำ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: Deposit.typeCustomer,
                  icon: Icon(Icons.call_received),
                  label: Text('ลูกค้าวางมัดจำกับเรา'),
                ),
                ButtonSegment(
                  value: Deposit.typeSupplier,
                  icon: Icon(Icons.call_made),
                  label: Text('เราวางมัดจำกับซัพพลายเออร์'),
                ),
              ],
              selected: {_type},
              onSelectionChanged: _isUsed
                  ? null
                  : (v) => setState(() {
                        _type = v.first;
                        _partyId = null;
                      }),
            ),
            const SizedBox(height: 8),
            Text(
              _isCustomer
                  ? 'ยอดนี้จะเลือกหักได้ในรายการขายของลูกค้ารายนี้ (หักได้หลายรายการจนกว่ายอดจะหมด)'
                  : 'ยอดนี้จะเลือกหักได้ในรายการซื้อจากซัพพลายเออร์รายนี้ (หักได้หลายรายการจนกว่ายอดจะหมด)',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            IgnorePointer(
              ignoring: _isUsed,
              child: Opacity(
                opacity: _isUsed ? 0.6 : 1,
                child: _isCustomer
                    ? CustomerDropdown(
                        key: const ValueKey('deposit-customer'),
                        selectedCustomerId: _partyId,
                        allowClear: false,
                        onChanged: (v) => setState(() => _partyId = v),
                      )
                    : SupplierDropdown(
                        key: const ValueKey('deposit-supplier'),
                        selectedSupplierId: _partyId,
                        allowClear: false,
                        onChanged: (v) => setState(() => _partyId = v),
                      ),
              ),
            ),
            if (_isUsed)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('มัดจำนี้ถูกหักแล้ว จึงเปลี่ยนประเภทและคู่ค้าไม่ได้',
                    style: TextStyle(fontSize: 12, color: Colors.orange[800])),
              ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'วันที่วางมัดจำ *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(_dateFormat.format(_depositDate)),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'ยอดเงินมัดจำ *',
                prefixText: '฿ ',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final amount = double.tryParse((value ?? '').replaceAll(',', '').trim());
                if (amount == null || amount <= 0) return 'กรุณาระบุยอดเงินมัดจำ';
                final used = _deposit?.usedAmount ?? 0;
                if (amount < used - 0.005) {
                  return 'ต้องไม่น้อยกว่ายอดที่หักไปแล้ว ฿${_currency.format(used)}';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            AccountDropdown(
              selectedAccountId: _ourAccount,
              isRequired: false,
              label: _isCustomer ? 'บัญชีของเราที่รับเงินมัดจำ' : 'บัญชีของเราที่จ่ายเงินมัดจำ',
              onChanged: (v) => setState(() => _ourAccount = v),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _referenceController,
              decoration: const InputDecoration(
                labelText: 'เลขที่อ้างอิง',
                hintText: 'เช่น เลขที่ PO / ใบเสร็จรับเงินมัดจำ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _codeController,
              enabled: !_isUsed,
              decoration: InputDecoration(
                labelText: 'รหัสมัดจำ',
                hintText: _isEdit ? null : 'ว่างไว้ให้ระบบสร้างอัตโนมัติ',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'หมายเหตุ',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(Deposit d) {
    Widget stat(String label, double value, Color? color) => Expanded(
          child: Column(
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
              const SizedBox(height: 4),
              Text('฿${_currency.format(value)}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        );
    return Card(
      color: _color.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            stat('ยอดมัดจำ', d.amount, null),
            stat('หักไปแล้ว', d.usedAmount, Colors.red[700]),
            stat('คงเหลือ', d.remainingAmount, _color.shade800),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageCard(Deposit d) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_isCustomer ? 'ประวัติการหักในรายการขาย' : 'ประวัติการหักในรายการซื้อ',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (d.usages.isEmpty)
              Text('ยังไม่ได้หักในรายการใด', style: TextStyle(color: Colors.grey[600]))
            else
              ...d.usages.map((u) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(u.isSale ? Icons.point_of_sale : Icons.shopping_cart, color: _color.shade700),
                    title: Text(u.docCode),
                    subtitle: u.docDate != null ? Text(_dateFormat.format(u.docDate!)) : null,
                    trailing: Text('-฿${_currency.format(u.amount)}',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red[700])),
                    onTap: u.docId.isEmpty
                        ? null
                        : () => context.go(u.isSale ? '/sale/${u.docId}' : '/purchase/${u.docId}'),
                  )),
          ],
        ),
      ),
    );
  }
}
