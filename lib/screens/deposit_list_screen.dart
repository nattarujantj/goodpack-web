import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/deposit.dart';
import '../providers/deposit_provider.dart';
import '../providers/customer_provider.dart';
import '../services/pdf_service_deposit.dart';
import '../widgets/nav_menu_button.dart';
import '../widgets/responsive_layout.dart';

/// รายการเงินมัดจำ แยกเป็น 2 ประเภท:
/// - ลูกค้าวางมัดจำกับเรา (type=customer) ใช้หักในรายการขาย
/// - เราวางมัดจำกับซัพพลายเออร์ (type=supplier) ใช้หักในรายการซื้อ
class DepositListScreen extends StatefulWidget {
  final String depositType;

  const DepositListScreen({Key? key, this.depositType = Deposit.typeCustomer}) : super(key: key);

  @override
  State<DepositListScreen> createState() => _DepositListScreenState();
}

enum _StatusFilter { all, remaining, used }

class _DepositListScreenState extends State<DepositListScreen> {
  final _currency = NumberFormat('#,##0.00', 'th');
  final _dateFormat = DateFormat('dd/MM/yyyy');
  String _searchQuery = '';
  _StatusFilter _statusFilter = _StatusFilter.remaining;

  bool get _isCustomer => widget.depositType == Deposit.typeCustomer;
  MaterialColor get _color => _isCustomer ? Colors.teal : Colors.indigo;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DepositProvider>().loadDepositsIfNeeded();
    });
  }

  List<Deposit> _filter(List<Deposit> deposits) {
    final query = _searchQuery.trim().toLowerCase();
    return deposits.where((d) {
      if (_statusFilter == _StatusFilter.remaining && d.isFullyUsed) return false;
      if (_statusFilter == _StatusFilter.used && !d.isFullyUsed) return false;
      if (query.isEmpty) return true;
      return d.depositCode.toLowerCase().contains(query) ||
          d.partyName.toLowerCase().contains(query) ||
          d.partyCode.toLowerCase().contains(query) ||
          d.reference.toLowerCase().contains(query) ||
          d.notes.toLowerCase().contains(query) ||
          d.usages.any((u) => u.docCode.toLowerCase().contains(query));
    }).toList();
  }

  Future<void> _print(Deposit d) async {
    final targetWindow = html.window.open('', '_blank');
    try {
      final customerProvider = context.read<CustomerProvider>();
      if (customerProvider.allCustomers.isEmpty) await customerProvider.loadCustomers();
      final matches = customerProvider.allCustomers.where((c) => c.id == d.partyId);
      await PdfServiceDeposit.printDeposit(d, matches.isEmpty ? null : matches.first, targetWindow: targetWindow);
    } catch (e) {
      targetWindow.close();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ResponsiveAppBar(
        leading: const NavMenuButton(),
        title: _isCustomer ? 'มัดจำ: ลูกค้าวางมัดจำกับเรา' : 'มัดจำ: เราวางมัดจำกับซัพพลายเออร์',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<DepositProvider>().loadDeposits(),
            tooltip: 'รีเฟรช',
          ),
        ],
      ),
      body: Consumer<DepositProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && !provider.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error.isNotEmpty && !provider.hasData) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(provider.error, style: const TextStyle(color: Colors.red)),
              ),
            );
          }

          final ofType = provider.depositsOfType(widget.depositType);
          final filtered = _filter(ofType);

          return Column(
            children: [
              _buildFilters(),
              _buildSummaryBar(filtered),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.savings_outlined, size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              ofType.isEmpty ? 'ยังไม่มีรายการมัดจำ' : 'ไม่พบรายการที่ตรงกับตัวกรอง',
                              style: const TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => provider.loadDeposits(),
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 80),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) => _buildCard(filtered[index]),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/deposit-form?type=${widget.depositType}'),
        icon: const Icon(Icons.add),
        label: Text(_isCustomer ? 'รับมัดจำ' : 'วางมัดจำ'),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 320,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'ค้นหา รหัส / ${Deposit.partyLabel(widget.depositType)} / เลขที่เอกสาร...',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          SegmentedButton<_StatusFilter>(
            segments: const [
              ButtonSegment(value: _StatusFilter.remaining, label: Text('มียอดคงเหลือ')),
              ButtonSegment(value: _StatusFilter.used, label: Text('ใช้หมดแล้ว')),
              ButtonSegment(value: _StatusFilter.all, label: Text('ทั้งหมด')),
            ],
            selected: {_statusFilter},
            showSelectedIcon: false,
            onSelectionChanged: (v) => setState(() => _statusFilter = v.first),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBar(List<Deposit> deposits) {
    // มัดจำ VAT นับเป็นยอดก่อน VAT (หน่วยเดียวกับยอดที่หักได้)
    final total = deposits.fold(0.0, (sum, d) => sum + d.deductibleAmount);
    final used = deposits.fold(0.0, (sum, d) => sum + d.usedAmount);
    final remaining = deposits.fold(0.0, (sum, d) => sum + d.remainingAmount);

    Widget stat(String label, double value, {bool bold = false}) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
            Text(
              '฿${_currency.format(value)}',
              style: TextStyle(
                fontSize: bold ? 16 : 14,
                fontWeight: bold ? FontWeight.bold : FontWeight.w500,
                color: bold ? _color.shade800 : null,
              ),
            ),
          ],
        );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: _color.shade50,
      child: Wrap(
        spacing: 32,
        runSpacing: 8,
        children: [
          Text('${deposits.length} รายการ', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
          stat('ยอดมัดจำ (VAT นับก่อน VAT)', total),
          stat('หักไปแล้ว', used),
          stat('คงเหลือ', remaining, bold: true),
        ],
      ),
    );
  }

  Widget _buildCard(Deposit d) {
    final progress = d.deductibleAmount > 0 ? (d.usedAmount / d.deductibleAmount).clamp(0.0, 1.0) : 0.0;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.go('/deposit-form?id=${d.id}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: _color.shade100,
                    child: Icon(
                      _isCustomer ? Icons.call_received : Icons.call_made,
                      color: _color.shade700,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(d.partyName,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: d.isVAT ? Colors.green.shade50 : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                d.isVAT ? 'VAT ฿${_currency.format(d.amount)}' : 'ไม่มี VAT',
                                style: TextStyle(
                                    fontSize: 10, color: d.isVAT ? Colors.green.shade800 : Colors.grey.shade700),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          [
                            d.depositCode,
                            _dateFormat.format(d.depositDate),
                            if (d.reference.isNotEmpty) 'อ้างอิง ${d.reference}',
                          ].join(' · '),
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        if (d.notes.isNotEmpty)
                          Text(d.notes,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '฿${_currency.format(d.remainingAmount)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: d.isFullyUsed ? Colors.grey : _color.shade800,
                        ),
                      ),
                      Text('คงเหลือ${d.balanceUnitLabel} จาก ฿${_currency.format(d.deductibleAmount)}',
                          style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                    ],
                  ),
                  if (_isCustomer)
                    IconButton(
                      icon: const Icon(Icons.print, size: 20),
                      tooltip: d.isVAT ? 'พิมพ์ใบรับเงินมัดจำ/ใบกำกับภาษี' : 'พิมพ์ใบรับเงินมัดจำ',
                      onPressed: () => _print(d),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: Colors.grey.shade200,
                  color: _color.shade400,
                ),
              ),
              if (d.usages.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: d.usages
                      .map((u) => Chip(
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            label: Text('${u.docCode} ฿${_currency.format(u.amount)}',
                                style: const TextStyle(fontSize: 11)),
                          ))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
