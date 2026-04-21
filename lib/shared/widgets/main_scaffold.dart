import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uniride/shared/widgets/bottom_nav_bar.dart';

class MainScaffold extends StatelessWidget {
  final Widget child;

  const MainScaffold({
    super.key,
    required this.child,
  });

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();

    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/rides')) return 1;
    if (location.startsWith('/community')) return 2;

    if (location.startsWith('/profile') || location.startsWith('/nfc')) return 3;

    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final index = _currentIndex(context);

    return Scaffold(
      body: SafeArea(child: child),
      bottomNavigationBar: UniRideBottomNav(
        currentIndex: index,
      ),
    );
  }
}