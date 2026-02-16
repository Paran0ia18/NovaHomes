import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import 'firebase_options.dart';
import 'screens/auth_gate_screen.dart';
import 'state/nova_homes_state.dart';
import 'theme/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  PaintingBinding.instance.imageCache.maximumSizeBytes = 60 << 20;
  await _initializeThirdPartyServices();
  runApp(const NovaHomesApp());
}

Future<void> _initializeThirdPartyServices() async {
  try {
    if (!DefaultFirebaseOptions.currentPlatform.projectId.contains(
      'REPLACE_',
    )) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } else {
      await Firebase.initializeApp();
    }
  } catch (_) {
    // Firebase may not be configured yet in local env.
  }

  const String stripePublishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
  );
  const String stripeMerchantIdentifier = String.fromEnvironment(
    'STRIPE_MERCHANT_IDENTIFIER',
  );
  if (stripePublishableKey.isNotEmpty) {
    Stripe.publishableKey = stripePublishableKey;
    if (stripeMerchantIdentifier.isNotEmpty) {
      Stripe.merchantIdentifier = stripeMerchantIdentifier;
    }
    await Stripe.instance.applySettings();
  }
}

class NovaHomesApp extends StatefulWidget {
  const NovaHomesApp({super.key});

  @override
  State<NovaHomesApp> createState() => _NovaHomesAppState();
}

class _NovaHomesAppState extends State<NovaHomesApp> {
  late final NovaHomesState _state;

  @override
  void initState() {
    super.initState();
    _state = NovaHomesState();
  }

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NovaHomesScope(
      notifier: _state,
      child: MaterialApp(
        title: 'NovaHomes',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AuthGateScreen(),
      ),
    );
  }
}
