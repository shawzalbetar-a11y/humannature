# HUMAN NATURE Admin Dashboard (Flutter)

This is a professional Admin Dashboard built with Flutter for the HUMAN NATURE e-commerce platform.

## Features
- **Anti-Clutter Product Form**: Uses a 4-step workflow to add products without overwhelming the UI.
- **Inventory Management**: Real-time Firestore sync with search and filter capabilities.
- **Premium UI**: Minimalist design with a luxury aesthetic (Inter & Outfit fonts).
- **State Management**: Robust implementation using `flutter_riverpod`.
- **Firebase Integration**: Directly linked to the existing Firestore database and Firebase Storage.

## Workflow: Adding a Product
1. **Basic Info**: Title, Description, and Category/Subcategory selection.
2. **Pricing**: Handle Original Price, Discount Price, and special Cart Offers.
3. **Variants**: Add multiple color/size combinations with individual stock levels.
4. **Media & Tags**: Upload images and mark as "Trending" or "New Arrival".

## Setup Instructions
1. Navigate to the `human_nature_admin` folder.
2. Run `flutter pub get` to install dependencies.
3. To run the app:
   - Web: `flutter run -d chrome`
   - Windows: `flutter run -d windows`
   - Mobile: `flutter run`

## Tech Stack
- **Framework**: Flutter 3.x
- **State**: Riverpod
- **Backend**: Firebase Auth, Firestore, Storage
- **Icons**: Lucide Icons
- **Fonts**: Google Fonts (Inter, Outfit)
