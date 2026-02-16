import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/booking.dart';
import '../state/nova_homes_state.dart';
import '../theme/theme.dart';
import '../widgets/adaptive_page.dart';
import 'property_details_screen.dart';

class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key, required this.onExploreTap});

  final VoidCallback onExploreTap;

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  bool _showOnlyUpcoming = true;

  @override
  Widget build(BuildContext context) {
    final NovaHomesState state = NovaHomesScope.of(context);
    final DateTime today = DateUtils.dateOnly(DateTime.now());
    final List<Booking> bookings = state.bookings
        .where((Booking booking) {
          if (!_showOnlyUpcoming) return true;
          return !DateUtils.dateOnly(booking.endDate).isBefore(today);
        })
        .toList(growable: false);

    if (bookings.isEmpty) {
      return AdaptivePage(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Icon(
                  Icons.flight_takeoff,
                  size: 60,
                  color: AppColors.accent,
                ),
                const SizedBox(height: 14),
                Text(
                  'No trips booked',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Reserve your first luxury stay and it will appear here.',
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
                    'Find properties',
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
          itemCount: bookings.length + 2,
          separatorBuilder: (_, int index) => const SizedBox(height: 14),
          itemBuilder: (_, int index) {
            if (index == 0) {
              return Row(
                children: <Widget>[
                  Text(
                    'Trips',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 44,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  FilterChip(
                    selected: _showOnlyUpcoming,
                    onSelected: (bool value) =>
                        setState(() => _showOnlyUpcoming = value),
                    label: const Text('Upcoming only'),
                    selectedColor: AppColors.cream,
                    labelStyle: GoogleFonts.lato(fontWeight: FontWeight.w700),
                  ),
                ],
              );
            }
            if (index == 1) {
              return Text(
                '${bookings.length} reservations',
                style: GoogleFonts.lato(
                  fontSize: 14,
                  color: const Color(0xFF667085),
                  fontWeight: FontWeight.w600,
                ),
              );
            }

            final Booking booking = bookings[index - 2];
            return TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 240 + ((index - 2) * 30)),
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
              child: _tripCard(context, booking, state),
            );
          },
        ),
      ),
    );
  }

  Widget _tripCard(
    BuildContext context,
    Booking booking,
    NovaHomesState state,
  ) {
    final bool isPastTrip = DateUtils.dateOnly(
      booking.endDate,
    ).isBefore(DateUtils.dateOnly(DateTime.now()));
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.cardRadius,
        border: Border.all(color: const Color(0xFFE9E9E9)),
        boxShadow: const <BoxShadow>[AppTheme.subtleShadow],
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 96,
                  height: 96,
                  child: Image.network(
                    booking.property.imageUrl,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.low,
                    cacheWidth: 320,
                    errorBuilder: (_, error, stackTrace) {
                      return Container(color: const Color(0xFFD9D9D9));
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      booking.property.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.lato(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF101828),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${_fmt(booking.startDate)} - ${_fmt(booking.endDate)}',
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        color: const Color(0xFF667085),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${booking.guests} guests - ${booking.nights} nights',
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        color: const Color(0xFF667085),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _currency(booking.total),
                      style: GoogleFonts.lato(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isPastTrip ? const Color(0xFFECEFF3) : AppColors.cream,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  isPastTrip ? 'Completed' : 'Upcoming',
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    color: isPastTrip
                        ? const Color(0xFF667085)
                        : const Color(0xFFB38B1D),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<PropertyDetailsScreen>(
                      builder: (_) =>
                          PropertyDetailsScreen(property: booking.property),
                    ),
                  );
                },
                child: Text(
                  'View home',
                  style: GoogleFonts.lato(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (!isPastTrip)
                TextButton(
                  onPressed: () => _cancelBooking(booking, state),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.lato(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFB42318),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _cancelBooking(Booking booking, NovaHomesState state) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancel this reservation?'),
          content: Text(
            'This will remove your stay at ${booking.property.title} from Trips.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Keep'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Cancel trip'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    state.removeBooking(booking.id);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Trip cancelled: ${booking.property.title}'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => state.restoreBooking(booking),
        ),
      ),
    );
  }

  String _fmt(DateTime date) {
    const List<String> months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  String _currency(int amount) {
    final String raw = amount.toString();
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < raw.length; i++) {
      final int reverseIndex = raw.length - i;
      buffer.write(raw[i]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write(',');
      }
    }
    return '\$$buffer';
  }
}
