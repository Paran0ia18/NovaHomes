import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/app_user_profile.dart';
import '../models/property.dart';
import '../services/firestore_service.dart';
import '../state/nova_homes_state.dart';
import '../theme/theme.dart';
import '../widgets/adaptive_page.dart';
import '../widgets/property_card.dart';
import 'property_details_screen.dart';

enum _HomeSortMode { recommended, priceLow, priceHigh, rating, reviews }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<String> _categories = <String>[
    'All',
    'Villas',
    'Beachfront',
    'Cabins',
    'Mansions',
  ];
  final TextEditingController _searchController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();

  int _selectedCategory = 0;
  String _query = '';
  int _maxNightly = 1500;
  int _minGuests = 1;
  bool _onlySuperhost = false;
  bool _requiresPool = false;
  String _city = '';
  _HomeSortMode _sortMode = _HomeSortMode.recommended;
  bool _portfolioQueryMode = false;
  bool _isLoading = true;
  bool _usingCloudData = false;
  String? _loadError;
  List<Property> _sourceProperties = mockProperties;
  int _fetchVersion = 0;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _fetchFromServer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final NovaHomesState state = NovaHomesScope.of(context);
      state.syncFavoritesFromCloud();
    });
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _query = _searchController.text.trim().toLowerCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    final NovaHomesState state = NovaHomesScope.of(context);
    final User? user = Firebase.apps.isNotEmpty
        ? FirebaseAuth.instance.currentUser
        : null;

    return StreamBuilder<AppUserProfile?>(
      stream: user == null
          ? const Stream<AppUserProfile?>.empty()
          : _firestoreService.streamUserProfile(user.uid),
      builder: (BuildContext context, AsyncSnapshot<AppUserProfile?> snapshot) {
        final AppUserProfile? profile = snapshot.data;
        final String localNameOverride = state.profileDisplayNameOverride;
        final String localPhotoOverride = state.profilePhotoUrlOverride;
        final String userDisplayName = profile?.displayName.isNotEmpty == true
            ? (localNameOverride.isNotEmpty
                  ? localNameOverride
                  : profile!.displayName)
            : (user?.displayName ?? user?.email ?? 'Guest');
        final String safePhotoUrl = _safeNetworkUrl(
          localPhotoOverride.isNotEmpty
              ? localPhotoOverride
              : (profile?.photoUrl.isNotEmpty == true
                    ? profile!.photoUrl
                    : (user?.photoURL ?? '')),
        );
        final String userName = _firstName(userDisplayName);
        final List<Property> filteredProperties = _filteredProperties();
        final List<Property> recentlyViewed = state.recentlyViewedProperties;
        final List<_FilterChipData> activeChips = _activeFilterChips();

        return SafeArea(
          child: AdaptivePage(
            child: RefreshIndicator(
              onRefresh: _fetchFromServer,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
                children: <Widget>[
                  Text(
                    'Welcome back, $userName',
                    style: GoogleFonts.lato(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF667085),
                    ),
                  ),
                  Row(
                    children: <Widget>[
                      Text(
                        'Explore',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 46,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 42,
                        height: 42,
                        decoration: const BoxDecoration(
                          color: AppColors.cream,
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child: safePhotoUrl.isNotEmpty
                              ? Image.network(
                                  safePhotoUrl,
                                  fit: BoxFit.cover,
                                  filterQuality: FilterQuality.low,
                                  cacheWidth: 120,
                                  errorBuilder: (_, error, stackTrace) {
                                    return const Center(
                                      child: Icon(
                                        Icons.person,
                                        color: Color(0xFFA1887F),
                                      ),
                                    );
                                  },
                                )
                              : const Icon(
                                  Icons.person,
                                  color: Color(0xFFA1887F),
                                ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: const <BoxShadow>[AppTheme.subtleShadow],
                    ),
                    child: Row(
                      children: <Widget>[
                        const Icon(Icons.search, color: AppColors.textPrimary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            style: GoogleFonts.lato(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              fillColor: Colors.transparent,
                              hintText: 'Where to?',
                              hintStyle: GoogleFonts.lato(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF98A2B3),
                              ),
                            ),
                          ),
                        ),
                        Tooltip(
                          message: 'Open filters',
                          child: InkWell(
                            onTap: _openFilterSheet,
                            borderRadius: BorderRadius.circular(999),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: const Icon(Icons.tune, size: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _summaryText(filteredProperties.length),
                    style: GoogleFonts.lato(
                      fontSize: 13,
                      color: const Color(0xFF98A2B3),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: _usingCloudData
                              ? const Color(0xFFEFF8F3)
                              : AppColors.cream,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: _usingCloudData
                                ? const Color(0xFF9AD6B1)
                                : const Color(0xFFE9DFCA),
                          ),
                        ),
                        child: Text(
                          _usingCloudData ? 'Cloud data' : 'Mock data',
                          style: GoogleFonts.lato(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _usingCloudData
                                ? const Color(0xFF067647)
                                : const Color(0xFF8A6D1D),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_portfolioQueryMode)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF1FF),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: const Color(0xFFC5D6FF)),
                          ),
                          child: Text(
                            'Composite query',
                            style: GoogleFonts.lato(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1849A9),
                            ),
                          ),
                        ),
                      const Spacer(),
                      TextButton(
                        onPressed: _isLoading ? null : _fetchFromServer,
                        child: Text(
                          'Refresh',
                          style: GoogleFonts.lato(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_loadError != null) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(
                      _loadError!,
                      style: GoogleFonts.lato(
                        fontSize: 13,
                        color: const Color(0xFFB42318),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (activeChips.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: activeChips.map(_buildFilterChip).toList(),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 68,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (_, int index) {
                        final bool selected = index == _selectedCategory;
                        return InkWell(
                          onTap: () =>
                              setState(() => _selectedCategory = index),
                          child: Column(
                            children: <Widget>[
                              Icon(
                                _categoryIcon(_categories[index]),
                                color: selected
                                    ? AppColors.textPrimary
                                    : const Color(0xFF98A2B3),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _categories[index],
                                style: GoogleFonts.lato(
                                  fontSize: 14,
                                  color: selected
                                      ? AppColors.textPrimary
                                      : const Color(0xFF98A2B3),
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 6),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                height: 2,
                                width: 28,
                                color: selected
                                    ? AppColors.textPrimary
                                    : Colors.transparent,
                              ),
                            ],
                          ),
                        );
                      },
                      separatorBuilder: (_, int index) =>
                          const SizedBox(width: 22),
                      itemCount: _categories.length,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 34,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: <Widget>[
                        _sortChip('Recommended', _HomeSortMode.recommended),
                        const SizedBox(width: 8),
                        _sortChip('Price low', _HomeSortMode.priceLow),
                        const SizedBox(width: 8),
                        _sortChip('Price high', _HomeSortMode.priceHigh),
                        const SizedBox(width: 8),
                        _sortChip('Top rated', _HomeSortMode.rating),
                        const SizedBox(width: 8),
                        _sortChip('Most reviewed', _HomeSortMode.reviews),
                      ],
                    ),
                  ),
                  if (recentlyViewed.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 20),
                    Row(
                      children: <Widget>[
                        Text(
                          'Recently viewed',
                          style: GoogleFonts.lato(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: state.clearRecentlyViewed,
                          child: Text(
                            'Clear',
                            style: GoogleFonts.lato(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF667085),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 112,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: recentlyViewed.length.clamp(0, 8),
                        separatorBuilder: (_, int index) =>
                            const SizedBox(width: 10),
                        itemBuilder: (_, int index) {
                          final Property property = recentlyViewed[index];
                          return _recentlyViewedCard(
                            property: property,
                            onTap: () => _openProperty(property),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  if (_isLoading)
                    const _HomeSkeleton()
                  else if (filteredProperties.isEmpty)
                    _emptyResultCard()
                  else
                    ListView.separated(
                      itemCount: filteredProperties.length,
                      separatorBuilder: (_, int index) =>
                          const SizedBox(height: 30),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (_, int index) {
                        final Property property = filteredProperties[index];
                        return TweenAnimationBuilder<double>(
                          duration: Duration(milliseconds: 220 + (index * 30)),
                          tween: Tween<double>(begin: 0, end: 1),
                          curve: Curves.easeOutCubic,
                          builder: (_, double value, Widget? child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, 10 * (1 - value)),
                                child: child,
                              ),
                            );
                          },
                          child: PropertyCard(
                            property: property,
                            isFavorite: state.isFavorite(property),
                            showSuperhost: property.rating >= 4.9,
                            onFavoriteTap: () => state.toggleFavorite(property),
                            onTap: () => _openProperty(property),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _summaryText(int count) {
    if (_portfolioQueryMode) {
      return '$count stays - Mallorca - <= \$500 - Pool';
    }
    final String cityPart = _city.trim().isEmpty ? 'Anywhere' : _city.trim();
    final String poolPart = _requiresPool ? ' - Pool' : '';
    final String hostPart = _onlySuperhost ? ' - Superhost' : '';
    final String sortPart = ' - ${_sortLabel(_sortMode)}';
    return '$count stays - $cityPart - <= \$$_maxNightly$poolPart$hostPart$sortPart';
  }

  Future<void> _fetchFromServer() async {
    final int fetchToken = ++_fetchVersion;
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final List<Property> fetched = _portfolioQueryMode
          ? await _firestoreService.runPortfolioCompoundQuery()
          : await _firestoreService.queryProperties(
              city: _city.trim().isEmpty ? null : _city.trim(),
              maxNightlyPrice: _maxNightly < 1500 ? _maxNightly : null,
              requiresPool: _requiresPool,
              sort: _remoteSortMode(_sortMode),
            );
      if (!mounted || fetchToken != _fetchVersion) return;
      final bool hasCloudFilters =
          _portfolioQueryMode ||
          _city.trim().isNotEmpty ||
          _requiresPool ||
          _maxNightly < 1500;
      final bool shouldFallbackToMock = fetched.isEmpty && !hasCloudFilters;
      final List<Property> source = shouldFallbackToMock
          ? mockProperties
          : fetched;
      setState(() {
        _sourceProperties = source;
        _usingCloudData = !shouldFallbackToMock;
        _isLoading = false;
      });
      NovaHomesScope.of(context).registerProperties(source);
    } on FirebaseException catch (error) {
      if (!mounted || fetchToken != _fetchVersion) return;
      setState(() {
        _sourceProperties = mockProperties;
        _usingCloudData = false;
        _isLoading = false;
        _loadError = _firestoreErrorMessage(error);
      });
      NovaHomesScope.of(context).registerProperties(mockProperties);
    } catch (_) {
      if (!mounted || fetchToken != _fetchVersion) return;
      setState(() {
        _sourceProperties = mockProperties;
        _usingCloudData = false;
        _isLoading = false;
        _loadError =
            'Firestore not reachable/configured. Showing mock properties.';
      });
      NovaHomesScope.of(context).registerProperties(mockProperties);
    }
  }

  List<Property> _filteredProperties() {
    final List<Property> filtered = _sourceProperties
        .where((Property property) {
          final String haystack = '${property.title} ${property.location}'
              .toLowerCase();
          final bool matchesQuery = _query.isEmpty || haystack.contains(_query);
          final bool matchesCategory = _matchesCategory(property);
          final bool matchesGuests = property.guests >= _minGuests;
          final bool matchesPrice = property.nightlyPrice <= _maxNightly;
          final bool matchesSuperhost =
              !_onlySuperhost || property.rating >= 4.9;
          final bool matchesPool =
              !_requiresPool || property.amenities.contains('pool');

          return matchesQuery &&
              matchesCategory &&
              matchesGuests &&
              matchesPrice &&
              matchesSuperhost &&
              matchesPool;
        })
        .toList(growable: false);

    switch (_sortMode) {
      case _HomeSortMode.recommended:
        filtered.sort((Property a, Property b) {
          final double scoreA = a.rating * (1 + (a.reviews / 100));
          final double scoreB = b.rating * (1 + (b.reviews / 100));
          return scoreB.compareTo(scoreA);
        });
        break;
      case _HomeSortMode.priceLow:
        filtered.sort(
          (Property a, Property b) => a.nightlyPrice.compareTo(b.nightlyPrice),
        );
        break;
      case _HomeSortMode.priceHigh:
        filtered.sort(
          (Property a, Property b) => b.nightlyPrice.compareTo(a.nightlyPrice),
        );
        break;
      case _HomeSortMode.rating:
        filtered.sort((Property a, Property b) => b.rating.compareTo(a.rating));
        break;
      case _HomeSortMode.reviews:
        filtered.sort(
          (Property a, Property b) => b.reviews.compareTo(a.reviews),
        );
        break;
    }

    return filtered;
  }

  bool _matchesCategory(Property property) {
    final String category = _categories[_selectedCategory];
    final String title = property.title.toLowerCase();
    final String location = property.location.toLowerCase();

    if (category == 'All') return true;
    if (category == 'Villas') return title.contains('villa');
    if (category == 'Beachfront') {
      return location.contains('coast') ||
          location.contains('marina') ||
          title.contains('cliffside');
    }
    if (category == 'Cabins') {
      return title.contains('retreat') || location.contains('forest');
    }
    if (category == 'Mansions') {
      return title.contains('mansion') || property.bedrooms >= 5;
    }
    return true;
  }

  Future<void> _openFilterSheet() async {
    final TextEditingController cityController = TextEditingController(
      text: _city,
    );
    int tempMaxNightly = _maxNightly;
    int tempMinGuests = _minGuests;
    bool tempOnlySuperhost = _onlySuperhost;
    bool tempRequiresPool = _requiresPool;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final double keyboardInset = MediaQuery.of(
              context,
            ).viewInsets.bottom;
            return AnimatedPadding(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: EdgeInsets.fromLTRB(20, 16, 20, 26 + keyboardInset),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Filters',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: cityController,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: 'City (e.g. Mallorca)',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Max nightly price: \$${tempMaxNightly.toInt()}',
                        style: GoogleFonts.lato(fontWeight: FontWeight.w700),
                      ),
                      Slider(
                        value: tempMaxNightly.toDouble(),
                        min: 250,
                        max: 1500,
                        divisions: 25,
                        activeColor: AppColors.black,
                        onChanged: (double value) =>
                            setModalState(() => tempMaxNightly = value.toInt()),
                      ),
                      Row(
                        children: <Widget>[
                          Text(
                            'Min guests',
                            style: GoogleFonts.lato(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: tempMinGuests > 1
                                ? () => setModalState(() => tempMinGuests--)
                                : null,
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          Text(
                            '$tempMinGuests',
                            style: GoogleFonts.lato(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          IconButton(
                            onPressed: tempMinGuests < 16
                                ? () => setModalState(() => tempMinGuests++)
                                : null,
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                        ],
                      ),
                      SwitchListTile(
                        value: tempRequiresPool,
                        activeThumbColor: AppColors.black,
                        activeTrackColor: AppColors.black.withValues(
                          alpha: 0.24,
                        ),
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Requires pool (array query)',
                          style: GoogleFonts.lato(fontWeight: FontWeight.w700),
                        ),
                        onChanged: (bool value) =>
                            setModalState(() => tempRequiresPool = value),
                      ),
                      SwitchListTile(
                        value: tempOnlySuperhost,
                        activeThumbColor: AppColors.black,
                        activeTrackColor: AppColors.black.withValues(
                          alpha: 0.24,
                        ),
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Only superhost homes',
                          style: GoogleFonts.lato(fontWeight: FontWeight.w700),
                        ),
                        onChanged: (bool value) =>
                            setModalState(() => tempOnlySuperhost = value),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: <Widget>[
                          TextButton(
                            onPressed: () async {
                              FocusScope.of(context).unfocus();
                              setState(() {
                                _portfolioQueryMode = false;
                                _city = '';
                                _maxNightly = 1500;
                                _minGuests = 1;
                                _onlySuperhost = false;
                                _requiresPool = false;
                              });
                              Navigator.of(context).pop();
                              await _fetchFromServer();
                            },
                            child: const Text('Reset'),
                          ),
                          const Spacer(),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: AppColors.black,
                            ),
                            onPressed: () async {
                              FocusScope.of(context).unfocus();
                              setState(() {
                                _portfolioQueryMode = false;
                                _city = cityController.text.trim();
                                _maxNightly = tempMaxNightly;
                                _minGuests = tempMinGuests;
                                _onlySuperhost = tempOnlySuperhost;
                                _requiresPool = tempRequiresPool;
                              });
                              Navigator.of(context).pop();
                              await _fetchFromServer();
                            },
                            child: Text(
                              'Apply',
                              style: GoogleFonts.lato(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      TextButton(
                        onPressed: () async {
                          FocusScope.of(context).unfocus();
                          setState(() {
                            _portfolioQueryMode = true;
                            _city = 'Mallorca';
                            _maxNightly = 500;
                            _requiresPool = true;
                            _minGuests = 1;
                            _onlySuperhost = false;
                          });
                          Navigator.of(context).pop();
                          await _fetchFromServer();
                        },
                        child: Text(
                          'Run portfolio query: Mallorca + <=500 + pool',
                          style: GoogleFonts.lato(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    cityController.dispose();
  }

  Widget _emptyResultCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.cardRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: <Widget>[
          const Icon(Icons.search_off_rounded, color: AppColors.textSecondary),
          const SizedBox(height: 8),
          Text(
            'No homes match your filters',
            style: GoogleFonts.lato(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try reducing filters or check if Firestore has matching data.',
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(
              fontSize: 14,
              color: const Color(0xFF667085),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sortChip(String label, _HomeSortMode mode) {
    final bool selected = _sortMode == mode;
    return ChoiceChip(
      selected: selected,
      label: Text(label),
      onSelected: (_) async {
        setState(() => _sortMode = mode);
        await _fetchFromServer();
      },
      labelStyle: GoogleFonts.lato(
        fontSize: 12,
        color: selected ? Colors.white : AppColors.textPrimary,
        fontWeight: FontWeight.w700,
      ),
      backgroundColor: Colors.white,
      selectedColor: AppColors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: const BorderSide(color: AppColors.border),
      ),
    );
  }

  Widget _buildFilterChip(_FilterChipData chip) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            chip.label,
            style: GoogleFonts.lato(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: chip.onRemove,
            child: const Icon(Icons.close, size: 14),
          ),
        ],
      ),
    );
  }

  Widget _recentlyViewedCard({
    required Property property,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 188,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: <Widget>[
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: SizedBox(
                width: 70,
                height: 110,
                child: Image.network(
                  property.imageUrl,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.low,
                  cacheWidth: 320,
                  errorBuilder: (_, error, stackTrace) =>
                      Container(color: const Color(0xFFD9D9D9)),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      property.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.lato(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      property.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.lato(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF667085),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      property.price,
                      style: GoogleFonts.lato(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_FilterChipData> _activeFilterChips() {
    final List<_FilterChipData> chips = <_FilterChipData>[];
    if (_portfolioQueryMode) {
      chips.add(
        _FilterChipData(
          label: 'Portfolio query',
          onRemove: () {
            setState(() {
              _portfolioQueryMode = false;
              _city = '';
              _maxNightly = 1500;
              _requiresPool = false;
            });
            _fetchFromServer();
          },
        ),
      );
    }
    if (_city.trim().isNotEmpty) {
      chips.add(
        _FilterChipData(
          label: 'City: ${_city.trim()}',
          onRemove: () {
            setState(() {
              _portfolioQueryMode = false;
              _city = '';
            });
            _fetchFromServer();
          },
        ),
      );
    }
    if (_requiresPool) {
      chips.add(
        _FilterChipData(
          label: 'Pool',
          onRemove: () {
            setState(() {
              _portfolioQueryMode = false;
              _requiresPool = false;
            });
            _fetchFromServer();
          },
        ),
      );
    }
    if (_onlySuperhost) {
      chips.add(
        _FilterChipData(
          label: 'Superhost',
          onRemove: () => setState(() => _onlySuperhost = false),
        ),
      );
    }
    if (_maxNightly < 1500) {
      chips.add(
        _FilterChipData(
          label: 'Max \$$_maxNightly',
          onRemove: () {
            setState(() {
              _portfolioQueryMode = false;
              _maxNightly = 1500;
            });
            _fetchFromServer();
          },
        ),
      );
    }
    if (_minGuests > 1) {
      chips.add(
        _FilterChipData(
          label: '$_minGuests+ guests',
          onRemove: () => setState(() => _minGuests = 1),
        ),
      );
    }
    return chips;
  }

  void _openProperty(Property property) {
    final NovaHomesState state = NovaHomesScope.of(context);
    state.recordViewedProperty(property);
    Navigator.of(context).push(
      MaterialPageRoute<PropertyDetailsScreen>(
        builder: (_) => PropertyDetailsScreen(property: property),
      ),
    );
  }

  String _sortLabel(_HomeSortMode mode) {
    switch (mode) {
      case _HomeSortMode.recommended:
        return 'Recommended';
      case _HomeSortMode.priceLow:
        return 'Price low';
      case _HomeSortMode.priceHigh:
        return 'Price high';
      case _HomeSortMode.rating:
        return 'Top rated';
      case _HomeSortMode.reviews:
        return 'Most reviewed';
    }
  }

  PropertyRemoteSort _remoteSortMode(_HomeSortMode mode) {
    switch (mode) {
      case _HomeSortMode.recommended:
        return PropertyRemoteSort.none;
      case _HomeSortMode.priceLow:
        return PropertyRemoteSort.priceLow;
      case _HomeSortMode.priceHigh:
        return PropertyRemoteSort.priceHigh;
      case _HomeSortMode.rating:
        return PropertyRemoteSort.rating;
      case _HomeSortMode.reviews:
        return PropertyRemoteSort.none;
    }
  }

  String _firestoreErrorMessage(FirebaseException error) {
    if (error.code == 'failed-precondition') {
      return 'Composite index missing for this query. Create it from the Firebase console and refresh.';
    }
    if (error.code == 'permission-denied') {
      return 'Firestore rules blocked this query for the current user.';
    }
    return 'Firestore unavailable (${error.code}). Showing mock properties.';
  }

  String _firstName(String fullName) {
    final String cleaned = fullName.trim();
    if (cleaned.isEmpty) return 'Guest';
    return cleaned.split(' ').first;
  }

  String _safeNetworkUrl(String raw) {
    final String value = raw.trim();
    if (value.isEmpty) return '';
    final Uri? uri = Uri.tryParse(value);
    final bool valid =
        uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
    return valid ? value : '';
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'All':
        return Icons.explore_outlined;
      case 'Villas':
        return Icons.villa_outlined;
      case 'Beachfront':
        return Icons.beach_access_outlined;
      case 'Cabins':
        return Icons.cabin_outlined;
      case 'Mansions':
        return Icons.castle_outlined;
      default:
        return Icons.home_outlined;
    }
  }
}

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List<Widget>.generate(2, (int index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          height: 250,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: const Color(0xFFF2F2F2),
          ),
        );
      }),
    );
  }
}

class _FilterChipData {
  const _FilterChipData({required this.label, required this.onRemove});

  final String label;
  final VoidCallback onRemove;
}
