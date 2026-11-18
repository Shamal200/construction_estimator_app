
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'providers/app_navigation_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/email_verification_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/business/business_onboarding_screen.dart';
import 'screens/business/business_selection_screen.dart';
import 'screens/board_calculator_screen.dart';
import 'screens/customers_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/estimates_screen.dart';
import 'screens/invoices_screen.dart';
import 'screens/materials_screen.dart';
import 'screens/quotations_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'services/business_service.dart';
import 'widgets/responsive_scaffold.dart';

class ConstructionEstimatorApp extends StatelessWidget {
  const ConstructionEstimatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AppNavigationProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => AuthProvider()..initialize(),
        ),
        Provider(
          create: (_) => BusinessService(),
        ),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const AuthGate(),
        routes: {
          '/business-onboarding': (_) =>
              const BusinessOnboardingScreen(),
          '/business-selection': (_) =>
              const BusinessSelectionScreen(),
        },
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.isLoading) {
      return const SplashScreen();
    }

    if (auth.user == null) {
      return const LoginScreen();
    }

    if (auth.user != null && !auth.user!.emailVerified) {
      return const EmailVerificationScreen();
    }

    if (!auth.hasBusiness) {
      return const BusinessOnboardingScreen();
    }

    if (!auth.hasActiveBusiness) {
      return const BusinessSelectionScreen();
    }

    return const AppShell();
  }
}

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    final navigation = context.watch<AppNavigationProvider>();
    final auth = context.watch<AuthProvider>();

    final screens = <Widget>[
      const DashboardScreen(),
      const CustomersScreen(),
      const QuotationsScreen(),
      const InvoicesScreen(),
      const EstimatesScreen(),
      const MaterialsScreen(),
      const SettingsScreen(),
      const BoardCalculatorScreen(),
    ];

    final destinations = const <NavigationDestination>[
      NavigationDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard),
        label: 'Dashboard',
      ),
      NavigationDestination(
        icon: Icon(Icons.people_outline),
        selectedIcon: Icon(Icons.people),
        label: 'Customers',
      ),
      NavigationDestination(
        icon: Icon(Icons.receipt_long_outlined),
        selectedIcon: Icon(Icons.receipt_long),
        label: 'Quotations',
      ),
      NavigationDestination(
        icon: Icon(Icons.request_quote_outlined),
        selectedIcon: Icon(Icons.request_quote),
        label: 'Invoices',
      ),
      NavigationDestination(
        icon: Icon(Icons.calculate_outlined),
        selectedIcon: Icon(Icons.calculate),
        label: 'Estimates',
      ),
      NavigationDestination(
        icon: Icon(Icons.inventory_2_outlined),
        selectedIcon: Icon(Icons.inventory_2),
        label: 'Materials',
      ),
      NavigationDestination(
        icon: Icon(Icons.settings_outlined),
        selectedIcon: Icon(Icons.settings),
        label: 'Settings',
      ),
      NavigationDestination(
        icon: Icon(Icons.view_quilt_outlined),
        selectedIcon: Icon(Icons.view_quilt),
        label: 'Board Calculator',
      ),
    ];

    final selectedIndex = navigation.selectedIndex
        .clamp(0, destinations.length - 1);

    final title =
        auth.activeBusiness?.name ??
        destinations[selectedIndex].label;

    return ResponsiveScaffold(
      title: title,
      selectedIndex: selectedIndex,
      destinations: destinations,
      onDestinationSelected: navigation.setIndex,
      body: screens[selectedIndex],
      actions: [
        IconButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    const BusinessSelectionScreen(),
              ),
            );
          },
          tooltip: 'Switch business',
          icon: const Icon(Icons.swap_horiz),
        ),
        IconButton(
          onPressed: () async {
            await context.read<AuthProvider>().signOut();
          },
          tooltip: 'Sign out',
          icon: const Icon(Icons.logout),
        ),
      ],
    );
  }
}
