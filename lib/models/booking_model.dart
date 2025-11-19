import 'package:cloud_firestore/cloud_firestore.dart';

enum BookingStatus {
  pending,
  confirmed,
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
  final double price;
  final BookingStatus status;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

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
    required this.price,
    required this.status,
    this.notes,
    required this.createdAt,
    this.updatedAt,
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
      price: (data['price'] ?? 0).toDouble(),
      status: BookingStatus.values.firstWhere(
        (e) => e.toString() == 'BookingStatus.${data['status']}',
        orElse: () => BookingStatus.pending,
      ),
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
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
      'price': price,
      'status': status.toString().split('.').last,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
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
    double? price,
    BookingStatus? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
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
      price: price ?? this.price,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
