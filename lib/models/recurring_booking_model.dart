import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum for recurrence frequency types
enum RecurrenceType {
  daily,    // Every day
  weekly,   // Specific days of week
  custom,   // Custom days selected
}

/// Model for recurring booking patterns
class RecurringBooking {
  final String id;
  final String ownerId;
  final String walkerId;
  final String ownerName;
  final String walkerName;
  final String dogName;
  final String time; // TimeOfDay formatted as string (e.g., "10:00 AM")
  final int duration; // in minutes
  final String location;
  final double pricePerBooking;
  final String? notes;

  // Recurrence settings
  final RecurrenceType recurrenceType;
  final List<int> daysOfWeek; // 1=Monday, 2=Tuesday, ..., 7=Sunday (ISO 8601)
  final DateTime startDate;
  final DateTime? endDate; // null = ongoing/indefinite

  // Service details
  final List<String> services;
  final Map<String, dynamic> serviceDetails;

  // Metadata
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive; // Can be paused/deactivated

  RecurringBooking({
    required this.id,
    required this.ownerId,
    required this.walkerId,
    required this.ownerName,
    required this.walkerName,
    required this.dogName,
    required this.time,
    required this.duration,
    required this.location,
    required this.pricePerBooking,
    this.notes,
    required this.recurrenceType,
    required this.daysOfWeek,
    required this.startDate,
    this.endDate,
    required this.services,
    required this.serviceDetails,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
  });

  factory RecurringBooking.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RecurringBooking(
      id: doc.id,
      ownerId: data['ownerId'] ?? '',
      walkerId: data['walkerId'] ?? '',
      ownerName: data['ownerName'] ?? '',
      walkerName: data['walkerName'] ?? '',
      dogName: data['dogName'] ?? '',
      time: data['time'] ?? '',
      duration: data['duration'] ?? 60,
      location: data['location'] ?? '',
      pricePerBooking: (data['pricePerBooking'] ?? 0).toDouble(),
      notes: data['notes'],
      recurrenceType: RecurrenceType.values.firstWhere(
        (e) => e.toString() == 'RecurrenceType.${data['recurrenceType']}',
        orElse: () => RecurrenceType.weekly,
      ),
      daysOfWeek: data['daysOfWeek'] != null
          ? List<int>.from(data['daysOfWeek'])
          : [],
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: data['endDate'] != null
          ? (data['endDate'] as Timestamp).toDate()
          : null,
      services: data['services'] != null
          ? List<String>.from(data['services'])
          : [],
      serviceDetails: data['serviceDetails'] != null
          ? Map<String, dynamic>.from(data['serviceDetails'])
          : {},
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'ownerId': ownerId,
      'walkerId': walkerId,
      'ownerName': ownerName,
      'walkerName': walkerName,
      'dogName': dogName,
      'time': time,
      'duration': duration,
      'location': location,
      'pricePerBooking': pricePerBooking,
      'notes': notes,
      'recurrenceType': recurrenceType.toString().split('.').last,
      'daysOfWeek': daysOfWeek,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'services': services,
      'serviceDetails': serviceDetails,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isActive': isActive,
    };
  }

  RecurringBooking copyWith({
    String? id,
    String? ownerId,
    String? walkerId,
    String? ownerName,
    String? walkerName,
    String? dogName,
    String? time,
    int? duration,
    String? location,
    double? pricePerBooking,
    String? notes,
    RecurrenceType? recurrenceType,
    List<int>? daysOfWeek,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? services,
    Map<String, dynamic>? serviceDetails,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return RecurringBooking(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      walkerId: walkerId ?? this.walkerId,
      ownerName: ownerName ?? this.ownerName,
      walkerName: walkerName ?? this.walkerName,
      dogName: dogName ?? this.dogName,
      time: time ?? this.time,
      duration: duration ?? this.duration,
      location: location ?? this.location,
      pricePerBooking: pricePerBooking ?? this.pricePerBooking,
      notes: notes ?? this.notes,
      recurrenceType: recurrenceType ?? this.recurrenceType,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      services: services ?? this.services,
      serviceDetails: serviceDetails ?? this.serviceDetails,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Get a human-readable description of the recurrence pattern
  String getRecurrenceDescription() {
    switch (recurrenceType) {
      case RecurrenceType.daily:
        return 'Every day at $time';
      case RecurrenceType.weekly:
        final dayNames = daysOfWeek.map((day) => _getDayName(day)).join(', ');
        return 'Every $dayNames at $time';
      case RecurrenceType.custom:
        final dayNames = daysOfWeek.map((day) => _getDayName(day)).join(', ');
        return '$dayNames at $time';
    }
  }

  String _getDayName(int day) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[day - 1];
  }
}
