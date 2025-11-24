
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String name;
  final String email;
  final String userType;
  final String? bio;
  final String? imageUrl;
  final String? location;
  final String? availability;
  final double? hourlyRate;
  final List<String>? pets;

  UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.userType,
    this.bio,
    this.imageUrl,
    this.location,
    this.availability,
    this.hourlyRate,
    this.pets,
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      userType: data['userType'] ?? '',
      bio: data['bio'],
      imageUrl: data['imageUrl'],
      location: data['location'],
      availability: data['availability'],
      hourlyRate: (data['hourlyRate'] as num?)?.toDouble(),
      pets: List<String>.from(data['pets'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'userType': userType,
      'bio': bio,
      'imageUrl': imageUrl,
      'location': location,
      'availability': availability,
      'hourlyRate': hourlyRate,
      'pets': pets,
    };
  }
}
