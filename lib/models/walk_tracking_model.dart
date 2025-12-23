import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

enum WalkStatus {
  notStarted,
  active,
  paused,
  completed,
  cancelled,
}

class WalkLocation {
  final LatLng position;
  final DateTime timestamp;
  final double? accuracy;

  WalkLocation({
    required this.position,
    required this.timestamp,
    this.accuracy,
  });

  Map<String, dynamic> toMap() {
    return {
      'latitude': position.latitude,
      'longitude': position.longitude,
      'timestamp': Timestamp.fromDate(timestamp),
      'accuracy': accuracy,
    };
  }

  factory WalkLocation.fromMap(Map<String, dynamic> map) {
    return WalkLocation(
      position: LatLng(
        map['latitude'] as double,
        map['longitude'] as double,
      ),
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      accuracy: map['accuracy'] as double?,
    );
  }
}

class PauseRecord {
  final DateTime pausedAt;
  final DateTime? resumedAt;

  PauseRecord({
    required this.pausedAt,
    this.resumedAt,
  });

  Duration get duration {
    if (resumedAt == null) return Duration.zero;
    return resumedAt!.difference(pausedAt);
  }

  Map<String, dynamic> toMap() {
    return {
      'pausedAt': Timestamp.fromDate(pausedAt),
      'resumedAt': resumedAt != null ? Timestamp.fromDate(resumedAt!) : null,
    };
  }

  factory PauseRecord.fromMap(Map<String, dynamic> map) {
    return PauseRecord(
      pausedAt: (map['pausedAt'] as Timestamp).toDate(),
      resumedAt: map['resumedAt'] != null
          ? (map['resumedAt'] as Timestamp).toDate()
          : null,
    );
  }
}

class WalkTracking {
  final String id;
  final String bookingId;
  final String walkerId;
  final String ownerId;
  final WalkStatus status;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final List<WalkLocation> locationHistory;
  final List<PauseRecord> pauseHistory;
  final double? totalDistance; // in meters
  final int scheduledDuration; // in minutes
  final Map<String, dynamic>? metadata;

  WalkTracking({
    required this.id,
    required this.bookingId,
    required this.walkerId,
    required this.ownerId,
    this.status = WalkStatus.notStarted,
    this.startedAt,
    this.completedAt,
    this.locationHistory = const [],
    this.pauseHistory = const [],
    this.totalDistance,
    required this.scheduledDuration,
    this.metadata,
  });

  /// Calculate total elapsed time (excluding paused time)
  Duration get elapsedTime {
    if (startedAt == null) return Duration.zero;

    final endTime = completedAt ?? DateTime.now();
    final totalTime = endTime.difference(startedAt!);

    // Subtract paused time
    int totalPausedSeconds = 0;
    for (final pause in pauseHistory) {
      if (pause.resumedAt != null) {
        totalPausedSeconds += pause.duration.inSeconds;
      } else if (status == WalkStatus.paused) {
        // Current pause
        totalPausedSeconds +=
            DateTime.now().difference(pause.pausedAt).inSeconds;
      }
    }

    return totalTime - Duration(seconds: totalPausedSeconds);
  }

  /// Calculate remaining time
  Duration get remainingTime {
    final scheduled = Duration(minutes: scheduledDuration);
    final remaining = scheduled - elapsedTime;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Calculate progress percentage (0.0 to 1.0)
  double get progress {
    if (scheduledDuration == 0) return 0.0;
    final elapsed = elapsedTime.inSeconds;
    final scheduled = scheduledDuration * 60;
    final progress = elapsed / scheduled;
    return progress > 1.0 ? 1.0 : progress;
  }

  /// Check if walk is currently active (not paused or completed)
  bool get isActive => status == WalkStatus.active;

  /// Check if walk is paused
  bool get isPaused => status == WalkStatus.paused;

  /// Check if walk is completed
  bool get isCompleted => status == WalkStatus.completed;

  Map<String, dynamic> toFirestore() {
    return {
      'bookingId': bookingId,
      'walkerId': walkerId,
      'ownerId': ownerId,
      'status': status.toString().split('.').last,
      'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'locationHistory': locationHistory.map((loc) => loc.toMap()).toList(),
      'pauseHistory': pauseHistory.map((pause) => pause.toMap()).toList(),
      'totalDistance': totalDistance,
      'scheduledDuration': scheduledDuration,
      'metadata': metadata,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory WalkTracking.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WalkTracking(
      id: doc.id,
      bookingId: data['bookingId'] ?? '',
      walkerId: data['walkerId'] ?? '',
      ownerId: data['ownerId'] ?? '',
      status: WalkStatus.values.firstWhere(
        (e) => e.toString() == 'WalkStatus.${data['status']}',
        orElse: () => WalkStatus.notStarted,
      ),
      startedAt: data['startedAt'] != null
          ? (data['startedAt'] as Timestamp).toDate()
          : null,
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      locationHistory: data['locationHistory'] != null
          ? (data['locationHistory'] as List)
              .map((loc) => WalkLocation.fromMap(loc as Map<String, dynamic>))
              .toList()
          : [],
      pauseHistory: data['pauseHistory'] != null
          ? (data['pauseHistory'] as List)
              .map((pause) => PauseRecord.fromMap(pause as Map<String, dynamic>))
              .toList()
          : [],
      totalDistance: data['totalDistance'] as double?,
      scheduledDuration: data['scheduledDuration'] ?? 30,
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  WalkTracking copyWith({
    String? id,
    String? bookingId,
    String? walkerId,
    String? ownerId,
    WalkStatus? status,
    DateTime? startedAt,
    DateTime? completedAt,
    List<WalkLocation>? locationHistory,
    List<PauseRecord>? pauseHistory,
    double? totalDistance,
    int? scheduledDuration,
    Map<String, dynamic>? metadata,
  }) {
    return WalkTracking(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      walkerId: walkerId ?? this.walkerId,
      ownerId: ownerId ?? this.ownerId,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      locationHistory: locationHistory ?? this.locationHistory,
      pauseHistory: pauseHistory ?? this.pauseHistory,
      totalDistance: totalDistance ?? this.totalDistance,
      scheduledDuration: scheduledDuration ?? this.scheduledDuration,
      metadata: metadata ?? this.metadata,
    );
  }
}
