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
  final String? location;
  final List<String>? services;
  final Map<String, dynamic>? servicePrices;
  final bool? onboardingComplete;
  final double? rating;
  final int? reviews;
  final int? completedWalks;
  final String? phoneNumber;
  final bool? hasPoliceClearance;
  final double? latitude;
  final double? longitude;
  final String? locationState;
  final String? locationCity;
  final String? locationSuburb;
  final String? locationPostcode;

  // Wallet fields (Walker-specific)
  final double? walletBalance;
  final double? totalEarnings;
  final double? pendingEarnings;
  final DateTime? lastPaymentAt;
  final int? totalTransactions;

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
    this.location,
    this.services,
    this.servicePrices,
    this.onboardingComplete,
    this.rating,
    this.reviews,
    this.completedWalks,
    this.phoneNumber,
    this.hasPoliceClearance,
    this.latitude,
    this.longitude,
    this.locationState,
    this.locationCity,
    this.locationSuburb,
    this.locationPostcode,
    this.walletBalance,
    this.totalEarnings,
    this.pendingEarnings,
    this.lastPaymentAt,
    this.totalTransactions,
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
      location: data['location'],
      services: data['services'] != null
          ? List<String>.from(data['services'])
          : null,
      servicePrices: data['servicePrices'] != null
          ? Map<String, dynamic>.from(data['servicePrices'])
          : null,
      onboardingComplete: data['onboardingComplete'],
      rating: data['rating']?.toDouble(),
      reviews: data['reviews'],
      completedWalks: data['completedWalks'],
      phoneNumber: data['phoneNumber'],
      hasPoliceClearance: data['hasPoliceClearance'],
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      locationState: data['locationState'],
      locationCity: data['locationCity'],
      locationSuburb: data['locationSuburb'],
      locationPostcode: data['locationPostcode'],
      walletBalance: data['walletBalance']?.toDouble() ?? 0.0,
      totalEarnings: data['totalEarnings']?.toDouble() ?? 0.0,
      pendingEarnings: data['pendingEarnings']?.toDouble() ?? 0.0,
      lastPaymentAt: (data['lastPaymentAt'] as Timestamp?)?.toDate(),
      totalTransactions: data['totalTransactions'] ?? 0,
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
      'location': location,
      'services': services,
      'servicePrices': servicePrices,
      'onboardingComplete': onboardingComplete,
      'rating': rating,
      'reviews': reviews,
      'completedWalks': completedWalks,
      'phoneNumber': phoneNumber,
      'hasPoliceClearance': hasPoliceClearance,
      'latitude': latitude,
      'longitude': longitude,
      'locationState': locationState,
      'locationCity': locationCity,
      'locationSuburb': locationSuburb,
      'locationPostcode': locationPostcode,
      'walletBalance': walletBalance,
      'totalEarnings': totalEarnings,
      'pendingEarnings': pendingEarnings,
      'lastPaymentAt': lastPaymentAt != null ? Timestamp.fromDate(lastPaymentAt!) : null,
      'totalTransactions': totalTransactions,
    };
  }
}

class UserService {
  late final FirebaseFirestore _firestore;
  late final FirebaseAuth _auth;

  UserService() {
    _firestore = FirebaseFirestore.instance;
    _auth = FirebaseAuth.instance;
  }

  /// Determine the collection name based on user type
  String _getCollectionName(UserType userType) {
    return userType == UserType.petWalker ? 'walkers' : 'owners';
  }

  // Create a new user document in Firestore
  // Uses merge to avoid overwriting existing data
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

      final collectionName = _getCollectionName(userType);

      // Check if user already exists in the appropriate collection
      final existingDoc = await _firestore.collection(collectionName).doc(user.uid).get();

      if (existingDoc.exists) {
        // User already exists, update only if necessary
        final data = existingDoc.data() as Map<String, dynamic>;

        // Update fields that might have changed (like photo from Google)
        Map<String, dynamic> updates = {
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        };

        if (displayName != null && displayName != data['displayName']) {
          updates['displayName'] = displayName;
        }

        if (photoURL != null && photoURL != data['photoURL']) {
          updates['photoURL'] = photoURL;
        }

        if (updates.length > 1) { // More than just updatedAt
          await _firestore.collection(collectionName).doc(user.uid).update(updates);
        }

        return; // User already exists, no need to create
      }

      // Create new user
      final appUser = AppUser(
        id: user.uid,
        email: email,
        displayName: displayName ?? user.displayName ?? email.split('@')[0],
        photoURL: photoURL ?? user.photoURL,
        userType: userType,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection(collectionName)
          .doc(user.uid)
          .set(appUser.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      throw 'Failed to create user profile: $e';
    }
  }

