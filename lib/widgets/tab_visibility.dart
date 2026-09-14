import 'package:flutter/material.dart';

/// Exposes which bottom-nav tab is active so embedded screens can refresh
/// PRO status when the user switches tabs.
class TabVisibility extends InheritedWidget {
  final int activeIndex;

  const TabVisibility({
    super.key,
    required this.activeIndex,
    required super.child,
  });

  static TabVisibility? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<TabVisibility>();
  }

  bool isTabActive(int index) => activeIndex == index;

  @override
  bool updateShouldNotify(TabVisibility oldWidget) =>
      oldWidget.activeIndex != activeIndex;
}
