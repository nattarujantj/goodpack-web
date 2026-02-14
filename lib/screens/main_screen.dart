import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/responsive_layout.dart';
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

  // สำหรับ ExpansionTile
  bool _isPurchaseExpanded = false;
  bool _isSaleExpanded = false;
  bool _isQuotationExpanded = false;

  final List<Widget> _screens = [
    const ProductListScreen(),
  ];

  final List<BottomNavigationBarItem> _bottomNavItems = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.dashboard),
      label: 'สรุป',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.inventory_2),
      label: 'สินค้า',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.business),
      label: 'ลูกค้า',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.local_shipping),
      label: 'ซัพพลายเออร์',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.shopping_cart),
      label: 'ซื้อ',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.point_of_sale),
      label: 'ขาย',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.description),
      label: 'เสนอราคา',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.file_download),
      label: 'Export',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.upload_file),
      label: 'Import',
    ),
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

  /// คืนค่า index ของเมนูที่ควรไฮไลท์ตาม route ปัจจุบัน (เมื่อใช้ GoRouter)
  int _getSelectedIndex() {
    if (widget.child == null) return _currentIndex;
    final path = GoRouterState.of(context).uri.path;
    if (path == '/dashboard') return 0;
    if (path == '/' || path.startsWith('/product')) return 1;
    if (path.startsWith('/customer')) return 2;
    if (path.startsWith('/supplier')) return 3;
    if (path.startsWith('/purchase')) return 4;
    if (path.startsWith('/sale')) return 5;
    if (path.startsWith('/quotation')) return 6;
    if (path == '/export') return 7;
    if (path == '/import') return 8;
    return _currentIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Desktop sidebar navigation
          if (MediaQuery.of(context).size.width >= 1200)
            _buildDesktopNavigation(),
          
          // Main content area
          Expanded(
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
        ],
      ),
      bottomNavigationBar: MediaQuery.of(context).size.width < 1200
          ? MediaQuery.of(context).size.width < 768
              ? _buildBottomNavigationBar()
              : _buildTabletNavigation()
          : null,
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _getSelectedIndex(),
      onTap: _onTabTapped,
      type: BottomNavigationBarType.fixed,
      items: _bottomNavItems,
      selectedItemColor: Theme.of(context).primaryColor,
      unselectedItemColor: Colors.grey[600],
    );
  }

  Widget _buildTabletNavigation() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: _bottomNavItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isSelected = _getSelectedIndex() == index;
          
          return Expanded(
            child: InkWell(
              onTap: () => _onTabTapped(index),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    item.icon,
                    const SizedBox(height: 4),
                    Text(
                      item.label!,
                      style: TextStyle(
                        color: isSelected 
                            ? Theme.of(context).primaryColor 
                            : Colors.grey[600],
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
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
      child: Column(
        children: [
          // App Header
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(
                  Icons.inventory_2,
                  size: 48,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 8),
                ResponsiveText(
                  'GoodPack',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                ResponsiveText(
                  'Inventory Management',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(),
          
          // Navigation Items
          Expanded(
            child: ListView(
              children: [
                // สรุป Dashboard
                _buildNavItem(0, Icons.dashboard, 'สรุปภาพรวม'),
                
                const Divider(height: 8, indent: 16, endIndent: 16),
                
                // สินค้า
                _buildNavItem(1, Icons.inventory_2, 'สินค้า'),
                // ลูกค้า
                _buildNavItem(2, Icons.business, 'ลูกค้า'),
                // ซัพพลายเออร์
                _buildNavItem(3, Icons.local_shipping, 'ซัพพลายเออร์'),
                
                // ซื้อ - มีเมนูย่อย
                _buildExpandableNavItem(
                  icon: Icons.shopping_cart,
                  title: 'ซื้อ',
                  isExpanded: _isPurchaseExpanded,
                  onExpand: (expanded) => setState(() => _isPurchaseExpanded = expanded),
                  isSelected: _getSelectedIndex() == 4,
                  children: [
                    _buildSubNavItem('ทั้งหมด', '/purchases'),
                    _buildSubNavItem('VAT', '/purchases?vat=true'),
                    _buildSubNavItem('Non-VAT', '/purchases?vat=false'),
                  ],
                ),
                
                // ขาย - มีเมนูย่อย
                _buildExpandableNavItem(
                  icon: Icons.point_of_sale,
                  title: 'ขาย',
                  isExpanded: _isSaleExpanded,
                  onExpand: (expanded) => setState(() => _isSaleExpanded = expanded),
                  isSelected: _getSelectedIndex() == 5,
                  children: [
                    _buildSubNavItem('ทั้งหมด', '/sales'),
                    _buildSubNavItem('VAT', '/sales?vat=true'),
                    _buildSubNavItem('Non-VAT', '/sales?vat=false'),
                  ],
                    ),
                
                // เสนอราคา - มีเมนูย่อย
                _buildExpandableNavItem(
                  icon: Icons.description,
                  title: 'เสนอราคา',
                  isExpanded: _isQuotationExpanded,
                  onExpand: (expanded) => setState(() => _isQuotationExpanded = expanded),
                  isSelected: _getSelectedIndex() == 6,
                  children: [
                    _buildSubNavItem('ทั้งหมด', '/quotations'),
                    _buildSubNavItem('VAT', '/quotations?vat=true'),
                    _buildSubNavItem('Non-VAT', '/quotations?vat=false'),
                  ],
                ),
                
                const Divider(height: 24, indent: 16, endIndent: 16),
                
                // Export
                _buildNavItem(7, Icons.file_download, 'Export'),
                // Import
                _buildNavItem(8, Icons.upload_file, 'Import'),
              ],
            ),
          ),
          
          // Footer
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Divider(),
                const SizedBox(height: 8),
                ResponsiveText(
                  'เวอร์ชัน 1.0.0',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
            color: isSelected 
                ? Theme.of(context).primaryColor 
                : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        onTap: () => _onTabTapped(index),
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
          leading: Icon(
            icon,
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey[700],
          ),
          title: Text(
            title,
            style: TextStyle(
              color: isSelected 
                  ? Theme.of(context).primaryColor 
                  : Colors.grey[700],
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
            color: isSelected 
                ? Theme.of(context).primaryColor 
                : Colors.grey[600],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        onTap: () => context.go(route),
      ),
    );
  }

  void _onTabTapped(int index) {
    // สำหรับเมนูที่มีเมนูย่อย (ซื้อ, ขาย, เสนอราคา) แสดง Bottom Sheet บนมือถือ/tablet
    // index 4 = ซื้อ, index 5 = ขาย, index 6 = เสนอราคา
    if (MediaQuery.of(context).size.width < 1200 && (index == 4 || index == 5 || index == 6)) {
      _showVatFilterSheet(index);
      return;
    }
    
    setState(() {
      _currentIndex = index;
    });
    
    // If using router (child is not null), navigate using GoRouter
    if (widget.child != null) {
      switch (index) {
        case 0:
          context.go('/dashboard');
          break;
        case 1:
          context.go('/');
          break;
        case 2:
          context.go('/customers');
          break;
        case 3:
          context.go('/suppliers');
          break;
        case 4:
          context.go('/purchases');
          break;
        case 5:
          context.go('/sales');
          break;
        case 6:
          context.go('/quotations');
          break;
        case 7:
          context.go('/export');
          break;
        case 8:
          context.go('/import');
          break;
      }
    } else {
      // Only animate if PageView is being used (when child is null)
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }
  
  void _showVatFilterSheet(int menuIndex) {
    String title;
    String basePath;
    IconData icon;
    
    switch (menuIndex) {
      case 4:
        title = 'รายการซื้อ';
        basePath = '/purchases';
        icon = Icons.shopping_cart;
        break;
      case 5:
        title = 'รายการขาย';
        basePath = '/sales';
        icon = Icons.point_of_sale;
        break;
      case 6:
        title = 'เสนอราคา';
        basePath = '/quotations';
        icon = Icons.description;
        break;
      default:
        return;
    }
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(icon, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              
              // Options
              ListTile(
                leading: const Icon(Icons.list),
                title: const Text('ทั้งหมด'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _currentIndex = menuIndex);
                  context.go(basePath);
                },
              ),
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: const Text('VAT'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _currentIndex = menuIndex);
                  context.go('$basePath?vat=true');
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel, color: Colors.red),
                title: const Text('Non-VAT'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _currentIndex = menuIndex);
                  context.go('$basePath?vat=false');
                },
              ),
              
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
