# UzzOut - Discover Restaurants with Friends

UzzOut is a modern Flutter application that helps users discover, rate, and share restaurant experiences with friends. With a Tinder-like swiping interface, location-based restaurant recommendations, and social features, UzzOut makes dining out more fun and social.

## Features

- **Restaurant Discovery**: Browse and discover restaurants near your location
- **Swipe Interface**: Like or dislike restaurants with an intuitive swipe interface
- **User Profiles**: Customize your profile and preferences
- **Friends System**: Connect with friends to share restaurant recommendations
- **Rewards Program**: Earn rewards for visiting restaurants and engaging with the app
- **Location-Based**: Get personalized restaurant recommendations based on your current location
- **Caching**: Efficient caching system for restaurant data to reduce API calls and provide offline support

## Technical Stack

- **Frontend**: Flutter with GetX state management
- **Backend**: Supabase for authentication, database, and serverless functions
- **APIs**: Integration with restaurant data APIs
- **Authentication**: Google Sign-In and Supabase Auth
- **Geolocation**: Using device location services for nearby restaurant discovery
- **Data Caching**: Local storage with SharedPreferences

## Project Structure

- **`lib/`**: Main application code
  - **`app/`**: Core application components
    - **`models/`**: Data models (e.g., Restaurant)
    - **`controllers/`**: Business logic and state management
    - **`pages/`**: UI screens
    - **`widgets/`**: Reusable UI components
    - **`bindings/`**: Dependency injection
    - **`middleware/`**: Authentication and routing middleware
- **`supabase/`**: Supabase functions and configuration
- **`assets/`**: Images, icons, and other static resources

## Getting Started

### Prerequisites

- Flutter 3.7.2 or higher
- Dart SDK 3.7.2 or higher
- A Supabase account and project
- Google Developer account (for Google Sign-In)

### Installation

1. Clone the repository:
   ```
   git clone https://github.com/vanxh/uzzout.git
   ```

2. Navigate to the project directory:
   ```
   cd uzzout
   ```

3. Install dependencies:
   ```
   flutter pub get
   ```

4. Run the app:
   ```
   flutter run
   ```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the UzzOut Proprietary License - see the LICENSE file for details. This software is protected by copyright law and international treaties. Unauthorized reproduction or distribution of this software, or any portion of it, may result in severe civil and criminal penalties.

For commercial licensing inquiries, please contact the repository owner.

## Acknowledgements

- [Flutter](https://flutter.dev/)
- [Supabase](https://supabase.io/)
- [GetX](https://pub.dev/packages/get)
- [Flutter Card Swiper](https://pub.dev/packages/flutter_card_swiper)
