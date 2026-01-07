import 'package:cloud_firestore/cloud_firestore.dart';

enum BookingStatus {
  pending,
  confirmed,
  awaitingConfirmation,
  completed,
  cancelled,
}

class Booking {
  final String id;
  final String ownerId;
  final String walkerId;
  final String ownerName;
  final String walkerName;
  final String dogName;
  final DateTime date;
  final String time;
  final int duration; // in minutes
  final String location;
  final double? latitude;  // Pickup location latitude
  final double? longitude; // Pickup location longitude
  final double price;
  final BookingStatus status;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<String>? services; // List of service names
  final Map<String, dynamic>? serviceDetails; // {serviceName: {duration: 60, price: 25}}
  final String? recurringBookingId; // Reference to parent recurring booking
  final bool isRecurring; // Whether this booking is part of a recurring series
  final DateTime? completedByWalkerAt; // When walker marked complete
  final DateTime? confirmedByOwnerAt; // When owner confirmed completion
  final bool? paymentProcessed; // Payment settlement completed
  final String? transactionId; // Reference to transaction record
  final String? stripePaymentIntentId; // Stripe payment intent ID for tracking

  Booking({
    required this.id,
    required this.ownerId,
    required this.walkerId,
    required this.ownerName,
    required this.walkerName,
    required this.dogName,
    required this.date,
    required this.time,
    required this.duration,
    required this.location,
    this.latitude,
    this.longitude,
    required this.price,
    required this.status,
    this.notes,
    required this.createdAt,
    this.updatedAt,
    this.services,
    this.serviceDetails,
    this.recurringBookingId,
    this.isRecurring = false,
    this.completedByWalkerAt,
    this.confirmedByOwnerAt,
    this.paymentProcessed,
    this.transactionId,
    this.stripePaymentIntentId,
  });

  factory Booking.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Booking(
      id: doc.id,
      ownerId: data['ownerId'] ?? '',
      walkerId: data['walkerId'] ?? '',
      ownerName: data['ownerName'] ?? '',
      walkerName: data['walkerName'] ?? '',
      dogName: data['dogName'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      time: data['time'] ?? '',
      duration: data['duration'] ?? 30,
      location: data['location'] ?? '',
      latitude: data['latitude'] as double?,
      longitude: data['longitude'] as double?,
      price: (data['price'] ?? 0).toDouble(),
      status: BookingStatus.values.firstWhere(
        (e) => e.toString() == 'BookingStatus.${data['status']}',
        orElse: () => BookingStatus.pending,
      ),
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      services: data['services'] != null ? List<String>.from(data['services']) : null,
      serviceDetails: data['serviceDetails'] != null
          ? Map<String, dynamic>.from(data['serviceDetails'])
          : null,
      recurringBookingId: data['recurringBookingId'],
      isRecurring: data['isRecurring'] ?? false,
      completedByWalkerAt: (data['completedByWalkerAt'] as Timestamp?)?.toDate(),
      confirmedByOwnerAt: (data['confirmedByOwnerAt'] as Timestamp?)?.toDate(),
      paymentProcessed: data['paymentProcessed'],
      transactionId: data['transactionId'],
      stripePaymentIntentId: data['stripePaymentIntentId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'ownerId': ownerId,
      'walkerId': walkerId,
      'ownerName': ownerName,
      'walkerName': walkerName,
      'dogName': dogName,
      'date': Timestamp.fromDate(date),
      'time': time,
      'duration': duration,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'price': price,
      'status': status.toString().split('.').last,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'services': services,
      'serviceDetails': serviceDetails,
      'recurringBookingId': recurringBookingId,
      'isRecurring': isRecurring,
      'completedByWalkerAt': completedByWalkerAt != null ? Timestamp.fromDate(completedByWalkerAt!) : null,
      'confirmedByOwnerAt': confirmedByOwnerAt != null ? Timestamp.fromDate(confirmedByOwnerAt!) : null,
      'paymentProcessed': paymentProcessed,
      'transactionId': transactionId,
      'stripePaymentIntentId': stripePaymentIntentId,
    };
  }

  Booking copyWith({
    String? id,
    String? ownerId,
    String? walkerId,
    String? ownerName,
    String? walkerName,
    String? dogName,
    DateTime? date,
    String? time,
    int? duration,
    String? location,
    double? latitude,
    double? longitude,
    double? price,
    BookingStatus? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? services,
    Map<String, dynamic>? serviceDetails,
    String? recurringBookingId,
    bool? isRecurring,
    DateTime? completedByWalkerAt,
    DateTime? confirmedByOwnerAt,
    bool? paymentProcessed,
    String? transactionId,
    String? stripePaymentIntentId,
  }) {
    return Booking(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      walkerId: walkerId ?? this.walkerId,
      ownerName: ownerName ?? this.ownerName,
      walkerName: walkerName ?? this.walkerName,
      dogName: dogName ?? this.dogName,
      date: date ?? this.date,
      time: time ?? this.time,
      duration: duration ?? this.duration,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      price: price ?? this.price,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      services: services ?? this.services,
      serviceDetails: serviceDetails ?? this.serviceDetails,
      recurringBookingId: recurringBookingId ?? this.recurringBookingId,
      isRecurring: isRecurring ?? this.isRecurring,
      completedByWalkerAt: completedByWalkerAt ?? this.completedByWalkerAt,
      confirmedByOwnerAt: confirmedByOwnerAt ?? this.confirmedByOwnerAt,
      paymentProcessed: paymentProcessed ?? this.paymentProcessed,
      transactionId: transactionId ?? this.transactionId,
      stripePaymentIntentId: stripePaymentIntentId ?? this.stripePaymentIntentId,
    );
  }
}
