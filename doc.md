# Ethio Trading App - Project Documentation

## Overview

The Ethio Trading App is a mobile application designed to provide users with access to financial markets and trading tools, with a focus on features relevant to the Ethiopian context. This document serves to describe the project's architecture, features, and development progress.

## Features Implemented So Far

### 1. Project Setup and Core Structure

-   **Description:** The initial phase of the project involved setting up a Flutter project, and adding the needed dependencies.
-   **Key Components:**
    -   `main.dart`: Entry point of the application.
    - `pubspec.yaml`:  Defines the project's dependencies and assets.

### 2. Firebase Integration

-   **Description:** Integrated Firebase into the application to provide backend services such as authentication and data storage.
-   **Key Components:**
    -   `firebase_core`: Firebase core library.
    -   `firebase_options.dart`: Configuration file for Firebase.
- **Notes:**
    - Firebase is properly initialized.

### 3. Custom Theme and Dark Mode Support

-   **Description:** Created a custom theme for the app, including both light and dark mode options, allowing users to customize the app's appearance.
-   **Key Components:**
    -   `lib/theme/app_theme.dart`: Defines the `AppTheme` class with `lightTheme()` and `darkTheme()` methods.
    -   `main.dart`: Implements dynamic theme switching using `ThemeMode`.
    - `profile_screen.dart`: Adds a theme change button.

### 4. Profile Editing

-   **Description:** Implemented the ability for users to edit their profile information, including their username and email.
-   **Key Components:**
    -   `lib/screens/profile_screen.dart`: Contains the UI elements and logic for editing profile information.
    -   `lib/data/mock_data.dart`: holds mock user data.
    -   Key functionalities: Text Editing controllers, saving changes.

### 5. Localized Market Data

-   **Description:** Added a feature to display localized market data specific to Ethiopia.
-   **Key Components:**
    -   `lib/data/ethio_data.dart`: Contains functions to generate mock Ethiopian market data.
    -   `lib/screens/market_screen.dart`: Fetches and displays the data in a list view.
- **Notes:**
    - The data is currently mock data.
### 6. Code cleanup
- **Description:** The project has been improved a lot by fixing errors, and cleaning the code.
- **Key Components:**
    - multiple files were refactored.
### 7. File Structure:
- **Description:** The project structure has been improved a lot.
- **Key Components:**
    - Screens were moved to `lib/screens`.
    - Multiple files were added and organized.

## Next Steps

-   **Language Customization:**
    -   Add support for Amharic.

## Further Development

-   Implementing user Authentication with firebase.
-   Connecting to the real market data.
- Adding more Ethio centric data.
- Improving the ui/ux.
- adding more features.