
# Project Blueprint

## Overview

This document outlines the plan for integrating Firebase into the "WalkMyPet" Flutter application. The goal is to replace the current placeholder data with dynamic data from Firebase's Firestore and Storage services. This will allow for a more robust and scalable application.

## Current State

The application currently uses hardcoded placeholder data for displaying user profiles (both pet owners and walkers) and their details. Images are also stored locally in the project's assets.

## Plan for Firebase Integration

### 1. Firebase Setup

*   **Dependencies:** Add the necessary Firebase packages to the `pubspec.yaml` file:
    *   `firebase_core`: To initialize the Firebase app.
    *   `cloud_firestore`: To interact with the Firestore database.
    *   `firebase_storage`: To store and retrieve user profile images.
*   **Initialization:** Initialize Firebase in the `lib/main.dart` file to ensure that Firebase services are available throughout the application.

### 2. Data Modeling

*   **User Profiles:** Create a new data model in `lib/models/user_profile.dart` to represent user profiles. This model will include fields for:
    *   `uid`: The user's unique ID from Firebase Authentication.
    *   `name`: The user's name.
    *   `email`: The user's email.
    *   `userType`: "owner" or "walker".
    *   `bio`: A short biography.
    *   `imageUrl`: The URL of the user's profile picture stored in Firebase Storage.
    *   `location`: The user's location.
    *   `availability` (for walkers): The walker's availability.
    *   `hourlyRate` (for walkers): The walker's hourly rate.
    *   `pets` (for owners): A list of the owner's pets.

### 3. Firebase Services

*   **Firestore Service:** Create a new service in `lib/services/firestore_service.dart` to handle all interactions with the Firestore database. This service will include methods for:
    *   Creating and updating user profiles.
    *   Fetching user profiles by UID.
    *   Fetching lists of walkers and owners.
*   **Storage Service:** Create a new service in `lib/services/storage_service.dart` to handle all interactions with Firebase Storage. This service will include methods for:
    *   Uploading user profile images.
    *   Getting the download URL for an image.

### 4. Data Migration

*   **Upload Script:** Create a one-time script or function to upload the existing placeholder data (including images) to Firestore and Firebase Storage. This will populate the database with initial data for testing and development.

### 5. UI Refactoring

*   **User Type Selection Page:**
    *   Modify `lib/user_type_selection_page.dart` to display generic "Pet Owner" and "Pet Walker" cards that lead to the authentication/onboarding flow.
*   **Profile Pages:**
    *   Modify `lib/profile/owner_profile_page.dart` and `lib/profile/walker_profile_page.dart` to fetch user data from Firestore using the `FirestoreService`.
    *   Update the UI to display the dynamic data, including loading the profile images from the URLs stored in Firestore.
*   **Onboarding:**
    *   Update the `lib/onboarding/owner_onboarding_page.dart` and `lib/onboarding/walker_onboarding_page.dart` to save the user's information to Firestore after they complete the onboarding process.

### 6. Authentication

*   The existing authentication flow will be updated to create a user document in Firestore upon successful registration.
