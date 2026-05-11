import 'package:flutter/material.dart';

class MainScaffoldScope extends InheritedWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;

  const MainScaffoldScope({
    super.key,
    required this.scaffoldKey,
    required super.child,
  });

  static GlobalKey<ScaffoldState>? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MainScaffoldScope>()?.scaffoldKey;

  @override
  bool updateShouldNotify(MainScaffoldScope old) => scaffoldKey != old.scaffoldKey;
}
