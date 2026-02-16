import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';

import '../models/property.dart';
import '../services/booking_payment_service.dart';
import '../state/nova_homes_state.dart';
import '../theme/theme.dart';
import 'main_shell_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({
    super.key,
    required this.property,
    required this.startDate,
    required this.endDate,
    required this.guests,
  });

  final Property property;
  final DateTime startDate;
  final DateTime endDate;
  final int guests;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  late final TextEditingController _cardController;
  late final TextEditingController _expiryController;
  late final TextEditingController _cvvController;
  late final TextEditingController _zipController;
  final BookingPaymentService _paymentService = BookingPaymentService();
  final bool _useRealPayments = BookingPaymentService.useRealPayments;
  bool _isPaying = false;

  @override
  void initState() {
    super.initState();
    _cardController = TextEditingController(text: '4242 4242 4242 4242');
    _expiryController = TextEditingController(text: '12/28');
    _cvvController = TextEditingController(text: '123');
    _zipController = TextEditingController(text: '90210');
  }

  @override
  void dispose() {
    _cardController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _zipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int nights = widget.endDate.difference(widget.startDate).inDays;
    final int nightly = _extractNightlyPrice(widget.property.price);
    const int cleaningFee = 150;
    const int serviceFee = 300;
    final int subtotal = nightly * nights;
    final int total = subtotal + cleaningFee + serviceFee;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: Text(
          'Confirm and Pay',
          style: GoogleFonts.lato(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 130),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppTheme.cardRadius,
                border: Border.all(color: const Color(0xFFE9E9E9)),
                boxShadow: const <BoxShadow>[AppTheme.subtleShadow],
              ),
              child: Row(
                children: <Widget>[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      width: 104,
                      height: 104,
                      child: Image.network(
                        widget.property.imageUrl,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.low,
                        cacheWidth: 360,
                        errorBuilder: (_, error, stackTrace) =>
                            Container(color: const Color(0xFFD9D9D9)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'VILLA RENTAL',
                          style: GoogleFonts.lato(
                            fontSize: 13,
                            color: AppColors.accent,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.property.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.lato(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF101828),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _metaRow(
                          icon: Icons.calendar_today_outlined,
                          text:
                              '${_fmt(widget.startDate)} - ${_fmt(widget.endDate)}',
                        ),
                        const SizedBox(height: 4),
                        _metaRow(
                          icon: Icons.people_alt_outlined,
                          text: '${widget.guests} guests',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Price Details',
              style: GoogleFonts.lato(
                fontSize: 40,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF101828),
              ),
            ),
            const SizedBox(height: 18),
            _priceRow(
              left: '\$${nightly.toString()} x $nights nights',
              right: _asCurrency(subtotal),
            ),
            const SizedBox(height: 14),
            _priceRow(left: 'Cleaning fee', right: _asCurrency(cleaningFee)),
            const SizedBox(height: 14),
            _priceRow(left: 'Service fee', right: _asCurrency(serviceFee)),
            const SizedBox(height: 14),
            const Divider(color: Color(0xFFE2E2E2)),
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                Text(
                  'Total ',
                  style: GoogleFonts.lato(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF101828),
                  ),
                ),
                Text(
                  '(USD)',
                  style: GoogleFonts.lato(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF8F9094),
                  ),
                ),
                const Spacer(),
                Text(
                  _asCurrency(total),
                  style: GoogleFonts.lato(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF101828),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 34),
            Text(
              'Payment Method',
              style: GoogleFonts.lato(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF101828),
              ),
            ),
            const SizedBox(height: 14),
            _paymentInput(
              hint: 'Card number',
              icon: Icons.credit_card,
              controller: _cardController,
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: _paymentInput(
                    hint: 'MM / YY',
                    controller: _expiryController,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _paymentInput(hint: 'CVV', controller: _cvvController),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _paymentInput(hint: 'Zip Code', controller: _zipController),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 14),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: const Color(0xFF0B163A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: _isPaying ? null : _onPayPressed,
                  child: Text(
                    _isPaying
                        ? (_useRealPayments ? 'Processing...' : 'Reserving...')
                        : (_useRealPayments
                              ? 'Pay ${_asCurrency(total)}  ->'
                              : 'Reserve Demo  ->'),
                    style: GoogleFonts.lato(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _useRealPayments
                    ? 'Secure payment via Stripe'
                    : 'Demo mode: no real charge',
                style: GoogleFonts.lato(
                  fontSize: 14,
                  color: const Color(0xFF9A9A9A),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onPayPressed() async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final NavigatorState navigator = Navigator.of(context);

    final String? validationError = _validatePaymentForm();
    if (validationError != null) {
      messenger.showSnackBar(SnackBar(content: Text(validationError)));
      return;
    }

    setState(() => _isPaying = true);
    try {
      final BookingPaymentResult paymentResult = await _paymentService
          .payAndPersistBooking(
            property: widget.property,
            startDate: widget.startDate,
            endDate: widget.endDate,
            guests: widget.guests,
          );

      if (!mounted) return;
      final NovaHomesState state = NovaHomesScope.of(context);
      state.addBooking(
        property: widget.property,
        startDate: widget.startDate,
        endDate: widget.endDate,
        guests: widget.guests,
        nightlyRate: paymentResult.nightlyPrice,
        cleaningFee: paymentResult.cleaningFee,
        serviceFee: paymentResult.serviceFee,
      );
      HapticFeedback.mediumImpact();

      await showDialog<void>(
        context: navigator.context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text('Payment successful'),
            content: Text(
              _useRealPayments
                  ? 'Your reservation is confirmed for ${_asCurrency(paymentResult.totalAmount)}.\nBooking: ${paymentResult.bookingId.substring(paymentResult.bookingId.length - 6).toUpperCase()}'
                  : 'Demo reservation confirmed for ${_asCurrency(paymentResult.totalAmount)}.\nBooking: ${paymentResult.bookingId.substring(paymentResult.bookingId.length - 6).toUpperCase()}',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('View Trips'),
              ),
            ],
          );
        },
      );
    } on FirebaseFunctionsException catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(error.message ?? 'Server error during booking.'),
        ),
      );
      return;
    } on StripeException catch (error) {
      final String message =
          error.error.message ?? 'Payment was cancelled or failed.';
      messenger.showSnackBar(SnackBar(content: Text(message)));
      return;
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
      return;
    } finally {
      if (mounted) {
        setState(() => _isPaying = false);
      }
    }

    if (!mounted) return;
    navigator.pushAndRemoveUntil(
      MaterialPageRoute<MainShellScreen>(
        builder: (_) => const MainShellScreen(initialIndex: 2),
      ),
      (Route<dynamic> route) => false,
    );
  }

  Widget _metaRow({required IconData icon, required String text}) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 15, color: const Color(0xFF8F8B83)),
        const SizedBox(width: 6),
        Text(
          text,
          style: GoogleFonts.lato(
            fontSize: 15,
            color: const Color(0xFF8F8B83),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _priceRow({required String left, required String right}) {
    return Row(
      children: <Widget>[
        Text(
          left,
          style: GoogleFonts.lato(
            fontSize: 16,
            color: const Color(0xFF757575),
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          right,
          style: GoogleFonts.lato(
            fontSize: 16,
            color: const Color(0xFF757575),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _paymentInput({
    required String hint,
    required TextEditingController controller,
    IconData? icon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: hint == 'CVV' ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: icon == null
            ? null
            : Icon(icon, color: const Color(0xFF9AA0AE)),
        fillColor: const Color(0xFFF5F5F5),
        filled: true,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.black, width: 1),
        ),
      ),
    );
  }

  String? _validatePaymentForm() {
    final String card = _cardController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final String expiry = _expiryController.text.trim();
    final String cvv = _cvvController.text.trim();
    final String zip = _zipController.text.trim();

    if (card.length < 12) {
      return 'Card number looks too short.';
    }
    if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(expiry)) {
      return 'Expiry format should be MM/YY.';
    }
    if (!RegExp(r'^\d{3,4}$').hasMatch(cvv)) {
      return 'CVV must be 3 or 4 digits.';
    }
    if (zip.length < 4) {
      return 'Zip code looks incomplete.';
    }
    return null;
  }

  int _extractNightlyPrice(String price) {
    final String numbers = price.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(numbers) ?? 450;
  }

  String _asCurrency(int amount) {
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
