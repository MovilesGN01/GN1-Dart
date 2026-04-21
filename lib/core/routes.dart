import 'package:go_router/go_router.dart';
import 'package:uniride/features/auth/login_screen.dart';
import 'package:uniride/features/community/community_screen.dart';
import 'package:uniride/features/home/home_screen.dart';
import 'package:uniride/features/nfc/nfc_access_screen.dart';
import 'package:uniride/features/profile/profile_screen.dart';
import 'package:uniride/features/rides/available_rides_screen.dart';
import 'package:uniride/features/rides/ride_details_screen.dart';
import 'package:uniride/shared/widgets/main_scaffold.dart';

final appRouter = GoRouter(
  initialLocation: '/home',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const LoginScreen(),
    ),

    ShellRoute(
      builder: (context, state, child) => MainScaffold(child: child),
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/rides',
          builder: (context, state) => const AvailableRidesScreen(),
        ),
        GoRoute(
          path: '/community',
          builder: (context, state) => const CommunityScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/nfc',
          builder: (context, state) => const NfcAccessScreen(),
        ),
      ],
    ),

    GoRoute(
      path: '/rides/details/:rideId',
      builder: (context, state) {
        final rideId = state.pathParameters['rideId']!;
        return RideDetailsScreen(rideId: rideId);
      },
    ),
  ],
);