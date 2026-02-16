import 'dart:math';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_stripe/flutter_stripe.dart';

import '../models/property.dart';
import 'firestore_service.dart';

class BookingQuote {
  const BookingQuote({
    required this.bookingId,
    required this.currency,
    required this.nightlyPrice,
    required this.cleaningFee,
    required this.serviceFee,
    required this.totalAmount,
    required this.nights,
    required this.paymentIntentClientSecret,
    required this.paymentIntentId,
  });

  final String bookingId;
  final String currency;
  final int nightlyPrice;
  final int cleaningFee;
  final int serviceFee;
  final int totalAmount;
  final int nights;
  final String paymentIntentClientSecret;
  final String paymentIntentId;

  factory BookingQuote.fromMap(Map<dynamic, dynamic> map) {
    return BookingQuote(
      bookingId: (map['bookingId'] ?? '') as String,
      currency: (map['currency'] ?? 'eur') as String,
      nightlyPrice: (map['nightlyPrice'] as num?)?.toInt() ?? 0,
      cleaningFee: (map['cleaningFee'] as num?)?.toInt() ?? 0,
      serviceFee: (map['serviceFee'] as num?)?.toInt() ?? 0,
      totalAmount: (map['totalAmount'] as num?)?.toInt() ?? 0,
      nights: (map['nights'] as num?)?.toInt() ?? 0,
      paymentIntentClientSecret:
          (map['paymentIntentClientSecret'] ?? '') as String,
      paymentIntentId: (map['paymentIntentId'] ?? '') as String,
    );
  }
}

class BookingPaymentResult {
  const BookingPaymentResult({
    required this.bookingId,
    required this.currency,
    required this.nightlyPrice,
    required this.cleaningFee,
    required this.serviceFee,
    required this.totalAmount,
    required this.nights,
    required this.isDemo,
  });

  final String bookingId;
  final String currency;
  final int nightlyPrice;
  final int cleaningFee;
  final int serviceFee;
  final int totalAmount;
  final int nights;
  final bool isDemo;
}

class BookingPaymentService {
  static const bool useRealPayments = bool.fromEnvironment(
    'USE_REAL_PAYMENTS',
    defaultValue: false,
  );

  BookingPaymentService({
    FirebaseFunctions? functions,
    FirestoreService? firestoreService,
    FirebaseAuth? auth,
  }) : _functionsOverride = functions,
       _firestoreService = firestoreService ?? FirestoreService(),
       _authOverride = auth;

  final FirebaseFunctions? _functionsOverride;
  final FirestoreService _firestoreService;
  final FirebaseAuth? _authOverride;

  FirebaseFunctions get _functions {
    if (_functionsOverride != null) return _functionsOverride;
    if (Firebase.apps.isEmpty) {
      throw Exception(
        'Firebase is not configured. Run flutterfire configure first.',
      );
    }
    return FirebaseFunctions.instanceFor(region: 'europe-west1');
  }

  FirebaseAuth get _auth {
    if (_authOverride != null) return _authOverride;
    if (Firebase.apps.isEmpty) {
      throw Exception(
        'Firebase is not configured. Run flutterfire configure first.',
      );
    }
    return FirebaseAuth.instance;
  }

  Future<BookingQuote> createBookingQuote({
    required String propertyId,
    required DateTime startDate,
    required DateTime endDate,
    required int guests,
  }) async {
    final HttpsCallable callable = _functions.httpsCallable('createBooking');
    final HttpsCallableResult<dynamic> result = await callable
        .call(<String, dynamic>{
          'propertyId': propertyId,
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
          'guests': guests,
        });

    final dynamic data = result.data;
    if (data is! Map<dynamic, dynamic>) {
      throw Exception('Invalid booking response from server.');
    }
    final BookingQuote quote = BookingQuote.fromMap(data);
    if (quote.paymentIntentClientSecret.isEmpty) {
      throw Exception('Payment intent not returned by server.');
    }
    return quote;
  }

  Future<BookingPaymentResult> payAndPersistBooking({
    required Property property,
    required DateTime startDate,
    required DateTime endDate,
    required int guests,
  }) async {
    final int nights = endDate.difference(startDate).inDays;
    if (nights <= 0) {
      throw Exception('Invalid booking dates selected.');
    }

    if (!useRealPayments) {
      return _processDemoBooking(
        property: property,
        startDate: startDate,
        endDate: endDate,
        guests: guests,
        nights: nights,
      );
    }

    final User? user = _auth.currentUser;
    if (user == null) {
      throw Exception('User is not authenticated.');
    }
    if (Stripe.publishableKey.isEmpty) {
      throw Exception(
        'Real payments are not configured. Add STRIPE_PUBLISHABLE_KEY or keep demo mode.',
      );
    }

    final BookingQuote quote = await createBookingQuote(
      propertyId: property.id,
      startDate: startDate,
      endDate: endDate,
      guests: guests,
    );

    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        merchantDisplayName: 'NovaHomes',
        paymentIntentClientSecret: quote.paymentIntentClientSecret,
        style: ThemeMode.light,
        googlePay: const PaymentSheetGooglePay(
          merchantCountryCode: 'ES',
          currencyCode: 'EUR',
          testEnv: true,
        ),
        applePay: const PaymentSheetApplePay(merchantCountryCode: 'ES'),
      ),
    );

    await Stripe.instance.presentPaymentSheet();

    await _firestoreService.createBookingRecord(
      bookingId: quote.bookingId,
      userId: user.uid,
      property: property,
      startDate: startDate,
      endDate: endDate,
      guests: guests,
      nightlyPrice: quote.nightlyPrice,
      cleaningFee: quote.cleaningFee,
      serviceFee: quote.serviceFee,
      totalAmount: quote.totalAmount,
      paymentIntentId: quote.paymentIntentId,
      currency: quote.currency,
    );

    return BookingPaymentResult(
      bookingId: quote.bookingId,
      currency: quote.currency,
      nightlyPrice: quote.nightlyPrice,
      cleaningFee: quote.cleaningFee,
      serviceFee: quote.serviceFee,
      totalAmount: quote.totalAmount,
      nights: quote.nights,
      isDemo: false,
    );
  }

  Future<BookingPaymentResult> _processDemoBooking({
    required Property property,
    required DateTime startDate,
    required DateTime endDate,
    required int guests,
    required int nights,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));

    final int nightlyPrice = property.nightlyPrice;
    const int cleaningFee = 150;
    const int serviceFee = 300;
    final int totalAmount = (nightlyPrice * nights) + cleaningFee + serviceFee;
    final int random = Random().nextInt(999999);
    final String bookingId =
        'demo_${DateTime.now().millisecondsSinceEpoch}_$random';

    if (Firebase.apps.isNotEmpty) {
      final User? user = _auth.currentUser;
      if (user != null) {
        try {
          await _firestoreService.createBookingRecord(
            bookingId: bookingId,
            userId: user.uid,
            property: property,
            startDate: startDate,
            endDate: endDate,
            guests: guests,
            nightlyPrice: nightlyPrice,
            cleaningFee: cleaningFee,
            serviceFee: serviceFee,
            totalAmount: totalAmount,
            paymentIntentId: 'demo_intent_$bookingId',
            currency: 'usd',
          );
        } catch (_) {
          // In portfolio mode we allow booking UI to continue even if Firestore write fails.
        }
      }
    }

    return BookingPaymentResult(
      bookingId: bookingId,
      currency: 'usd',
      nightlyPrice: nightlyPrice,
      cleaningFee: cleaningFee,
      serviceFee: serviceFee,
      totalAmount: totalAmount,
      nights: nights,
      isDemo: true,
    );
  }
}
