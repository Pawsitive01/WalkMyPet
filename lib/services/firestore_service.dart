// DEPRECATED: This service uses the old 'users' collection and UserProfile model.
// Please use UserService (user_service.dart) with the new 'walkers' and 'owners' collections instead.
// This file is kept only for backward compatibility during migration.
// TODO: Remove this file once all data is migrated to the new structure.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:walkmypet/models/user_profile.dart';

@Deprecated('Use UserService with walkers/owners collections instead')
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> setUserProfile(String uid, UserProfile userProfile) {
    return _db.collection('users').doc(uid).set(userProfile.toFirestore());
  }

  // One-time read (kept for backward compatibility)
  Future<UserProfile?> getUserProfile(String uid) async {
    DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserProfile.fromFirestore(doc);
    } else {
      return null;
    }
  }

  // Real-time stream for user profile
  Stream<UserProfile?> getUserProfileStream(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return UserProfile.fromFirestore(doc);
      }
      return null;
    });
  }

  // One-time read (kept for backward compatibility)
  Future<List<UserProfile>> getWalkers() async {
    QuerySnapshot snapshot = await _db.collection('users').where('userType', isEqualTo: 'walker').get();
    return snapshot.docs.map((doc) => UserProfile.fromFirestore(doc)).toList();
  }

  // Real-time stream for walkers
  Stream<List<UserProfile>> getWalkersStream() {
    return _db
        .collection('users')
        .where('userType', isEqualTo: 'walker')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => UserProfile.fromFirestore(doc)).toList());
  }

  // One-time read (kept for backward compatibility)
  Future<List<UserProfile>> getOwners() async {
    QuerySnapshot snapshot = await _db.collection('users').where('userType', isEqualTo: 'owner').get();
    return snapshot.docs.map((doc) => UserProfile.fromFirestore(doc)).toList();
  }

  // Real-time stream for owners
  Stream<List<UserProfile>> getOwnersStream() {
    return _db
        .collection('users')
        .where('userType', isEqualTo: 'owner')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => UserProfile.fromFirestore(doc)).toList());
  }
}
