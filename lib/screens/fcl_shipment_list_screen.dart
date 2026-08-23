import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/fcl_shipment.dart';
import '../providers/fcl_shipment_provider.dart';
import '../providers/shipping_company_provider.dart';
import '../utils/date_formatter.dart';

/// The "ตู้ FCL" tab: a grouped view of every container. Each row links to the
/// container detail where cost is entered and allocated across its factories.
class FclShipmentListView extends StatefulWidget {
  const FclShipmentListView({Key? key}) : super(key: key);

  @override
  State<FclShipmentListView> createState() => _FclShipmentListViewState();
}

class _FclShipmentListViewState extends State<FclShipmentListView> {
  final _currencyFormat = NumberFormat('#,##0.00');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FclShipmentProvider>().loadIfNeeded();
      context.read<ShippingCompanyProvider>().loadIfNeeded();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FclShipmentProvider>(
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

        final shipments = provider.allShipments;
        return RefreshIndicator(
          onRefresh: provider.refresh,
          child: shipments.isEmpty
              ? ListView(
                  children: [
                    const SizedBox(height: 80),
                    Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    const Center(child: Text('ยังไม่มีตู้ FCL')),
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('สร้างตู้ใหม่'),
                        onPressed: () => context.push('/fcl-shipment-form'),
                      ),
                    ),
                  ],
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: shipments.length,
                  itemBuilder: (context, index) => _buildCard(shipments[index]),
                ),
        );
      },
    );
  }

  Widget _buildCard(FclShipment s) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => context.push('/fcl-shipment/${s.id}'),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.inventory_2, color: Colors.blue[700]),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(s.fclCode, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(width: 8),
                        _statusBadge(s.status),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${s.shippingCompanyName.isNotEmpty ? s.shippingCompanyName : "-"} · ${DateFormatter.formatDate(s.shipmentDate)}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),
              _stat('ค่าตู้', '${_currencyFormat.format(s.totalCostThb)} ฿'),
              const SizedBox(width: 16),
              _stat('CBM', s.totalCBM.toStringAsFixed(1)),
              const SizedBox(width: 16),
              _stat('โรงงาน', '${s.linkedImportCount} ใบ'),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      ],
    );
  }

  Widget _statusBadge(String status) {
    final isOpen = status == 'open';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isOpen ? Colors.orange[50] : Colors.green[50],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isOpen ? 'เปิดตู้' : 'ปิดตู้',
        style: TextStyle(
          color: isOpen ? Colors.orange[800] : Colors.green[700],
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }
}
