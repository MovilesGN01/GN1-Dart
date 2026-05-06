import 'package:flutter/material.dart';
import 'package:uniride/shared/widgets/bottom_nav_bar.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Community'),
      ),
      bottomNavigationBar: UniRideBottomNav(currentIndex: 3),
    );
  }
}