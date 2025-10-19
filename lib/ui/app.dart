import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'login_page.dart';
import 'onboarding/onboarding_page.dart';
import 'pets/pets_page.dart';
import 'register_page.dart';

class PetKeeperApp extends ConsumerWidget {
  final String initialRoute;
  const PetKeeperApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PetKeeper Lite',
      initialRoute: initialRoute,
      routes: {
        '/login': (_) => const LoginPage(),
        '/register': (_) => const RegisterPage(),
        '/onboarding': (_) => const OnboardingPage(),
        '/home': (_) => const PetsListPage(),
      },
    );
  }
}
