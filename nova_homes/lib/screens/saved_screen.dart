import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/property.dart';
import '../state/nova_homes_state.dart';
import '../theme/theme.dart';
import '../widgets/adaptive_page.dart';
import '../widgets/property_card.dart';
import 'property_details_screen.dart';

enum _SavedSortMode { recently, rating, price }

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key, required this.onExploreTap});

  final VoidCallback onExploreTap;

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  _SavedSortMode _sortMode = _SavedSortMode.recently;

  @override
  Widget build(BuildContext context) {
    final NovaHomesState state = NovaHomesScope.of(context);
    final List<Property> saved = _sortedSaved(state.savedProperties);

    if (saved.isEmpty) {
      return AdaptivePage(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Icon(
                  Icons.favorite_border,
                  size: 60,
                  color: AppColors.accent,
                ),
                const SizedBox(height: 14),
                Text(
                  'No saved homes yet',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap the heart icon in Explore to save your favorite villas.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    color: const Color(0xFF667085),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: AppColors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: widget.onExploreTap,
                  child: Text(
                    'Explore homes',
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SafeArea(
      child: AdaptivePage(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
          itemCount: saved.length + 2,
          separatorBuilder: (_, int index) => const SizedBox(height: 20),
          itemBuilder: (_, int index) {
            if (index == 0) {
              return Text(
                'Saved',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 44,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              );
            }
            if (index == 1) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: <Widget>[
                    _sortChip('Recent', _SavedSortMode.recently),
                    const SizedBox(width: 8),
                    _sortChip('Top rated', _SavedSortMode.rating),
                    const SizedBox(width: 8),
                    _sortChip('Lowest price', _SavedSortMode.price),
                  ],
                ),
              );
            }

            final Property property = saved[index - 2];
            return TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 260 + ((index - 2) * 40)),
              tween: Tween<double>(begin: 0, end: 1),
              builder: (_, double value, Widget? child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 12 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: PropertyCard(
                property: property,
                isFavorite: true,
                onFavoriteTap: () => state.toggleFavorite(property),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<PropertyDetailsScreen>(
                      builder: (_) => PropertyDetailsScreen(property: property),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _sortChip(String label, _SavedSortMode mode) {
    final bool selected = _sortMode == mode;
    return ChoiceChip(
      selected: selected,
      label: Text(label),
      onSelected: (_) => setState(() => _sortMode = mode),
      labelStyle: GoogleFonts.lato(
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

  List<Property> _sortedSaved(List<Property> items) {
    final List<Property> copy = List<Property>.from(items);
    switch (_sortMode) {
      case _SavedSortMode.recently:
        return copy;
      case _SavedSortMode.rating:
        copy.sort((Property a, Property b) => b.rating.compareTo(a.rating));
        return copy;
      case _SavedSortMode.price:
        copy.sort((Property a, Property b) {
          return _extractNightlyPrice(
            a.price,
          ).compareTo(_extractNightlyPrice(b.price));
        });
        return copy;
    }
  }

  int _extractNightlyPrice(String price) {
    final String numbers = price.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(numbers) ?? 0;
  }
}