  // Create or update user (for seamless Google Sign-In)
  Future<void> createOrUpdateUser({
    required String email,
    required UserType userType,
    String? displayName,
    String? photoURL,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw 'No authenticated user found';
      }

      final collectionName = _getCollectionName(userType);

      final userData = {
        'email': email,
        'displayName': displayName ?? user.displayName ?? email.split('@')[0],
        'photoURL': photoURL ?? user.photoURL,
        'userType': userType == UserType.petWalker ? 'petWalker' : 'petOwner',
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      // Add additional data if provided
      if (additionalData != null) {
        userData.addAll(additionalData);
      }

      // Check if document exists
      final docRef = _firestore.collection(collectionName).doc(user.uid);
      final doc = await docRef.get();

      if (doc.exists) {
        // Update existing user
        await docRef.update(userData);
      } else {
        // Create new user
        userData['createdAt'] = Timestamp.fromDate(DateTime.now());
        await docRef.set(userData);
      }
    } catch (e) {
      throw 'Failed to create/update user profile: $e';
    }
  }

  // Get user document from Firestore (checks both collections)
  Future<AppUser?> getUser(String userId) async {
    try {
      // Try walkers collection first
      var doc = await _firestore.collection('walkers').doc(userId).get();
      if (doc.exists) {
        return AppUser.fromFirestore(doc);
      }

      // Try owners collection
      doc = await _firestore.collection('owners').doc(userId).get();
      if (doc.exists) {
        return AppUser.fromFirestore(doc);
      }

      // Fallback to users collection for backward compatibility
      doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return AppUser.fromFirestore(doc);
      }

      return null;
    } catch (e) {
      throw 'Failed to fetch user profile: $e';
    }
  }

  // Update user document (creates if doesn't exist)
  Future<void> updateUser(String userId, Map<String, dynamic> updates) async {
    try {
      // First try to find which collection the user is in
      final user = await getUser(userId);

      String collectionName;
      if (user == null) {
        // User doesn't exist yet - determine collection from userType in updates or default to owners
        final userTypeStr = updates['userType'] as String?;
        if (userTypeStr == 'petWalker') {
          collectionName = 'walkers';
        } else {
          // Default to owners collection for new users without explicit type
          collectionName = 'owners';
        }

        // Create new document with set() instead of update()
        updates['createdAt'] = Timestamp.fromDate(DateTime.now());
        updates['updatedAt'] = Timestamp.fromDate(DateTime.now());
        updates['userType'] = updates['userType'] ?? 'petOwner';
        await _firestore.collection(collectionName).doc(userId).set(updates, SetOptions(merge: true));
      } else {
        // User exists - update normally
        collectionName = _getCollectionName(user.userType);
        updates['updatedAt'] = Timestamp.fromDate(DateTime.now());
        await _firestore.collection(collectionName).doc(userId).update(updates);
      }
    } catch (e) {
      throw 'Failed to update user profile: $e';
    }
  }

  // Delete user document
  Future<void> deleteUser(String userId) async {
    try {
      // Find which collection the user is in
      final user = await getUser(userId);
      if (user != null) {
        final collectionName = _getCollectionName(user.userType);
        await _firestore.collection(collectionName).doc(userId).delete();
      }
    } catch (e) {
      throw 'Failed to delete user profile: $e';
    }
  }

  // Stream user data (checks which collection the user is in first, then streams)
  Stream<AppUser?> userStream(String userId) async* {
    // First, determine which collection the user is in
    AppUser? user = await getUser(userId);

    if (user == null) {
      yield null;
      return;
    }

    // Now stream from the correct collection
    final collectionName = _getCollectionName(user.userType);

    await for (final doc in _firestore.collection(collectionName).doc(userId).snapshots()) {
      if (doc.exists) {
        yield AppUser.fromFirestore(doc);
      } else {
        yield null;
      }
    }
  }

  // Get all pet walkers (from walkers collection, with fallback to users collection)
  Future<List<AppUser>> getPetWalkers() async {
    try {
      // First, try the new walkers collection
      var querySnapshot = await _firestore
          .collection('walkers')
          .get();

      List<AppUser> walkers = querySnapshot.docs
          .map((doc) => AppUser.fromFirestore(doc))
          .toList();

      // If walkers collection is empty, fallback to users collection for backward compatibility
      if (walkers.isEmpty) {
        querySnapshot = await _firestore
            .collection('users')
            .where('userType', isEqualTo: 'petWalker')
            .get();

        walkers = querySnapshot.docs
            .map((doc) => AppUser.fromFirestore(doc))
            .toList();
      }

      return walkers;
    } catch (e) {
      throw 'Failed to fetch pet walkers: $e';
    }
  }

  // Get all pet owners (from owners collection, with fallback to users collection)
  Future<List<AppUser>> getPetOwners() async {
    try {
      // First, try the new owners collection
      var querySnapshot = await _firestore
          .collection('owners')
          .where('onboardingComplete', isEqualTo: true)
          .get();

      List<AppUser> owners = querySnapshot.docs
          .map((doc) => AppUser.fromFirestore(doc))
          .toList();

      // If owners collection is empty, fallback to users collection for backward compatibility
      if (owners.isEmpty) {
        querySnapshot = await _firestore
            .collection('users')
            .where('userType', isEqualTo: 'petOwner')
            .get();

        owners = querySnapshot.docs
            .map((doc) => AppUser.fromFirestore(doc))
            .toList();
      }

      return owners;
    } catch (e) {
      throw 'Failed to fetch pet owners: $e';
    }
  }
}
