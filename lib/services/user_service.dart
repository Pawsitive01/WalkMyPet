import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum UserType { petOwner, petWalker }

class AppUser {
  final String id;
  final String email;
  final String? displayName;
  final String? photoURL;
  final UserType userType;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Pet Owner specific fields
  final String? dogName;
  final String? dogBreed;
  final String? dogAge;

  // Pet Walker specific fields
  final double? hourlyRate;
  final String? bio;
  final List<String>? availability;

  AppUser({
    required this.id,
    required this.email,
    this.displayName,
    this.photoURL,
    required this.userType,
    required this.createdAt,
    this.updatedAt,
    this.dogName,
    this.dogBreed,
    this.dogAge,
    this.hourlyRate,
    this.bio,
    this.availability,
  });

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      id: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'],
      photoURL: data['photoURL'],
      userType: data['userType'] == 'petWalker'
          ? UserType.petWalker
          : UserType.petOwner,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      dogName: data['dogName'],
      dogBreed: data['dogBreed'],
      dogAge: data['dogAge'],
      hourlyRate: data['hourlyRate']?.toDouble(),
      bio: data['bio'],
      availability: data['availability'] != null
          ? List<String>.from(data['availability'])
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'userType': userType == UserType.petWalker ? 'petWalker' : 'petOwner',
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'dogName': dogName,
      'dogBreed': dogBreed,
      'dogAge': dogAge,
      'hourlyRate': hourlyRate,
      'bio': bio,
      'availability': availability,
    };
  }
}

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create a new user document in Firestore
  Future<void> createUser({
    required String email,
    required UserType userType,
    String? displayName,
    String? photoURL,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw 'No authenticated user found';
      }

      final appUser = AppUser(
        id: user.uid,
        email: email,
        displayName: displayName ?? email.split('@')[0],
        photoURL: photoURL,
        userType: userType,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(appUser.toFirestore());
    } catch (e) {
      throw 'Failed to create user profile: $e';
    }
  }

  // Get user document from Firestore
  Future<AppUser?> getUser(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return AppUser.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw 'Failed to fetch user profile: $e';
    }
  }

  // Update user document
  Future<void> updateUser(String userId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = Timestamp.fromDate(DateTime.now());
      await _firestore.collection('users').doc(userId).update(updates);
    } catch (e) {
      throw 'Failed to update user profile: $e';
    }
  }

  // Delete user document
  Future<void> deleteUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).delete();
    } catch (e) {
      throw 'Failed to delete user profile: $e';
    }
  }

  // Stream user data
  Stream<AppUser?> userStream(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map((doc) {
      if (doc.exists) {
        return AppUser.fromFirestore(doc);
      }
      return null;
    });
  }

  // Get all pet walkers
  Future<List<AppUser>> getPetWalkers() async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('userType', isEqualTo: 'petWalker')
          .get();

      return querySnapshot.docs
          .map((doc) => AppUser.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw 'Failed to fetch pet walkers: $e';
    }
  }

  // Get all pet owners
  Future<List<AppUser>> getPetOwners() async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('userType', isEqualTo: 'petOwner')
          .get();

      return querySnapshot.docs
          .map((doc) => AppUser.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw 'Failed to fetch pet owners: $e';
    }
  }
}
