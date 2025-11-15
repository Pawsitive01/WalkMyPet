
# Project Blueprint

## Overview

This document outlines the project's design, features, and development plan. It serves as a single source of truth for the application's architecture and style.

## Style and Design

The application will adhere to Material Design 3 principles, with a focus on a modern, clean, and visually engaging user experience.

*   **Color Scheme:** A color palette will be generated from a primary seed color (`Colors.deepPurple`) using `ColorScheme.fromSeed` for both light and dark themes.
*   **Typography:** The `google_fonts` package will be used to implement a consistent and expressive type scale. `Poppins` will be used for titles and headers, while `Inter` will be used for body text.
*   **Layout:** The layout will be responsive, utilizing widgets like `GridView` and `Wrap` to ensure adaptability across screen sizes. `Card` widgets with soft, multi-layered shadows will be used to create depth and a "lifted" appearance for important UI elements.
*   **Iconography:** Material Design icons will be used to enhance clarity and navigation.

## Features

### Core
*   **User Profiles:** Display detailed profiles for both "Dog Walkers" and "Pet Owners."
*   **Theme Toggle:** Allow users to switch between Light, Dark, and System theme modes.

### Current Plan: `detail_page.dart` Enhancement

**Objective:** Refine the `DetailPage` to improve its visual hierarchy, responsiveness, and user experience.

**Steps:**

1.  **Restructure Statistics Display:**
    *   Replace the current `Row` layout for statistics with a `GridView.count` to create a more organized and responsive grid.

2.  **Improve Layout with `Card` Widgets:**
    *   Encapsulate the "About", "Statistics", and "Pet Details" sections within styled `Card` widgets.
    *   Apply a subtle background color, rounded corners, and a soft shadow to each card to create a sense of depth and visual separation.

3.  **Add a Conditional Floating Action Button for Owners:**
    *   Implement a secondary `FloatingActionButton` that appears only on an `Owner`'s detail page, providing an "Edit Profile" action.

4.  **Enhance Readability of SliverAppBar:**
    *   Add a decorative `BoxDecoration` with a gradient overlay to the `FlexibleSpaceBar` background to ensure the title text is always legible against the background image.

5.  **Refactor for Reusability:**
    *   Create a private, reusable `_InfoCard` widget to reduce code duplication and make the main build method cleaner.
