import 'package:flutter/material.dart';

import 'budget_screen.dart';

import 'home_screen.dart';

/// Shown right after login.

/// Teammates can add their tabs (Expenses, Summary, ...) to _pages

/// and _destinations below. Keep both lists in the same order.

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _index = 0; // 0 = Home, shows first after login

  late final List<Widget> _pages = [
    HomeScreen(onOpenBudget: _openBudget),
    const BudgetScreen(),
  ];

  final List<NavigationDestination> _destinations = const [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),

      selectedIcon: Icon(Icons.home_rounded),

      label: 'Home',
    ),

    NavigationDestination(
      icon: Icon(Icons.account_balance_wallet_outlined),

      selectedIcon: Icon(Icons.account_balance_wallet_rounded),

      label: 'Budget',
    ),
  ];

  void _openBudget() {
    setState(() => _index = 1);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),

      bottomNavigationBar: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            border: Border(top: BorderSide(color: scheme.outlineVariant)),
          ),
          child: NavigationBar(
            selectedIndex: _index,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: _destinations,
          ),
        ),
      ),
    );
  }
}
