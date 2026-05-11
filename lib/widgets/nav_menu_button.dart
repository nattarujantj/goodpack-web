import 'package:flutter/material.dart';
import 'main_scaffold_scope.dart';

class NavMenuButton extends StatelessWidget {
  const NavMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).size.width >= 1200) return const SizedBox.shrink();
    return IconButton(
      icon: const Icon(Icons.menu),
      onPressed: () => MainScaffoldScope.of(context)?.currentState?.openDrawer(),
    );
  }
}
