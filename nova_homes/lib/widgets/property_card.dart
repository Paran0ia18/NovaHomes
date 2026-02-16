import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/property.dart';
import '../theme/theme.dart';

class PropertyCard extends StatelessWidget {
  const PropertyCard({
    super.key,
    required this.property,
    required this.isFavorite,
    required this.onTap,
    required this.onFavoriteTap,
    this.showSuperhost = false,
  });

  final Property property;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;
  final bool showSuperhost;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppTheme.cardRadius,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Stack(
            children: <Widget>[
              Hero(
                tag: property.imageUrl,
                child: ClipRRect(
                  borderRadius: AppTheme.cardRadius,
                  child: AspectRatio(
                    aspectRatio: 4 / 3,
                    child: Image.network(
                      property.imageUrl,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.low,
                      cacheWidth: 1000,
                      errorBuilder: (_, error, stackTrace) {
                        return Container(color: const Color(0xFFD9D9D9));
                      },
                    ),
                  ),
                ),
              ),
              if (showSuperhost)
                Positioned(
                  left: 14,
                  top: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'SUPERHOST',
                      style: GoogleFonts.lato(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              Positioned(
                right: 14,
                top: 14,
                child: InkWell(
                  onTap: onFavoriteTap,
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.34),
                    ),
                    child: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      size: 20,
                      color: isFavorite ? Colors.redAccent : Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Text(
                  property.title,
                  style: GoogleFonts.lato(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Row(
                children: <Widget>[
                  const Icon(Icons.star, size: 15, color: AppColors.accent),
                  const SizedBox(width: 4),
                  Text(
                    property.rating.toStringAsFixed(1),
                    style: GoogleFonts.lato(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${property.guests} guests - ${property.bedrooms} bedrooms',
            style: GoogleFonts.lato(
              fontSize: 16,
              color: const Color(0xFF667085),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              children: <InlineSpan>[
                TextSpan(
                  text: property.price.split(' / ').first,
                  style: GoogleFonts.lato(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextSpan(
                  text: ' / ${property.price.split(' / ').last}',
                  style: GoogleFonts.lato(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF667085),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
