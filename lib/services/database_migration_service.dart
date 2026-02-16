import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service to migrate data from old 'users' collection to new 'walkers'/'owners' collections
class DatabaseMigrationService {
  late final FirebaseFirestore _firestore;
  late final FirebaseAuth _auth;

  DatabaseMigrationService() {
    _firestore = FirebaseFirestore.instance;
    _auth = FirebaseAuth.instance;
  }

  /// Migrate a single user from 'users' collection to appropriate new collection
  Future<bool> migrateUser(String userId) async {
    try {
      // Get user from old collection
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        return false;
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final userType = userData['userType'] as String?;

      // Determine target collection
      String targetCollection;
      if (userType == 'petWalker' || userType == 'walker') {
        targetCollection = 'walkers';
      } else if (userType == 'petOwner' || userType == 'owner') {
        targetCollection = 'owners';
      } else {
        // Default to owners if userType is unclear
        // Unknown userType, defaulting to owners
        targetCollection = 'owners';
        userData['userType'] = 'petOwner';
      }

      // Check if user already exists in target collection
      final targetDoc = await _firestore.collection(targetCollection).doc(userId).get();
      if (targetDoc.exists) {
        return false;
      }

      // Copy user to new collection
      await _firestore.collection(targetCollection).doc(userId).set(userData);

      return true;
    } catch (e) {
      // Error handled silently
      return false;
    }
  }

  /// Migrate the currently logged-in user
  Future<bool> migrateCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) {
      return false;
    }

    return await migrateUser(user.uid);
  }

  /// Migrate all users from 'users' collection to new collections
  /// WARNING: This should only be run by admins/developers
  Future<Map<String, int>> migrateAllUsers() async {
    int successCount = 0;
    int failureCount = 0;
    int skippedCount = 0;

    try {
      final usersSnapshot = await _firestore.collection('users').get();

      for (var doc in usersSnapshot.docs) {
        final result = await migrateUser(doc.id);
        if (result) {
          successCount++;
        } else {
          // Check if it was skipped (already migrated) or failed
          final userData = doc.data();
          final userType = userData['userType'] as String?;
          String targetCollection = (userType == 'petWalker' || userType == 'walker')
              ? 'walkers'
              : 'owners';

          final targetDoc = await _firestore.collection(targetCollection).doc(doc.id).get();
          if (targetDoc.exists) {
            skippedCount++;
          } else {
            failureCount++;
          }
        }
      }

      return {
        'success': successCount,
        'failure': failureCount,
        'skipped': skippedCount,
      };
    } catch (e) {
      // Error handled silently
      return {
        'success': successCount,
        'failure': failureCount,
        'skipped': skippedCount,
      };
    }
  }

  /// Check if current user needs migration
  Future<bool> currentUserNeedsMigration() async {
    final user = _auth.currentUser;
    if (user == null) {
      return false;
    }

    // Check if user exists in old collection
    final oldDoc = await _firestore.collection('users').doc(user.uid).get();
    if (!oldDoc.exists) {
      return false; // User doesn't exist in old collection
    }

    // Check if user exists in new collections
    final walkersDoc = await _firestore.collection('walkers').doc(user.uid).get();
    if (walkersDoc.exists) {
      return false; // Already migrated to walkers
    }

    final ownersDoc = await _firestore.collection('owners').doc(user.uid).get();
    if (ownersDoc.exists) {
      return false; // Already migrated to owners
    }

    return true; // Needs migration
  }

  /// Migrate current user if needed (safe to call on every login)
  Future<void> migrateCurrentUserIfNeeded() async {
    try {
      if (await currentUserNeedsMigration()) {
        await migrateCurrentUser();
      }
    } catch (e) {
      // Error handled silently
    }
  }

  /// Delete user from old 'users' collection after successful migration
  /// WARNING: Only use this after confirming migration was successful
  Future<bool> deleteFromOldCollection(String userId) async {
    try {
      // Verify user exists in new collection first
      var newDoc = await _firestore.collection('walkers').doc(userId).get();
      if (!newDoc.exists) {
        newDoc = await _firestore.collection('owners').doc(userId).get();
      }

      if (!newDoc.exists) {
        // User not found in new collections, cannot delete from old collection
        return false;
      }

      // Delete from old collection
      await _firestore.collection('users').doc(userId).delete();
      return true;
    } catch (e) {
      // Error handled silently
      return false;
    }
  }

  /// Clean up old 'users' collection after migration
  /// WARNING: This is destructive and should only be run after verifying all migrations
  Future<Map<String, int>> cleanupOldCollection() async {
    int deletedCount = 0;
    int failedCount = 0;

    try {
      final usersSnapshot = await _firestore.collection('users').get();

      for (var doc in usersSnapshot.docs) {
        final result = await deleteFromOldCollection(doc.id);
        if (result) {
          deletedCount++;
        } else {
          failedCount++;
        }
      }

      return {
        'deleted': deletedCount,
        'failed': failedCount,
      };
    } catch (e) {
      // Error handled silently
      return {
        'deleted': deletedCount,
        'failed': failedCount,
      };
    }
  }
}
