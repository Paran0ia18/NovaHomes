import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/property.dart';
import '../theme/theme.dart';
import 'checkout_screen.dart';

class BookingCalendarScreen extends StatefulWidget {
  const BookingCalendarScreen({super.key, required this.property});

  final Property property;

  @override
  State<BookingCalendarScreen> createState() => _BookingCalendarScreenState();
}

class _BookingCalendarScreenState extends State<BookingCalendarScreen> {
  late final DateTime _firstDay;
  late final DateTime _lastDay;
  late DateTime _focusedDay;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  int _guests = 2;
  RangeSelectionMode _rangeSelectionMode = RangeSelectionMode.toggledOn;

  @override
  void initState() {
    super.initState();
    final DateTime today = DateUtils.dateOnly(DateTime.now());
    _firstDay = DateTime(today.year - 1, 1, 1);
    _lastDay = DateTime(today.year + 3, 12, 31);
    _focusedDay = today;
    _guests = widget.property.guests < 2 ? 1 : 2;
  }

  @override
  Widget build(BuildContext context) {
    final bool hasRange = _rangeStart != null && _rangeEnd != null;
    final int nights = hasRange
        ? _rangeEnd!.difference(_rangeStart!).inDays
        : 0;
    final bool canContinue = hasRange && nights > 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F8F8),
        elevation: 0,
        titleSpacing: 24,
        title: Text(
          'Select Dates',
          style: GoogleFonts.lato(
            fontSize: 38,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(
              Icons.close,
              size: 30,
              color: AppColors.textPrimary,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 16),
              child: TableCalendar<dynamic>(
                firstDay: _firstDay,
                lastDay: _lastDay,
                focusedDay: _focusedDay,
                rangeStartDay: _rangeStart,
                rangeEndDay: _rangeEnd,
                rangeSelectionMode: _rangeSelectionMode,
                enabledDayPredicate: (DateTime day) {
                  final DateTime d = DateUtils.dateOnly(day);
                  return !d.isBefore(_firstDay) && !d.isAfter(_lastDay);
                },
                headerStyle: HeaderStyle(
                  titleCentered: false,
                  formatButtonVisible: false,
                  titleTextStyle: GoogleFonts.lato(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                  leftChevronIcon: const Icon(Icons.chevron_left_rounded),
                  rightChevronIcon: const Icon(Icons.chevron_right_rounded),
                ),
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: GoogleFonts.lato(
                    color: const Color(0xFF98A2B3),
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                  weekendStyle: GoogleFonts.lato(
                    color: const Color(0xFF98A2B3),
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                calendarStyle: CalendarStyle(
                  isTodayHighlighted: false,
                  rangeHighlightColor: const Color(0xFFECE8E3),
                  outsideTextStyle: GoogleFonts.lato(
                    color: const Color(0xFFD0D4DC),
                    fontSize: 16,
                  ),
                  defaultTextStyle: GoogleFonts.lato(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                  weekendTextStyle: GoogleFonts.lato(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                  rangeStartDecoration: const BoxDecoration(
                    color: AppColors.black,
                    shape: BoxShape.circle,
                  ),
                  rangeEndDecoration: const BoxDecoration(
                    color: AppColors.black,
                    shape: BoxShape.circle,
                  ),
                  withinRangeDecoration: const BoxDecoration(
                    color: Color(0xFFECE8E3),
                  ),
                  withinRangeTextStyle: GoogleFonts.lato(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onRangeSelected:
                    (DateTime? start, DateTime? end, DateTime focusedDay) {
                      setState(() {
                        _focusedDay = DateUtils.dateOnly(focusedDay);
                        _rangeSelectionMode = RangeSelectionMode.toggledOn;

                        if (start == null) {
                          _rangeStart = null;
                          _rangeEnd = null;
                          return;
                        }

                        final DateTime normalizedStart = DateUtils.dateOnly(
                          start,
                        );
                        final DateTime? normalizedEnd = end == null
                            ? null
                            : DateUtils.dateOnly(end);

                        if (normalizedEnd != null &&
                            normalizedEnd.isBefore(normalizedStart)) {
                          _rangeStart = normalizedEnd;
                          _rangeEnd = normalizedStart;
                        } else {
                          _rangeStart = normalizedStart;
                          _rangeEnd = normalizedEnd;
                        }
                      });
                    },
                onPageChanged: (DateTime focusedDay) {
                  _focusedDay = DateUtils.dateOnly(focusedDay);
                },
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _rangeStart = null;
                            _rangeEnd = null;
                            _rangeSelectionMode = RangeSelectionMode.toggledOn;
                          });
                        },
                        child: Text(
                          'Clear',
                          style: GoogleFonts.lato(
                            decoration: TextDecoration.underline,
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        hasRange
                            ? '${_fmt(_rangeStart!)} - ${_fmt(_rangeEnd!)} ($nights nights)'
                            : 'Select your stay',
                        style: GoogleFonts.lato(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: hasRange
                              ? AppColors.textPrimary
                              : const Color(0xFF98A2B3),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: <Widget>[
                      Text(
                        'Guests',
                        style: GoogleFonts.lato(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _guests > 1
                            ? () => setState(() => _guests--)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text(
                        '$_guests',
                        style: GoogleFonts.lato(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      IconButton(
                        onPressed: _guests < widget.property.guests
                            ? () => setState(() => _guests++)
                            : null,
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: canContinue
                            ? AppColors.black
                            : Colors.black26,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      onPressed: canContinue
                          ? () {
                              Navigator.of(context).push(
                                MaterialPageRoute<CheckoutScreen>(
                                  builder: (_) => CheckoutScreen(
                                    property: widget.property,
                                    startDate: _rangeStart!,
                                    endDate: _rangeEnd!,
                                    guests: _guests,
                                  ),
                                ),
                              );
                            }
                          : null,
                      child: Text(
                        'Save & Continue',
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
        ],
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
}
