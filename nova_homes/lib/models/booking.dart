import 'property.dart';

class Booking {
  const Booking({
    required this.id,
    required this.property,
    required this.startDate,
    required this.endDate,
    required this.guests,
    required this.nightlyRate,
    required this.cleaningFee,
    required this.serviceFee,
    required this.createdAt,
  });

  final String id;
  final Property property;
  final DateTime startDate;
  final DateTime endDate;
  final int guests;
  final int nightlyRate;
  final int cleaningFee;
  final int serviceFee;
  final DateTime createdAt;

  int get nights => endDate.difference(startDate).inDays;
  int get subtotal => nightlyRate * nights;
  int get total => subtotal + cleaningFee + serviceFee;
}
