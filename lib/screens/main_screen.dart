import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/main_scaffold_scope.dart';
import '../config/app_config.dart';
import 'product_list_screen.dart';

class MainScreen extends StatefulWidget {
  final Widget? child;

  const MainScreen({Key? key, this.child}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late PageController _pageController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  // สำหรับ ExpansionTile
  bool _isPurchaseExpanded = false;
  bool _isSaleExpanded = false;
  bool _isQuotationExpanded = false;

  final List<Widget> _screens = [
    const ProductListScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  int _getSelectedIndex() {
    if (widget.child == null) return _currentIndex;
    final path = GoRouterState.of(context).uri.path;
    if (path == '/dashboard') return 0;
    if (path == '/' || path.startsWith('/product')) return 1;
    if (path == '/inventory-snapshots') return 11;
    if (path.startsWith('/customer')) return 2;
    if (path.startsWith('/supplier')) return 3;
    if (path.startsWith('/purchase')) return 4;
    if (path.startsWith('/sale')) return 5;
    if (path.startsWith('/quotation')) return 6;
    if (path.startsWith('/expense')) return 7;
    if (path == '/export') return 8;
    if (path.startsWith('/international')) return 9;
    if (path == '/users') return 10;
    return _currentIndex;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    if (!authProvider.isInitialized || !authProvider.isLoggedIn) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      key: _scaffoldKey,
      drawer: width < 1200 ? _buildDrawer() : null,
      body: Row(
        children: [
          if (width >= 1200)
            _buildDesktopNavigation(),
          Expanded(
            child: MainScaffoldScope(
              scaffoldKey: _scaffoldKey,
              child: widget.child ?? PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                children: _screens,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationContent() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.inventory_2, size: 48, color: Theme.of(context).primaryColor),
              const SizedBox(height: 8),
              ResponsiveText(
                'GoodPack',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              ResponsiveText(
                'Inventory Management',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: ListView(
            children: [
              _buildNavItem(0, Icons.dashboard, 'สรุปภาพรวม'),
              const Divider(height: 8, indent: 16, endIndent: 16),
              _buildNavItem(1, Icons.inventory_2, 'สินค้า'),
              _buildNavItem(11, Icons.history, 'คลังสินค้ารายเดือน'),
              _buildNavItem(2, Icons.business, 'ลูกค้า'),
              _buildNavItem(3, Icons.local_shipping, 'ซัพพลายเออร์'),
              _buildExpandableNavItem(
                icon: Icons.shopping_cart,
                title: 'ซื้อ',
                isExpanded: _isPurchaseExpanded,
                onExpand: (v) => setState(() => _isPurchaseExpanded = v),
                isSelected: _getSelectedIndex() == 4,
                children: [
                  _buildSubNavItem('ทั้งหมด', '/purchases'),
                  _buildSubNavItem('VAT', '/purchases?vat=true'),
                  _buildSubNavItem('Non-VAT', '/purchases?vat=false'),
                ],
              ),
              _buildExpandableNavItem(
                icon: Icons.point_of_sale,
                title: 'ขาย',
                isExpanded: _isSaleExpanded,
                onExpand: (v) => setState(() => _isSaleExpanded = v),
                isSelected: _getSelectedIndex() == 5,
                children: [
                  _buildSubNavItem('ทั้งหมด', '/sales'),
                  _buildSubNavItem('VAT', '/sales?vat=true'),
                  _buildSubNavItem('Non-VAT', '/sales?vat=false'),
                ],
              ),
              _buildExpandableNavItem(
                icon: Icons.description,
                title: 'เสนอราคา',
                isExpanded: _isQuotationExpanded,
                onExpand: (v) => setState(() => _isQuotationExpanded = v),
                isSelected: _getSelectedIndex() == 6,
                children: [
                  _buildSubNavItem('ทั้งหมด', '/quotations'),
                  _buildSubNavItem('VAT', '/quotations?vat=true'),
                  _buildSubNavItem('Non-VAT', '/quotations?vat=false'),
                ],
              ),
              _buildNavItem(7, Icons.receipt_long, 'ค่าใช้จ่าย'),
              const Divider(height: 24, indent: 16, endIndent: 16),
              _buildNavItem(8, Icons.file_download, 'Export'),
              _buildNavItem(9, Icons.public, 'International'),
              if (context.read<AuthProvider>().isSuperAdmin) ...[
                const Divider(height: 24, indent: 16, endIndent: 16),
                _buildNavItem(10, Icons.people, 'จัดการ Users'),
              ],
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Divider(),
              const SizedBox(height: 4),
              Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.logout, size: 20, color: Colors.red),
                    title: Text(
                      'ออกจากระบบ (${auth.user?.displayName ?? ""})',
                      style: const TextStyle(fontSize: 13, color: Colors.red),
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    onTap: () => auth.logout(),
                  );
                },
              ),
              const SizedBox(height: 4),
              // Version auto-updates from AppConfig.appVersion — bump that constant each PR
              ResponsiveText(
                'เวอร์ชัน ${AppConfig.appVersion}',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopNavigation() {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: _buildNavigationContent(),
    );
  }

  Widget _buildDrawer() {
    return Drawer(child: _buildNavigationContent());
  }

  Widget _buildNavItem(int index, IconData icon, String title) {
    final isSelected = _getSelectedIndex() == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        leading: Icon(icon),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onTap: () {
          if (MediaQuery.of(context).size.width < 1200) {
            Navigator.of(context).pop(); // close drawer
          }
          _onTabTapped(index);
        },
      ),
    );
  }

  Widget _buildExpandableNavItem({
    required IconData icon,
    required String title,
    required bool isExpanded,
    required Function(bool) onExpand,
    required bool isSelected,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Icon(icon, color: isSelected ? Theme.of(context).primaryColor : Colors.grey[700]),
          title: Text(
            title,
            style: TextStyle(
              color: isSelected ? Theme.of(context).primaryColor : Colors.grey[700],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          initiallyExpanded: isExpanded,
          onExpansionChanged: onExpand,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.only(left: 16),
          children: children,
        ),
      ),
    );
  }

  Widget _buildSubNavItem(String title, String route) {
    final currentPath = GoRouterState.of(context).uri.toString();
    final isSelected = currentPath == route || currentPath.startsWith('$route&');
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        dense: true,
        leading: Icon(
          isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
          size: 18,
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey[500],
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey[600],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onTap: () {
          if (MediaQuery.of(context).size.width < 1200) {
            Navigator.of(context).pop(); // close drawer
          }
          context.go(route);
        },
      ),
    );
  }

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
    if (widget.child != null) {
      switch (index) {
        case 0: context.go('/dashboard'); break;
        case 1: context.go('/'); break;
        case 2: context.go('/customers'); break;
        case 3: context.go('/suppliers'); break;
        case 4: context.go('/purchases'); break;
        case 5: context.go('/sales'); break;
        case 6: context.go('/quotations'); break;
        case 7: context.go('/expenses'); break;
        case 8: context.go('/export'); break;
        case 9: context.go('/internationals'); break;
        case 10: context.go('/users'); break;
        case 11: context.go('/inventory-snapshots'); break;
      }
    } else {
      if (_pageController.hasClients) {
        _pageController.animateToPage(index,
            duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      }
    }
  }
}
