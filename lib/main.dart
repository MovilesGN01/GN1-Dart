import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uniride/core/routes.dart';
import 'package:uniride/core/theme.dart';
import 'package:uniride/data/repositories/impl/mock_ride_repository.dart';
import 'package:uniride/data/repositories/impl/mock_user_repository.dart';
import 'package:uniride/presentation/viewmodels/auth_viewmodel.dart';
import 'package:uniride/presentation/viewmodels/ride_viewmodel.dart';

void main() {
  runApp(const UniRideApp());
}

class UniRideApp extends StatelessWidget {
  const UniRideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => RideViewModel(MockRideRepository()),
        ),
        ChangeNotifierProvider(
          create: (_) => AuthViewModel(MockUserRepository()),
        ),
      ],
      child: MaterialApp.router(
        title: 'UniRide',
        theme: uniRideTheme,
        routerConfig: appRouter,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
