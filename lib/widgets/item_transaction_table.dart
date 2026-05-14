import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/product_transaction.dart';
import '../services/api_service.dart';
import '../utils/number_formatter.dart';
import '../utils/date_formatter.dart';

class ItemTransactionTable extends StatefulWidget {
  final String productId;
  final bool isVAT;
  final bool isSale;
  final String title;

  const ItemTransactionTable({
    Key? key,
    required this.productId,
    required this.isVAT,
    required this.isSale,
    required this.title,
  }) : super(key: key);

  @override
  State<ItemTransactionTable> createState() => _ItemTransactionTableState();
}

class _ItemTransactionTableState extends State<ItemTransactionTable> {
  static const int _limit = 10;

  int _currentPage = 1;
  int _totalPages = 1;
  int _total = 0;
  bool _isLoading = true;
  String? _error;
  List<ProductTransactionItem> _data = [];

  @override
  void initState() {
    super.initState();
    _load(1);
  }

  Future<void> _load(int page) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final ProductTransactionPage result;
      if (widget.isSale) {
        result = await ApiService().getProductSales(
          widget.productId,
          isVAT: widget.isVAT,
          page: page,
          limit: _limit,
        );
      } else {
        result = await ApiService().getProductPurchases(
          widget.productId,
          isVAT: widget.isVAT,
          page: page,
          limit: _limit,
        );
      }

      if (mounted) {
        setState(() {
          _data = result.data;
          _currentPage = result.page;
          _totalPages = result.totalPages;
          _total = result.total;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _goToPage(int page) {
    if (page < 1 || page > _totalPages || page == _currentPage) return;
    _load(page);
  }

  void _navigateToDetail(String id) {
    final route = widget.isSale ? '/sale/$id' : '/purchase/$id';
    context.push(route);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header row
            Row(
              children: [
                Icon(
                  widget.isSale ? Icons.sell_outlined : Icons.shopping_cart_outlined,
                  size: 18,
                  color: widget.isSale ? Colors.green[700] : Colors.blue[700],
                ),
                const SizedBox(width: 8),
                Text(
                  widget.title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                if (!_isLoading && _error == null)
                  Text(
                    '($_total รายการ)',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _buildBody(),
            if (!_isLoading && _error == null && _totalPages > 1) ...[
              const SizedBox(height: 12),
              _buildPagination(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'โหลดข้อมูลไม่สำเร็จ',
            style: TextStyle(color: Colors.red[400]),
          ),
        ),
      );
    }

    if (_data.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.inbox_outlined, size: 40, color: Colors.grey[400]),
              const SizedBox(height: 8),
              Text('ไม่มีรายการ', style: TextStyle(color: Colors.grey[500])),
            ],
          ),
        ),
      );
    }

    return Scrollbar(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          showCheckboxColumn: false,
          columnSpacing: 16,
          headingRowColor: WidgetStateProperty.all(Colors.grey[100]),
          dataRowColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return Colors.blue[50];
            }
            return null;
          }),
          columns: _buildColumns(),
          rows: _data.map(_buildRow).toList(),
        ),
      ),
    );
  }

  List<DataColumn> _buildColumns() {
    return [
      const DataColumn(label: Text('วันที่', style: TextStyle(fontWeight: FontWeight.bold))),
      const DataColumn(label: Text('เลขรายการ', style: TextStyle(fontWeight: FontWeight.bold))),
      DataColumn(
        label: Text(
          widget.isSale ? 'ลูกค้า' : 'ซัพพลายเออร์',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      const DataColumn(
        label: Text('จำนวน', style: TextStyle(fontWeight: FontWeight.bold)),
        numeric: true,
      ),
      const DataColumn(
        label: Text('ราคา/หน่วย', style: TextStyle(fontWeight: FontWeight.bold)),
        numeric: true,
      ),
      const DataColumn(
        label: Text('รวม', style: TextStyle(fontWeight: FontWeight.bold)),
        numeric: true,
      ),
      if (widget.isVAT)
        const DataColumn(
          label: Text('รวมหลัง VAT', style: TextStyle(fontWeight: FontWeight.bold)),
          numeric: true,
        ),
    ];
  }

  DataRow _buildRow(ProductTransactionItem item) {
    return DataRow(
      onSelectChanged: (_) => _navigateToDetail(item.id),
      cells: [
        DataCell(Text(DateFormatter.formatDate(item.date))),
        DataCell(
          Text(
            item.documentCode,
            style: TextStyle(
              color: Colors.blue[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 200),
            child: Text(
              item.partnerName,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(Text(NumberFormatter.formatQuantity(item.quantity))),
        DataCell(Text(NumberFormatter.formatPrice(item.unitPrice))),
        DataCell(Text(NumberFormatter.formatPrice(item.totalPrice))),
        if (widget.isVAT)
          DataCell(Text(NumberFormatter.formatPrice(item.grandTotal))),
      ],
    );
  }

  Widget _buildPagination() {
    final pageButtons = _buildPageNumbers();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Previous arrow
        _PaginationButton(
          label: '<',
          onTap: _currentPage > 1 ? () => _goToPage(_currentPage - 1) : null,
        ),
        const SizedBox(width: 4),
        ...pageButtons,
        const SizedBox(width: 4),
        // Next arrow
        _PaginationButton(
          label: '>',
          onTap: _currentPage < _totalPages ? () => _goToPage(_currentPage + 1) : null,
        ),
      ],
    );
  }

  List<Widget> _buildPageNumbers() {
    // Show at most 7 page buttons: 1 ... X-1 X X+1 ... N
    final List<Widget> widgets = [];
    final pages = <int>{};

    pages.add(1);
    pages.add(_totalPages);
    pages.add(_currentPage);
    if (_currentPage > 1) pages.add(_currentPage - 1);
    if (_currentPage < _totalPages) pages.add(_currentPage + 1);

    final sorted = pages.toList()..sort();

    int? prev;
    for (final p in sorted) {
      if (prev != null && p - prev > 1) {
        widgets.add(const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text('...', style: TextStyle(color: Colors.grey)),
        ));
      }
      widgets.add(_PaginationButton(
        label: '$p',
        isActive: p == _currentPage,
        onTap: () => _goToPage(p),
      ));
      if (p != sorted.last) widgets.add(const SizedBox(width: 4));
      prev = p;
    }

    return widgets;
  }
}

class _PaginationButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  const _PaginationButton({
    required this.label,
    this.isActive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        constraints: const BoxConstraints(minWidth: 32),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? Colors.blue[700] : null,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isActive
                ? Colors.blue[700]!
                : isDisabled
                    ? Colors.grey[300]!
                    : Colors.grey[400]!,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive
                ? Colors.white
                : isDisabled
                    ? Colors.grey[400]
                    : Colors.grey[700],
          ),
        ),
      ),
    );
  }
}
