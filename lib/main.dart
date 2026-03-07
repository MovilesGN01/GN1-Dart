import 'package:flutter/material.dart';
import 'package:uniride/core/routes.dart';
import 'package:uniride/core/theme.dart';

void main() {
  runApp(const UniRideApp());
}

class UniRideApp extends StatelessWidget {
  const UniRideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'UniRide',
      theme: uniRideTheme,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}