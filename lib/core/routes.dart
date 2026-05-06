import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uniride/data/repositories/impl/firebase_ride_repository.dart';
import 'package:uniride/features/auth/login_screen.dart';
import 'package:uniride/features/auth/register_screen.dart';
import 'package:uniride/features/bookings/booking_details_screen.dart';
import 'package:uniride/features/bookings/data/booking_repository.dart';
import 'package:uniride/features/bookings/my_bookings_screen.dart';
import 'package:uniride/features/bookings/viewmodels/booking_details_viewmodel.dart';
import 'package:uniride/features/bookings/viewmodels/my_bookings_viewmodel.dart';
import 'package:uniride/features/community/community_screen.dart';
import 'package:uniride/features/home/home_screen.dart';
import 'package:uniride/features/nfc/nfc_access_screen.dart';
import 'package:uniride/features/profile/profile_screen.dart';
import 'package:uniride/features/rides/available_rides_screen.dart';
import 'package:uniride/features/rides/ride_details_screen.dart';
import 'package:uniride/features/rides/ride_details_viewmodel.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/rides',
      builder: (context, state) => const AvailableRidesScreen(),
    ),
    GoRoute(
      path: '/rides/:rideId',
      builder: (context, state) {
        final rideId = state.pathParameters['rideId']!;
        return ChangeNotifierProvider(
          create: (_) => RideDetailsViewModel(
            FirebaseRideRepository(),
            BookingRepository(),
          )..load(rideId),
          child: RideDetailsScreen(rideId: rideId),
        );
      },
    ),
    GoRoute(
      path: '/bookings',
      builder: (context, state) => ChangeNotifierProvider(
        create: (_) => MyBookingsViewModel(
          BookingRepository(),
          FirebaseRideRepository(),
        ),
        child: const MyBookingsScreen(),
      ),
    ),
    GoRoute(
      path: '/bookings/:bookingId',
      builder: (context, state) {
        final bookingId = state.pathParameters['bookingId']!;
        return ChangeNotifierProvider(
          create: (_) => BookingDetailsViewModel(BookingRepository()),
          child: BookingDetailsScreen(bookingId: bookingId),
        );
      },
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
);
