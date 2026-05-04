import 'package:flutter/material.dart';

class SearchableDropdown<T> extends StatefulWidget {
  final T? value;
  final List<T> items;
  final String Function(T) itemAsString;
  final T Function(T)? itemAsValue;
  final void Function(T?)? onChanged;
  final String? hint;
  final String? label;
  final String? Function(T?)? validator;
  final bool enabled;
  final bool allowClear;
  final Widget? prefixIcon;
  final Widget? suffixIcon;

  const SearchableDropdown({
    Key? key,
    this.value,
    required this.items,
    required this.itemAsString,
    this.itemAsValue,
    this.onChanged,
    this.hint,
    this.label,
    this.validator,
    this.enabled = true,
    this.allowClear = false,
    this.prefixIcon,
    this.suffixIcon,
  }) : super(key: key);

  @override
  State<SearchableDropdown<T>> createState() => _SearchableDropdownState<T>();
}

class _SearchableDropdownState<T> extends State<SearchableDropdown<T>> {
  late TextEditingController _searchController;
  List<T> _filteredItems = [];
  bool _isOpen = false;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filteredItems = widget.items;
    _focusNode.addListener(_onFocusChange);
    
    // Set initial value if provided
    if (widget.value != null) {
      _searchController.text = widget.itemAsString(widget.value!);
    }
  }

  @override
  void didUpdateWidget(SearchableDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Update text when value changes
    if (widget.value != oldWidget.value) {
      if (widget.value != null) {
        _searchController.text = widget.itemAsString(widget.value!);
      } else {
        setState(() {
          _filteredItems = widget.items;
        });
        _searchController.clear();
      }
    } else if (widget.value == null && _searchController.text.isNotEmpty) {
      // value is still null but text field has stale text — force clear
      _searchController.clear();
      setState(() {
        _filteredItems = widget.items;
      });
    }
    
    // Update filtered items when items list changes (e.g., data loaded asynchronously)
    if (widget.items != oldWidget.items) {
      setState(() {
        if (_searchController.text.isNotEmpty) {
          _filterItems(_searchController.text); // Re-filter with current query
        } else {
          _filteredItems = widget.items; // Show all new items
        }
      });
      
      // Update overlay if it's open
      if (_overlayEntry != null) {
        _overlayEntry!.markNeedsBuild();
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _showOverlay();
    }
    // Don't close overlay on focus loss - let tap-outside handle it
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;

    // For mobile/tablet, use bottom sheet instead of overlay
    if (MediaQuery.of(context).size.width < 600) {
      _showBottomSheet();
      return;
    }

    _overlayEntry = OverlayEntry(
      builder: (context) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          // Tap outside dropdown closes it
          _removeOverlay();
        },
        child: Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              // Invisible full-screen tap area to catch taps outside dropdown
              Positioned.fill(
                child: Container(color: Colors.transparent),
              ),
              // Dropdown content positioned below input
              Positioned(
                width: _getDropdownWidth(),
                child: CompositedTransformFollower(
                  link: _layerLink,
                  showWhenUnlinked: false,
                  offset: const Offset(0, 70),
                  child: GestureDetector(
                    onTap: () {}, // Prevent tap from reaching outer GestureDetector
                    child: Material(
                      elevation: 8,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 200),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: _buildDropdownContent(),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _showBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          expand: false,
          maxChildSize: 0.6,
          initialChildSize: 0.5,
          builder: (BuildContext context, ScrollController scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                children: [
                  // Header with close button
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.label ?? 'เลือก',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  // Search field
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'ค้นหา...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: _filterItems,
                    ),
                  ),
                  // Items list
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      shrinkWrap: true,
                      itemCount: _filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = _filteredItems[index];
                        final isSelected = item == widget.value;

                        return ListTile(
                          title: Text(widget.itemAsString(item)),
                          trailing: isSelected
                              ? const Icon(Icons.check, color: Colors.blue)
                              : null,
                          selected: isSelected,
                          selectedTileColor: Colors.blue[50],
                          onTap: () {
                            widget.onChanged?.call(item);
                            _searchController.text = widget.itemAsString(item);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDropdownContent() {
    return _filteredItems.isEmpty
        ? Padding(
            padding: const EdgeInsets.all(16),
            child: widget.items.isEmpty
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('กำลังโหลด...'),
                    ],
                  )
                : const Text('ไม่พบข้อมูล'),
          )
        : ListView.builder(
            shrinkWrap: true,
            itemCount: _filteredItems.length,
            itemBuilder: (context, index) {
              final item = _filteredItems[index];
              final isSelected = item == widget.value;

              return _HoverableListItem(
                isSelected: isSelected,
                onTap: () {
                  widget.onChanged?.call(item);
                  _searchController.text = widget.itemAsString(item);
                  _removeOverlay();
                },
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.itemAsString(item),
                        style: TextStyle(
                          color: isSelected ? Colors.blue[700] : null,
                          fontWeight: isSelected ? FontWeight.w500 : null,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check,
                        color: Colors.blue[700],
                        size: 16,
                      ),
                  ],
                ),
              );
            },
          );
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isOpen = false;
  }

  double _getDropdownWidth() {
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    return renderBox?.size.width ?? 200;
  }

  void _filterItems(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredItems = widget.items;
      } else {
        _filteredItems = widget.items.where((item) {
          final itemText = widget.itemAsString(item).toLowerCase();
          return itemText.contains(query.toLowerCase());
        }).toList();
      }
    });
    
    // Update overlay if it's open
    if (_overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.label != null) ...[
            Text(
              widget.label!,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
          ],
          TextFormField(
            controller: _searchController,
            focusNode: _focusNode,
            enabled: widget.enabled,
            decoration: InputDecoration(
              hintText: widget.hint,
              prefixIcon: widget.prefixIcon,
              suffixIcon: widget.suffixIcon ??
                  (widget.allowClear && widget.value != null
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            widget.onChanged?.call(null);
                            _searchController.clear();
                            _filterItems('');
                            _focusNode.unfocus();
                            _removeOverlay();
                          },
                        )
                      : const Icon(Icons.arrow_drop_down)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
            onChanged: (value) {
              _filterItems(value);
              // When user manually clears the text, reset the selected value
              if (value.isEmpty && widget.value != null) {
                widget.onChanged?.call(null);
              }
            },
            onTap: () {
              if (!_isOpen) {
                _showOverlay();
                _isOpen = true;
              }
            },
            validator: (value) => widget.validator?.call(widget.value),
            readOnly: false,
          ),
        ],
      ),
    );
  }
}

class _HoverableListItem extends StatefulWidget {
  final bool isSelected;
  final VoidCallback onTap;
  final Widget child;

  const _HoverableListItem({
    required this.isSelected,
    required this.onTap,
    required this.child,
  });

  @override
  State<_HoverableListItem> createState() => _HoverableListItemState();
}

class _HoverableListItemState extends State<_HoverableListItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: widget.isSelected 
                ? Colors.blue[50] 
                : _isHovered 
                    ? Colors.grey[100] 
                    : null,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
