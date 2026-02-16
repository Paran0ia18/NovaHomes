import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/app_user_profile.dart';
import '../models/property.dart';

enum PropertyRemoteSort { none, priceLow, priceHigh, rating }

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
    : _firestoreOverride = firestore;

  final FirebaseFirestore? _firestoreOverride;

  FirebaseFirestore get _firestore {
    if (_firestoreOverride != null) return _firestoreOverride;
    if (Firebase.apps.isEmpty) {
      throw Exception(
        'Firebase is not configured. Run flutterfire configure first.',
      );
    }
    return FirebaseFirestore.instance;
  }

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');
  CollectionReference<Map<String, dynamic>> get _properties =>
      _firestore.collection('properties');
  CollectionReference<Map<String, dynamic>> get _bookings =>
      _firestore.collection('bookings');

  Future<void> upsertUserProfile(User user, {String? fallbackName}) async {
    final String displayName = (user.displayName?.trim().isNotEmpty ?? false)
        ? user.displayName!.trim()
        : (fallbackName?.trim().isNotEmpty ?? false)
        ? fallbackName!.trim()
        : (user.email ?? 'Guest');

    final Map<String, dynamic> payload = <String, dynamic>{
      'uid': user.uid,
      'email': user.email ?? '',
      'displayName': displayName,
      'photoUrl': user.photoURL ?? '',
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    };

    await _users.doc(user.uid).set(payload, SetOptions(merge: true));
  }

  Future<void> upsertUserProfileFields({
    required String uid,
    String? email,
    String? displayName,
    String? photoUrl,
  }) async {
    final Map<String, dynamic> payload = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (email != null) payload['email'] = email;
    if (displayName != null) payload['displayName'] = displayName;
    if (photoUrl != null) payload['photoUrl'] = photoUrl;

    await _users.doc(uid).set(payload, SetOptions(merge: true));
  }

  Stream<AppUserProfile?> streamUserProfile(String uid) {
    return _users.doc(uid).snapshots().map((
      DocumentSnapshot<Map<String, dynamic>> doc,
    ) {
      final Map<String, dynamic>? data = doc.data();
      if (data == null) return null;
      return AppUserProfile.fromMap(uid, data);
    });
  }

  Future<Set<String>> getUserFavoritePropertyIds(String uid) async {
    final DocumentSnapshot<Map<String, dynamic>> doc = await _users
        .doc(uid)
        .get();
    final Map<String, dynamic>? data = doc.data();
    if (data == null) return <String>{};
    final List<dynamic> raw =
        (data['favoritePropertyIds'] as List<dynamic>?) ?? <dynamic>[];
    return raw.map((dynamic item) => item.toString()).toSet();
  }

  Future<void> addFavoritePropertyId(String uid, String propertyId) async {
    await _users.doc(uid).set(<String, dynamic>{
      'favoritePropertyIds': FieldValue.arrayUnion(<String>[propertyId]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> removeFavoritePropertyId(String uid, String propertyId) async {
    await _users.doc(uid).set(<String, dynamic>{
      'favoritePropertyIds': FieldValue.arrayRemove(<String>[propertyId]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<List<Property>> queryProperties({
    String? city,
    int? maxNightlyPrice,
    bool requiresPool = false,
    PropertyRemoteSort sort = PropertyRemoteSort.none,
    int limit = 40,
  }) async {
    Query<Map<String, dynamic>> query = _properties;

    if (city != null && city.trim().isNotEmpty) {
      query = query.where('location.city', isEqualTo: city.trim());
    }

    if (maxNightlyPrice != null) {
      query = query.where('nightlyPrice', isLessThanOrEqualTo: maxNightlyPrice);
    }

    if (requiresPool) {
      query = query.where('amenities', arrayContains: 'pool');
    }

    switch (sort) {
      case PropertyRemoteSort.none:
        if (maxNightlyPrice != null) {
          query = query.orderBy('nightlyPrice');
        }
        break;
      case PropertyRemoteSort.priceLow:
        query = query.orderBy('nightlyPrice');
        break;
      case PropertyRemoteSort.priceHigh:
        query = query.orderBy('nightlyPrice', descending: true);
        break;
      case PropertyRemoteSort.rating:
        if (maxNightlyPrice != null) {
          query = query
              .orderBy('nightlyPrice')
              .orderBy('rating', descending: true);
        } else {
          query = query.orderBy('rating', descending: true);
        }
        break;
    }

    query = query.limit(limit);

    final QuerySnapshot<Map<String, dynamic>> result = await query.get();
    return result.docs
        .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
          return Property.fromFirestore(doc);
        })
        .toList(growable: false);
  }

  Future<List<Property>> runPortfolioCompoundQuery({int limit = 20}) async {
    final QuerySnapshot<Map<String, dynamic>> result = await _properties
        .where('location.city', isEqualTo: 'Mallorca')
        .where('nightlyPrice', isLessThanOrEqualTo: 500)
        .where('amenities', arrayContains: 'pool')
        .orderBy('nightlyPrice')
        .limit(limit)
        .get();

    return result.docs
        .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
          return Property.fromFirestore(doc);
        })
        .toList(growable: false);
  }

  Stream<List<Property>> streamFeaturedProperties({int limit = 30}) {
    return _properties
        .orderBy('rating', descending: true)
        .limit(limit)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
          return snapshot.docs
              .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
                return Property.fromFirestore(doc);
              })
              .toList(growable: false);
        });
  }

  Future<void> createBookingRecord({
    required String bookingId,
    required String userId,
    required Property property,
    required DateTime startDate,
    required DateTime endDate,
    required int guests,
    required int nightlyPrice,
    required int cleaningFee,
    required int serviceFee,
    required int totalAmount,
    required String paymentIntentId,
    String currency = 'eur',
  }) async {
    final Map<String, dynamic> payload = <String, dynamic>{
      'bookingId': bookingId,
      'userId': userId,
      'propertyId': property.id,
      'propertyTitle': property.title,
      'propertyImage': property.imageUrl,
      'location': property.geoLocation.toMap(),
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'guests': guests,
      'nightlyPrice': nightlyPrice,
      'cleaningFee': cleaningFee,
      'serviceFee': serviceFee,
      'totalAmount': totalAmount,
      'currency': currency,
      'status': 'paid',
      'paymentIntentId': paymentIntentId,
      'createdAt': FieldValue.serverTimestamp(),
    };

    await _bookings.doc(bookingId).set(payload);
    await _users
        .doc(userId)
        .collection('bookings')
        .doc(bookingId)
        .set(payload, SetOptions(merge: true));
  }
}
