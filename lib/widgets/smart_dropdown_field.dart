import 'package:flutter/material.dart';
import '../services/config_service.dart';

class SmartDropdownField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final String configType; // 'categories' or 'colors'
  final String? Function(String?)? validator;
  final bool enabled;

  const SmartDropdownField({
    Key? key,
    required this.controller,
    required this.label,
    required this.configType,
    this.hint,
    this.validator,
    this.enabled = true,
  }) : super(key: key);

  @override
  State<SmartDropdownField> createState() => _SmartDropdownFieldState();
}

class _SmartDropdownFieldState extends State<SmartDropdownField> {
  List<String> _options = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadOptions();
    // Listen to controller changes
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didUpdateWidget(SmartDropdownField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload options if config type changed
    if (oldWidget.configType != widget.configType) {
      _loadOptions();
    }
    // Update listener if controller changed
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
    }
  }

  Future<void> _loadOptions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final configService = ConfigService();
      if (!configService.isLoaded) {
        await configService.loadConfig();
      }

      setState(() {
        if (widget.configType == 'categories') {
          _options = configService.getCategoryNames();
        } else if (widget.configType == 'colors') {
          _options = configService.getColorNames();
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading options: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: widget.enabled ? _showDropdown : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
              color: widget.enabled ? Colors.white : Colors.grey[100],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.controller.text.isEmpty 
                        ? (widget.hint ?? '') 
                        : widget.controller.text,
                    style: TextStyle(
                      color: widget.controller.text.isEmpty 
                          ? Colors.grey[600] 
                          : Colors.black,
                    ),
                  ),
                ),
                if (_isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
        if (widget.validator != null)
          Builder(
            builder: (context) {
              final error = widget.validator!(widget.controller.text);
              if (error != null) {
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    error,
                    style: TextStyle(
                      color: Colors.red[700],
                      fontSize: 12,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
      ],
    );
  }

  void _showDropdown() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return _DropdownContent(
          options: _options,
          isLoading: _isLoading,
          label: widget.label,
          controller: widget.controller,
          onSelectionChanged: () {
            setState(() {}); // Refresh the field
          },
        );
      },
    );
  }
}

class _DropdownContent extends StatefulWidget {
  final List<String> options;
  final bool isLoading;
  final String label;
  final TextEditingController controller;
  final VoidCallback onSelectionChanged;

  const _DropdownContent({
    Key? key,
    required this.options,
    required this.isLoading,
    required this.label,
    required this.controller,
    required this.onSelectionChanged,
  }) : super(key: key);

  @override
  State<_DropdownContent> createState() => _DropdownContentState();
}

class _DropdownContentState extends State<_DropdownContent> {
  List<String> _filteredOptions = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredOptions = widget.options;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterOptions(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredOptions = widget.options;
      } else {
        _filteredOptions = widget.options.where((option) {
          return option.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'เลือก${widget.label.replaceAll('*', '').trim()}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Search field
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'ค้นหา...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: _filterOptions,
          ),
          const SizedBox(height: 16),
          
          // Options list
          Expanded(
            child: widget.isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredOptions.isEmpty
                    ? const Center(
                        child: Text('ไม่พบข้อมูล'),
                      )
                    : ListView.builder(
                        itemCount: _filteredOptions.length,
                        itemBuilder: (context, index) {
                          final option = _filteredOptions[index];
                          final isSelected = widget.controller.text == option;
                          
                          return ListTile(
                            title: Text(option),
                            trailing: isSelected 
                                ? const Icon(Icons.check, color: Colors.blue)
                                : null,
                            selected: isSelected,
                            selectedTileColor: Colors.blue[50],
                            onTap: () {
                              widget.controller.text = option;
                              Navigator.pop(context);
                              widget.onSelectionChanged();
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
