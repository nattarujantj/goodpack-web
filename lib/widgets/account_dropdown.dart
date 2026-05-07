import 'package:flutter/material.dart';
import '../services/config_service.dart';
import 'searchable_dropdown.dart';

class AccountDropdown extends StatefulWidget {
  final String? selectedAccountId;
  final ValueChanged<String?> onChanged;
  final String label;
  final bool isRequired;

  const AccountDropdown({
    super.key,
    this.selectedAccountId,
    required this.onChanged,
    this.label = 'บัญชี *',
    this.isRequired = true,
  });

  @override
  State<AccountDropdown> createState() => _AccountDropdownState();
}

class _AccountDropdownState extends State<AccountDropdown> {
  List<AccountItem> _accounts = [];
  AccountItem? _selectedAccount;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  @override
  void didUpdateWidget(AccountDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedAccountId != widget.selectedAccountId) {
      setState(() {
        _syncSelectedAccount();
      });
    }
  }

  Future<void> _loadAccounts() async {
    final configService = ConfigService();
    if (!configService.isLoaded) {
      await configService.loadConfig();
    }
    if (mounted) {
      setState(() {
        _accounts = configService.accounts;
        _syncSelectedAccount();
      });
    }
  }

  void _syncSelectedAccount() {
    if (widget.selectedAccountId == null) {
      _selectedAccount = null;
      return;
    }
    try {
      _selectedAccount = _accounts.firstWhere((a) => a.id == widget.selectedAccountId);
    } catch (_) {
      _selectedAccount = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SearchableDropdown<AccountItem>(
      label: widget.label,
      value: _selectedAccount,
      items: _accounts,
      itemAsString: (account) => account.displayName,
      hint: 'เลือกบัญชี',
      onChanged: (account) {
        setState(() {
          _selectedAccount = account;
        });
        widget.onChanged(account?.id);
      },
      validator: widget.isRequired
          ? (account) => account == null ? 'กรุณาเลือกบัญชี' : null
          : null,
    );
  }
}