import 'dart:math';
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
  final bool useBottomSheet;

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
    this.allowClear = true,
    this.prefixIcon,
    this.suffixIcon,
    this.useBottomSheet = false,
  }) : super(key: key);

  @override
  State<SearchableDropdown<T>> createState() => _SearchableDropdownState<T>();
}

class _SearchableDropdownState<T> extends State<SearchableDropdown<T>> {
  late TextEditingController _searchController;
  List<T> _filteredItems = [];
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  final FocusNode _focusNode = FocusNode();
  bool _isTappingItem = false;
  bool _effectiveBottomSheet = false;
  bool _isBottomSheetOpen = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filteredItems = widget.items;
    _focusNode.addListener(_onFocusChange);

    if (widget.value != null) {
      _searchController.text = widget.itemAsString(widget.value!);
    }
  }

  @override
  void didUpdateWidget(SearchableDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

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
      _searchController.clear();
      setState(() {
        _filteredItems = widget.items;
      });
    }

    if (widget.items != oldWidget.items) {
      setState(() {
        if (_searchController.text.isNotEmpty) {
          _filterItems(_searchController.text);
        } else {
          _filteredItems = widget.items;
        }
      });
      _overlayEntry?.markNeedsBuild();
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
      if (!_effectiveBottomSheet) {
        _showOverlay();
      }
    } else if (!_isTappingItem) {
      _removeOverlay();
    }
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final widgetSize = renderBox.size;
    final widgetOffset = renderBox.localToGlobal(Offset.zero);
    final screenHeight = MediaQuery.of(context).size.height;
    final viewInsetsBottom = MediaQuery.of(context).viewInsets.bottom;

    final spaceBelow = screenHeight - viewInsetsBottom - (widgetOffset.dy + widgetSize.height);
    final spaceAbove = widgetOffset.dy;
    const minDropdownHeight = 120.0;
    const maxDropdownHeight = 250.0;

    final showBelow = spaceBelow >= minDropdownHeight || spaceBelow >= spaceAbove;
    final availableSpace = showBelow ? spaceBelow : spaceAbove;
    final effectiveMaxHeight = min(availableSpace - 8, maxDropdownHeight);
    final dropdownOffset = showBelow
        ? Offset(0, widgetSize.height)
        : Offset(0, -(effectiveMaxHeight + 8));
    final dropdownWidth = widgetSize.width;

    _overlayEntry = OverlayEntry(
      builder: (context) => Listener(
        onPointerDown: (_) => _isTappingItem = true,
        onPointerUp: (_) => _isTappingItem = false,
        child: GestureDetector(
          onTap: () {
            _focusNode.unfocus();
            _removeOverlay();
          },
          child: Material(
            color: Colors.transparent,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(color: Colors.transparent),
                ),
                Positioned(
                  width: dropdownWidth,
                  child: CompositedTransformFollower(
                    link: _layerLink,
                    showWhenUnlinked: false,
                    offset: dropdownOffset,
                    child: GestureDetector(
                      onTap: () {},
                      child: Material(
                        elevation: 8,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          constraints: BoxConstraints(maxHeight: effectiveMaxHeight),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: _buildDropdownItems(),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  Widget _buildDropdownItems() {
    if (_filteredItems.isEmpty) {
      return Padding(
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
      );
    }
    return ListView.builder(
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
            _focusNode.unfocus();
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
                Icon(Icons.check, color: Colors.blue[700], size: 16),
            ],
          ),
        );
      },
    );
  }

  void _showBottomSheet() {
    if (_isBottomSheetOpen) return;
    _isBottomSheetOpen = true;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _BottomSheetContent<T>(
        items: widget.items,
        itemAsString: widget.itemAsString,
        selectedValue: widget.value,
        onSelected: (item) {
          widget.onChanged?.call(item);
          setState(() {
            _searchController.text = item != null ? widget.itemAsString(item) : '';
          });
        },
      ),
    ).whenComplete(() => _isBottomSheetOpen = false);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _filterItems(String query) {
    setState(() {
      _filteredItems = query.isEmpty
          ? widget.items
          : widget.items.where((item) {
              return widget.itemAsString(item).toLowerCase().contains(query.toLowerCase());
            }).toList();
    });
    _overlayEntry?.markNeedsBuild();
  }

  @override
  Widget build(BuildContext context) {
    _effectiveBottomSheet =
        widget.useBottomSheet || MediaQuery.of(context).size.width < 600;
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
            readOnly: _effectiveBottomSheet,
            decoration: InputDecoration(
              hintText: widget.hint,
              prefixIcon: widget.prefixIcon,
              suffixIcon: widget.suffixIcon ??
                  (widget.allowClear && _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            widget.onChanged?.call(null);
                            _searchController.clear();
                            _filterItems('');
                            _focusNode.unfocus();
                            _removeOverlay();
                            setState(() {});
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
            onChanged: _effectiveBottomSheet
                ? null
                : (value) {
                    _filterItems(value);
                    if (value.isEmpty && widget.value != null) {
                      widget.onChanged?.call(null);
                    }
                    setState(() {});
                  },
            onTap: () {
              if (_effectiveBottomSheet) {
                _showBottomSheet();
              } else if (_overlayEntry == null) {
                _showOverlay();
              }
            },
            validator: (value) => widget.validator?.call(widget.value),
          ),
        ],
      ),
    );
  }
}

class _BottomSheetContent<T> extends StatefulWidget {
  final List<T> items;
  final String Function(T) itemAsString;
  final T? selectedValue;
  final void Function(T?) onSelected;

  const _BottomSheetContent({
    required this.items,
    required this.itemAsString,
    required this.selectedValue,
    required this.onSelected,
  });

  @override
  State<_BottomSheetContent<T>> createState() => _BottomSheetContentState<T>();
}

class _BottomSheetContentState<T> extends State<_BottomSheetContent<T>> {
  List<T> _filteredItems = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterOptions(String query) {
    setState(() {
      _filteredItems = query.isEmpty
          ? widget.items
          : widget.items.where((item) {
              return widget.itemAsString(item).toLowerCase().contains(query.toLowerCase());
            }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'เลือก',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'ค้นหา...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onChanged: _filterOptions,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _filteredItems.isEmpty
                    ? const Center(child: Text('ไม่พบข้อมูล'))
                    : ListView.builder(
                        itemCount: _filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = _filteredItems[index];
                          final isSelected = item == widget.selectedValue;
                          return ListTile(
                            title: Text(widget.itemAsString(item)),
                            trailing: isSelected
                                ? const Icon(Icons.check, color: Colors.blue)
                                : null,
                            selected: isSelected,
                            selectedTileColor: Colors.blue[50],
                            onTap: () {
                              widget.onSelected(item);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
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