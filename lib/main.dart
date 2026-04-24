import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/firebase_options.dart';
import 'core/routes.dart';
import 'core/theme.dart';
import 'data/repositories/impl/firebase_auth_repository.dart';
import 'data/repositories/impl/firebase_ride_repository.dart';
import 'data/repositories/impl/open_meteo_repository.dart';
import 'features/auth/auth_viewmodel.dart';
import 'features/chatbot/data/chatbot_service.dart';
import 'features/chatbot/state/chatbot_controller.dart';
import 'features/home/weather_viewmodel.dart';
import 'features/rides/ride_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => RideViewModel(FirebaseRideRepository()),
        ),
        ChangeNotifierProvider(
          create: (_) => AuthViewModel(FirebaseAuthRepository()),
        ),
        ChangeNotifierProvider(
          create: (_) => WeatherViewModel(OpenMeteoRepository()),
        ),
        ChangeNotifierProvider(
          create: (_) => ChatbotController(ChatbotService()),
        ),
      ],
      child: const UniRideApp(),
    ),
  );
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
