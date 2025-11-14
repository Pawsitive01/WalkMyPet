# Project Blueprint

## Overview

This document outlines the plan, style, design, and features of the Flutter application. The goal is to create a visually appealing and intuitive app for pet owners and walkers.

## Current Plan

The current goal is to refine the application's visual design by giving the `AppBar` a more modern and appealing look with smooth, rounded edges.

### Steps:

1.  **Modify AppBar Theme:**
    *   Adjust the `AppBarTheme` in `lib/main.dart` for both light and dark themes.
    *   Increase the `borderRadius` of the `RoundedRectangleBorder` to `30` to create a more pronounced rounded effect on the bottom edge of the `AppBar`.

## Style and Design

*   **Theme:** Material 3 with an elegant, purple-based color scheme.
*   **AppBar:** A customized `AppBar` with smooth, rounded bottom edges for a modern look.
*   **Visual Effects:** Cards have soft, deep drop shadows to create a multi-layered effect and a strong sense of depth.
*   **Iconography:** Modern icons are used for menus and actions to enhance user understanding.
*   **Interactivity:** A main menu and a new Floating Action Button provide clear, interactive pathways for users.
*   **Fonts:** `google_fonts` are used for expressive and clean typography.

## Features

*   **Theme Toggle:** A settings option allows users to switch between light and dark modes.
*   **Login Option:** A placeholder for future user login functionality, now accessible via the main menu and a new FAB.
*   **Tabbed Navigation:** Users can easily switch between "Pet Walkers" and "Pet Owners."
*   **Walker & Owner Profiles:** Information is presented in visually enhanced cards.
