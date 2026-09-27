import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'providers/app_navigation_provider.dart';
import 'screens/customers_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/estimates_screen.dart';
import 'screens/materials_screen.dart';
import 'screens/quotations_screen.dart';
import 'screens/settings_screen.dart';
import 'widgets/responsive_scaffold.dart';

class ConstructionEstimatorApp extends StatelessWidget {
  const ConstructionEstimatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppNavigationProvider(),
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const AppShell(),
      ),
    );
  }
}

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    final navigation = context.watch<AppNavigationProvider>();
    final screens = <Widget>[
      const DashboardScreen(),
      const CustomersScreen(),
      const QuotationsScreen(),
      const EstimatesScreen(),
      const MaterialsScreen(),
      const SettingsScreen(),
    ];

    final destinations = const <NavigationDestination>[
      NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
      NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Customers'),
      NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Quotations'),
      NavigationDestination(icon: Icon(Icons.calculate_outlined), selectedIcon: Icon(Icons.calculate), label: 'Estimates'),
      NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: 'Materials'),
      NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
    ];

    return ResponsiveScaffold(
      title: destinations[navigation.selectedIndex].label,
      selectedIndex: navigation.selectedIndex,
      destinations: destinations,
      onDestinationSelected: navigation.setIndex,
      body: screens[navigation.selectedIndex],
    );
  }
}
