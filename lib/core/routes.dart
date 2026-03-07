import 'package:go_router/go_router.dart';
import 'package:uniride/features/auth/login_screen.dart';
import 'package:uniride/features/home/home_screen.dart';
import 'package:uniride/features/rides/available_rides_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/rides',
      builder: (context, state) => const AvailableRidesScreen(),
    ),
  ],
);