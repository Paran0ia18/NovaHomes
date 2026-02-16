import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/property.dart';
import '../state/nova_homes_state.dart';
import '../theme/theme.dart';
import 'booking_calendar_screen.dart';

class PropertyDetailsScreen extends StatefulWidget {
  const PropertyDetailsScreen({super.key, required this.property});

  final Property property;

  @override
  State<PropertyDetailsScreen> createState() => _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState extends State<PropertyDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      NovaHomesScope.of(context).recordViewedProperty(widget.property);
    });
  }

  @override
  Widget build(BuildContext context) {
    final Property property = widget.property;
    final NovaHomesState state = NovaHomesScope.of(context);
    final bool isFavorite = state.isFavorite(property);

    return Scaffold(
      body: Stack(
        children: <Widget>[
          Column(
            children: <Widget>[
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.52,
                width: double.infinity,
                child: Hero(
                  tag: property.imageUrl,
                  child: Image.network(
                    property.imageUrl,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.low,
                    cacheWidth: 1400,
                    errorBuilder: (_, error, stackTrace) {
                      return Container(color: const Color(0xFFD9D9D9));
                    },
                  ),
                ),
              ),
            ],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: <Widget>[
                  _CircleTopAction(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                  _CircleTopAction(icon: Icons.share_outlined, onTap: () {}),
                  const SizedBox(width: 10),
                  _CircleTopAction(
                    icon: isFavorite ? Icons.favorite : Icons.favorite_border,
                    iconColor: isFavorite
                        ? Colors.redAccent
                        : AppColors.background,
                    onTap: () => state.toggleFavorite(property),
                  ),
                ],
              ),
            ),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.47,
            minChildSize: 0.47,
            maxChildSize: 0.86,
            builder: (BuildContext context, ScrollController controller) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 110),
                  children: <Widget>[
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5E7EB),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      property.title,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 41,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: <Widget>[
                        const Icon(
                          Icons.star,
                          color: AppColors.accent,
                          size: 18,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${property.rating} (${property.reviews} reviews)',
                          style: GoogleFonts.lato(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.cream,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.accent.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            'SUPERHOST',
                            style: GoogleFonts.lato(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFB38B1D),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: AppColors.border),
                    const SizedBox(height: 20),
                    Text(
                      'About this space',
                      style: GoogleFonts.lato(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      property.description,
                      style: GoogleFonts.lato(
                        fontSize: 17,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF5E6067),
                      ),
                    ),
                    const SizedBox(height: 26),
                    Text(
                      'What this place offers',
                      style: GoogleFonts.lato(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: property.amenities.length.clamp(0, 6),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 14,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.3,
                          ),
                      itemBuilder: (_, int index) {
                        final String amenity = property.amenities[index];
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFE6E6E6),
                                ),
                              ),
                              child: Icon(
                                _amenityIcon(amenity),
                                size: 22,
                                color: const Color(0xFF7A7A7A),
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              amenity,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.lato(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF666666),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Where you\'ll be',
                      style: GoogleFonts.lato(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Stack(
                      children: <Widget>[
                        ClipRRect(
                          borderRadius: AppTheme.cardRadius,
                          child: SizedBox(
                            height: 180,
                            width: double.infinity,
                            child: Image.network(
                              'https://images.unsplash.com/photo-1613395877344-13d4a8e0d49e?auto=format&fit=crop&w=1200&q=80',
                              fit: BoxFit.cover,
                              filterQuality: FilterQuality.low,
                              cacheWidth: 1000,
                              errorBuilder: (_, error, stackTrace) {
                                return Container(
                                  color: const Color(0xFFD9D9D9),
                                );
                              },
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              children: <Widget>[
                                Text(
                                  'Open map',
                                  style: GoogleFonts.lato(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.open_in_new, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      property.location,
                      style: GoogleFonts.lato(
                        fontSize: 17,
                        color: const Color(0xFF6C6E73),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          height: 92,
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Color(0x11000000),
                blurRadius: 14,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      property.price,
                      style: GoogleFonts.lato(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Oct 15 - Oct 20',
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 140,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<BookingCalendarScreen>(
                        builder: (_) =>
                            BookingCalendarScreen(property: property),
                      ),
                    );
                  },
                  child: Text(
                    'Reserve',
                    style: GoogleFonts.lato(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _amenityIcon(String amenity) {
    final String normalized = amenity.toLowerCase();
    if (normalized.contains('wifi')) return Icons.wifi_rounded;
    if (normalized.contains('pool')) return Icons.pool_outlined;
    if (normalized.contains('kitchen')) return Icons.kitchen_outlined;
    if (normalized.contains('ac')) return Icons.ac_unit_outlined;
    if (normalized.contains('gym')) return Icons.fitness_center_outlined;
    if (normalized.contains('parking')) return Icons.local_parking_outlined;
    if (normalized.contains('concierge')) return Icons.room_service_outlined;
    if (normalized.contains('cinema')) return Icons.movie_outlined;
    if (normalized.contains('sauna')) return Icons.spa_outlined;
    if (normalized.contains('workspace')) return Icons.work_outline;
    return Icons.check_circle_outline;
  }
}

class _CircleTopAction extends StatelessWidget {
  const _CircleTopAction({
    required this.icon,
    required this.onTap,
    this.iconColor = AppColors.background,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.28),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, size: 20, color: iconColor),
        ),
      ),
    );
  }
}
