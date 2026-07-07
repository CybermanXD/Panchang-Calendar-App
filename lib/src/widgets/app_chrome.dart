import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_icon_mark.dart';

class AppChrome extends StatelessWidget {
  const AppChrome({required this.child, required this.currentIndex, required this.onIndexChanged, super.key});

  final Widget child;
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<PanchangColors>()!;
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: PanchangTheme.softShadow,
        ),
        child: NavigationBar(
          height: 68,
          selectedIndex: currentIndex,
          backgroundColor: Colors.transparent,
          indicatorColor: Colors.transparent,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: onIndexChanged,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month_rounded), label: 'Calendar'),
            NavigationDestination(icon: Icon(Icons.auto_awesome_outlined), selectedIcon: Icon(Icons.auto_awesome_rounded), label: 'Today'),
            NavigationDestination(icon: Icon(Icons.brightness_5_outlined), selectedIcon: Icon(Icons.brightness_5_rounded), label: 'Panchang'),
            NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings_rounded), label: 'Settings'),
          ],
        ),
      ),
    );
  }
}

class AppPage extends StatelessWidget {
  const AppPage({required this.child, this.trailing, super.key});

  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<PanchangColors>()!;
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(30, 20, 30, 0),
            child: Row(
              children: [
                const AppIconMark(size: 34),
                const SizedBox(width: 16),
                Expanded(child: Text('Panchang Calendar', style: Theme.of(context).textTheme.headlineSmall)),
                IconTheme(data: IconThemeData(color: colors.primary), child: trailing ?? const SizedBox.shrink()),
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
