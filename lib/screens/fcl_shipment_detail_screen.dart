import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/fcl_shipment.dart';
import '../models/international_import.dart';
import '../providers/fcl_shipment_provider.dart';
import '../services/fcl_shipment_api_service.dart';
import '../widgets/responsive_layout.dart';
import '../utils/date_formatter.dart';
import '../utils/error_dialog.dart';

class FclShipmentDetailScreen extends StatefulWidget {
  final String shipmentId;
  const FclShipmentDetailScreen({Key? key, required this.shipmentId}) : super(key: key);

  @override
  State<FclShipmentDetailScreen> createState() => _FclShipmentDetailScreenState();
}

class _FclShipmentDetailScreenState extends State<FclShipmentDetailScreen> {
  final _currencyFormat = NumberFormat('#,##0.00');
  List<InternationalImport> _imports = [];
  bool _loadingImports = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final provider = context.read<FclShipmentProvider>();
    await provider.fetchById(widget.shipmentId);
    await _loadImports();
  }

  Future<void> _loadImports() async {
    setState(() => _loadingImports = true);
    try {
      final imports = await FclShipmentApiService.getImports(widget.shipmentId);
      if (mounted) setState(() => _imports = imports);
    } catch (_) {
      // keep whatever we had
    } finally {
      if (mounted) setState(() => _loadingImports = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ResponsiveAppBar(
        title: 'รายละเอียดตู้ FCL',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/internationals'),
        ),
      ),
      body: Consumer<FclShipmentProvider>(
        builder: (context, provider, _) {
          final s = provider.getById(widget.shipmentId);
          if (s == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 980),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(s),
                    const SizedBox(height: 16),
                    _buildStatusBanner(s),
                    const SizedBox(height: 16),
                    _buildCostCard(s),
                    const SizedBox(height: 16),
                    _buildImportsCard(s),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(FclShipment s) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(s.fclCode, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(width: 10),
                _statusBadge(s.status),
                const Spacer(),
                if (s.isOpen)
                  IconButton(
                    icon: const Icon(Icons.edit),
                    tooltip: 'แก้ไขตู้',
                    onPressed: () => context.push('/fcl-shipment-form?id=${s.id}'),
                  ),
              ],
            ),
            const Divider(height: 24),
            _infoRow('วันที่', DateFormatter.formatDate(s.shipmentDate)),
            _infoRow('Shipping Company', s.shippingCompanyName.isNotEmpty ? s.shippingCompanyName : '-'),
            _infoRow('เรทกลาง USD/THB', s.usdToThbRate == 0 ? '-' : _currencyFormat.format(s.usdToThbRate)),
            if (s.notes != null && s.notes!.isNotEmpty) _infoRow('หมายเหตุ', s.notes!),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBanner(FclShipment s) {
    final isOpen = s.isOpen;
    final color = isOpen ? Colors.orange : Colors.green;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(isOpen ? Icons.hourglass_top : Icons.lock, color: color[800], size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOpen ? 'ประมาณการ — ตู้ยังเปิดอยู่' : 'ล็อกแล้ว (final) — ปิดตู้เรียบร้อย',
                  style: TextStyle(fontWeight: FontWeight.bold, color: color[800]),
                ),
                const SizedBox(height: 2),
                Text(
                  isOpen
                      ? 'ค่าขนส่ง/ชิ้นคำนวณจาก CBM เท่าที่มีตอนนี้ จะเปลี่ยนเมื่อเพิ่ม/แก้โรงงาน'
                      : 'ค่าเฉลี่ยถูกตรึงไว้ พร้อมนำไปสร้าง purchase / ต้นทุนสินค้า',
                  style: TextStyle(fontSize: 13, color: color[900]),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _busy
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : isOpen
                  ? ElevatedButton.icon(
                      icon: const Icon(Icons.lock, size: 18),
                      label: const Text('ปิดตู้'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green[600]),
                      onPressed: () => _confirmClose(s),
                    )
                  : OutlinedButton.icon(
                      icon: const Icon(Icons.lock_open, size: 18),
                      label: const Text('เปิดตู้อีกครั้ง'),
                      onPressed: () => _reopen(s),
                    ),
        ],
      ),
    );
  }

  Widget _buildCostCard(FclShipment s) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ค่าตู้ (เหมาทั้งตู้)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (s.costLines.isEmpty)
              const Text('ยังไม่มีรายการค่าตู้', style: TextStyle(color: Colors.grey))
            else
              ...s.costLines.map((line) {
                final sub = line.currency == 'USD'
                    ? '\$${_currencyFormat.format(line.amount)} × ${line.usdRate > 0 ? line.usdRate : s.usdToThbRate}'
                    : null;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(line.name),
                            if (sub != null) Text(sub, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          ],
                        ),
                      ),
                      Text('${_currencyFormat.format(line.amountThb)} ฿',
                          style: const TextStyle(fontWeight: FontWeight.w500)),
                    ],
                  ),
                );
              }),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('ค่าตู้รวม', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('${_currencyFormat.format(s.totalCostThb)} บาท',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportsCard(FclShipment s) {
    final totalCBM = s.totalCBM;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('โรงงานในตู้ (${_imports.length})',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                if (s.isOpen)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('เพิ่มโรงงาน'),
                    onPressed: () => context.push('/international-form?fclShipmentId=${s.id}'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text('ต้นทุนขนส่งเฉลี่ย/CBM: ${totalCBM > 0 ? _currencyFormat.format(s.totalCostThb / totalCBM) : "-"} บาท',
                style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            const SizedBox(height: 12),
            if (_loadingImports)
              const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
            else if (_imports.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text('ยังไม่มีโรงงานในตู้นี้', style: TextStyle(color: Colors.grey))),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 20,
                  headingRowColor: WidgetStateProperty.all(Colors.grey[100]),
                  columns: const [
                    DataColumn(label: Text('เลขที่ / โรงงาน')),
                    DataColumn(label: Text('CBM'), numeric: true),
                    DataColumn(label: Text('% ของตู้'), numeric: true),
                    DataColumn(label: Text('ค่าขนส่งเฉลี่ย (฿)'), numeric: true),
                  ],
                  rows: _imports.map((imp) {
                    final impCBM = imp.totalCBM;
                    final pct = totalCBM > 0 ? impCBM / totalCBM * 100 : 0;
                    final allocated = imp.totalShippingCost;
                    return DataRow(
                      onSelectChanged: (_) => context.push('/international/${imp.id}'),
                      cells: [
                        DataCell(Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(imp.importCode,
                                style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.blue)),
                            Text(imp.supplierName, style: const TextStyle(fontSize: 12)),
                          ],
                        )),
                        DataCell(Text(impCBM.toStringAsFixed(1))),
                        DataCell(Text('${pct.toStringAsFixed(1)}%')),
                        DataCell(Text(_currencyFormat.format(allocated))),
                      ],
                    );
                  }).toList(),
                ),
              ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('CBM รวมของตู้', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('${totalCBM.toStringAsFixed(1)} คิว', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(label, style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : null)),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    final isOpen = status == 'open';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: isOpen ? Colors.orange[50] : Colors.green[50],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isOpen ? 'เปิดตู้' : 'ปิดตู้',
        style: TextStyle(
          color: isOpen ? Colors.orange[800] : Colors.green[700],
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }

  Future<void> _confirmClose(FclShipment s) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ปิดตู้?'),
        content: const Text(
            'เมื่อปิดตู้ ค่าขนส่งเฉลี่ยของทุกโรงงานจะถูกล็อกเป็นค่า final และแก้ไขไม่ได้จนกว่าจะเปิดตู้อีกครั้ง'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[600]),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ปิดตู้'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    final provider = context.read<FclShipmentProvider>();
    final ok = await provider.close(s.id);
    if (ok) {
      await _loadImports();
    } else if (mounted) {
      ErrorDialog.showServerError(context, provider.error);
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _reopen(FclShipment s) async {
    setState(() => _busy = true);
    final provider = context.read<FclShipmentProvider>();
    final ok = await provider.reopen(s.id);
    if (ok) {
      await _loadImports();
    } else if (mounted) {
      ErrorDialog.showServerError(context, provider.error);
    }
    if (mounted) setState(() => _busy = false);
  }
}
