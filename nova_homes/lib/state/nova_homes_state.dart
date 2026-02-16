import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/booking.dart';
import '../models/conversation.dart';
import '../models/property.dart';
import '../services/firestore_service.dart';

class NovaHomesState extends ChangeNotifier {
  NovaHomesState({FirestoreService? firestoreService})
    : _firestoreService = firestoreService ?? FirestoreService() {
    for (final Property property in mockProperties) {
      _knownPropertiesById[property.id] = property;
    }
    _favoritePropertyIds.add('mock_3');
    _bookings.add(
      Booking(
        id: 'bk_001',
        property: mockProperties.first,
        startDate: DateTime.now().add(const Duration(days: 12)),
        endDate: DateTime.now().add(const Duration(days: 17)),
        guests: 2,
        nightlyRate: 450,
        cleaningFee: 150,
        serviceFee: 300,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    );
    _conversations.addAll(<Conversation>[
      Conversation(
        id: 'cv_001',
        hostName: 'Marta Villa Host',
        propertyTitle: 'Azure Cliffside Villa',
        avatarUrl:
            'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=240&q=80',
        lastMessage: 'Your early check-in has been approved.',
        lastTimestamp: DateTime.now().subtract(const Duration(hours: 2)),
        unreadCount: 2,
      ),
      Conversation(
        id: 'cv_002',
        hostName: 'James Concierge',
        propertyTitle: 'Cliffside Mansion',
        avatarUrl:
            'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=240&q=80',
        lastMessage: 'Do you need airport transfer for your stay?',
        lastTimestamp: DateTime.now().subtract(const Duration(days: 1)),
        unreadCount: 0,
      ),
    ]);
    _syncFavoritesFromCloud();
  }

  final FirestoreService _firestoreService;
  final Set<String> _favoritePropertyIds = <String>{};
  final Map<String, Property> _knownPropertiesById = <String, Property>{};
  final List<String> _recentlyViewedIds = <String>[];
  final List<Booking> _bookings = <Booking>[];
  final List<Conversation> _conversations = <Conversation>[];
  String _profilePhotoUrl = '';
  String _profileDisplayName = '';

  List<Property> get savedProperties {
    final List<String> orderedIds = <String>[
      ..._recentlyViewedIds.where(_favoritePropertyIds.contains),
      ..._favoritePropertyIds.where(
        (String id) => !_recentlyViewedIds.contains(id),
      ),
    ];
    return orderedIds
        .map((String id) => _knownPropertiesById[id])
        .whereType<Property>()
        .toList(growable: false);
  }

  List<Property> get recentlyViewedProperties {
    return _recentlyViewedIds
        .map((String id) => _knownPropertiesById[id])
        .whereType<Property>()
        .toList(growable: false);
  }

  List<Booking> get bookings {
    final List<Booking> copy = List<Booking>.from(_bookings);
    copy.sort((Booking a, Booking b) => b.startDate.compareTo(a.startDate));
    return copy;
  }

  List<Conversation> get conversations {
    final List<Conversation> copy = List<Conversation>.from(_conversations);
    copy.sort(
      (Conversation a, Conversation b) =>
          b.lastTimestamp.compareTo(a.lastTimestamp),
    );
    return copy;
  }

  int get unreadInboxCount => _conversations.fold<int>(
    0,
    (int sum, Conversation conversation) => sum + conversation.unreadCount,
  );
  String get profilePhotoUrlOverride => _profilePhotoUrl;
  String get profileDisplayNameOverride => _profileDisplayName;

  bool isFavorite(Property property) {
    return _favoritePropertyIds.contains(property.id);
  }

  void toggleFavorite(Property property) {
    registerProperties(<Property>[property]);
    final bool isFavoriteNow;
    if (_favoritePropertyIds.contains(property.id)) {
      _favoritePropertyIds.remove(property.id);
      isFavoriteNow = false;
    } else {
      _favoritePropertyIds.add(property.id);
      isFavoriteNow = true;
    }
    notifyListeners();
    _persistFavoriteChange(propertyId: property.id, isFavorite: isFavoriteNow);
  }

  void registerProperties(Iterable<Property> properties) {
    bool changed = false;
    for (final Property property in properties) {
      final Property? existing = _knownPropertiesById[property.id];
      if (existing == null || existing != property) {
        _knownPropertiesById[property.id] = property;
        changed = true;
      }
    }
    if (changed) {
      notifyListeners();
    }
  }

  void recordViewedProperty(Property property) {
    registerProperties(<Property>[property]);
    final String id = property.id;
    if (_recentlyViewedIds.isNotEmpty && _recentlyViewedIds.first == id) {
      return;
    }
    _recentlyViewedIds.remove(id);
    _recentlyViewedIds.insert(0, id);
    if (_recentlyViewedIds.length > 12) {
      _recentlyViewedIds.removeRange(12, _recentlyViewedIds.length);
    }
    notifyListeners();
  }

  void clearRecentlyViewed() {
    if (_recentlyViewedIds.isEmpty) return;
    _recentlyViewedIds.clear();
    notifyListeners();
  }

  void setProfilePhotoUrlOverride(String value) {
    final String normalized = value.trim();
    if (_profilePhotoUrl == normalized) return;
    _profilePhotoUrl = normalized;
    notifyListeners();
  }

  void setProfileDisplayNameOverride(String value) {
    final String normalized = value.trim();
    if (_profileDisplayName == normalized) return;
    _profileDisplayName = normalized;
    notifyListeners();
  }

  Future<void> syncFavoritesFromCloud() async {
    await _syncFavoritesFromCloud();
  }

  void addBooking({
    required Property property,
    required DateTime startDate,
    required DateTime endDate,
    required int guests,
    required int nightlyRate,
    required int cleaningFee,
    required int serviceFee,
  }) {
    _bookings.insert(
      0,
      Booking(
        id: 'bk_${DateTime.now().microsecondsSinceEpoch}',
        property: property,
        startDate: DateUtils.dateOnly(startDate),
        endDate: DateUtils.dateOnly(endDate),
        guests: guests,
        nightlyRate: nightlyRate,
        cleaningFee: cleaningFee,
        serviceFee: serviceFee,
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void removeBooking(String bookingId) {
    _bookings.removeWhere((Booking booking) => booking.id == bookingId);
    notifyListeners();
  }

  void restoreBooking(Booking booking) {
    _bookings.insert(0, booking);
    notifyListeners();
  }

  void markConversationRead(String conversationId) {
    final int index = _conversations.indexWhere(
      (Conversation conversation) => conversation.id == conversationId,
    );
    if (index == -1) return;

    final Conversation current = _conversations[index];
    if (current.unreadCount == 0) return;

    _conversations[index] = current.copyWith(unreadCount: 0);
    notifyListeners();
  }

  void markAllConversationsRead() {
    bool changed = false;
    for (int i = 0; i < _conversations.length; i++) {
      final Conversation current = _conversations[i];
      if (current.unreadCount > 0) {
        _conversations[i] = current.copyWith(unreadCount: 0);
        changed = true;
      }
    }
    if (changed) {
      notifyListeners();
    }
  }

  void sendMessage({required String conversationId, required String text}) {
    final int index = _conversations.indexWhere(
      (Conversation conversation) => conversation.id == conversationId,
    );
    if (index == -1) return;

    final Conversation current = _conversations[index];
    _conversations[index] = current.copyWith(
      lastMessage: text,
      lastTimestamp: DateTime.now(),
    );
    notifyListeners();
  }

  Future<void> _syncFavoritesFromCloud() async {
    try {
      if (Firebase.apps.isEmpty) return;
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final Set<String> cloudIds = await _firestoreService
          .getUserFavoritePropertyIds(user.uid);
      if (cloudIds.isEmpty) return;
      _favoritePropertyIds
        ..clear()
        ..addAll(cloudIds);
      notifyListeners();
    } catch (_) {
      // Keep local defaults for portfolio mode when backend is unavailable.
    }
  }

  Future<void> _persistFavoriteChange({
    required String propertyId,
    required bool isFavorite,
  }) async {
    try {
      if (Firebase.apps.isEmpty) return;
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      if (isFavorite) {
        await _firestoreService.addFavoritePropertyId(user.uid, propertyId);
      } else {
        await _firestoreService.removeFavoritePropertyId(user.uid, propertyId);
      }
    } catch (_) {
      // Silent fallback for demo mode.
    }
  }
}

class NovaHomesScope extends InheritedNotifier<NovaHomesState> {
  const NovaHomesScope({
    super.key,
    required NovaHomesState notifier,
    required super.child,
  }) : super(notifier: notifier);

  static final NovaHomesState _fallbackState = NovaHomesState();

  static NovaHomesState of(BuildContext context) {
    final NovaHomesScope? scope = context
        .dependOnInheritedWidgetOfExactType<NovaHomesScope>();
    return scope?.notifier ?? _fallbackState;
  }
}
