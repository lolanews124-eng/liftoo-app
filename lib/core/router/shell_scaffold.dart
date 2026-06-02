import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import 'back_navigation.dart';

class ShellScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  final bool isAssistant;

  const ShellScaffold({
    super.key,
    required this.navigationShell,
    required this.isAssistant,
  });

  int get _branchOffset => isAssistant ? 4 : 0;
  int get _localIndex => navigationShell.currentIndex - _branchOffset;

  @override
  Widget build(BuildContext context) {
    if (isAssistant) return _assistantShell(context);
    return _customerShell(context);
  }

  Widget _customerShell(BuildContext context) {
    return TabShellBackScope(
      navigationShell: navigationShell,
      homeBranchIndex: _branchOffset,
      localTabIndex: _localIndex,
      child: Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(bottom: false, child: navigationShell),
      extendBody: true,
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/customer/booking'),
        backgroundColor: AppColors.primary,
        elevation: 4,
        highlightElevation: 6,
        child: const Icon(Icons.add, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        height: 64,
        padding: EdgeInsets.zero,
        notchMargin: 8,
        color: Colors.white,
        elevation: 8,
        shadowColor: Colors.black26,
        surfaceTintColor: Colors.white,
        shape: const CircularNotchedRectangle(),
        clipBehavior: Clip.antiAlias,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(0, Icons.home_rounded, 'Home'),
            _navItem(1, Icons.receipt_long_outlined, 'Bookings'),
            const SizedBox(width: 48),
            _navItem(2, Icons.account_balance_wallet_outlined, 'Wallet'),
            _navItem(3, Icons.person_outline_rounded, 'Profile'),
          ],
        ),
      ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final selected = _localIndex == index;
    return InkWell(
      onTap: () => navigationShell.goBranch(_branchOffset + index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: selected ? AppColors.primary : AppColors.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _assistantShell(BuildContext context) {
    return TabShellBackScope(
      navigationShell: navigationShell,
      homeBranchIndex: _branchOffset,
      localTabIndex: _localIndex,
      child: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(bottom: false, child: navigationShell),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _localIndex,
            onDestinationSelected: (i) => navigationShell.goBranch(_branchOffset + i),
            backgroundColor: Colors.white,
            indicatorColor: AppColors.primaryLight,
            height: 64,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.work_outline),
                selectedIcon: Icon(Icons.work),
                label: 'Jobs',
              ),
              NavigationDestination(
                icon: Icon(Icons.payments_outlined),
                selectedIcon: Icon(Icons.payments),
                label: 'Earnings',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
    );
  }
}
