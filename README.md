# Ecom: Multi-Vendor Marketplace Application

Ecom is a comprehensive, feature-rich multivendor marketplace application built with Flutter and
Firebase. It supports three distinct user roles—**Buyer**, **Seller**, and **Admin**—providing a
complete ecosystem for e-commerce transactions, store management, and platform moderation.

## 🚀 Key Features

### 🛒 Buyer Experience

- **Product Discovery**: Browse a diverse catalog of products and services with detailed
  descriptions and high-quality images.
- **Shopping Cart & Wishlist**: Manage items for immediate purchase or save them for later.
- **Secure Checkout**: Seamless ordering process with address management and multiple payment status
  tracking.
- **Order Tracking**: Real-time updates on order status (Pending, Processing, Shipped, Delivered)
  with support for delivery assignment tracking.
- **Notifications**: Stay informed with in-app notifications for order updates and platform news.
- **Personalized Profile**: Manage account settings, delivery addresses, and view order history.
- **Real-time Chat**: Direct communication channel with sellers for product inquiries.

### 🏪 Seller Dashboard

- **Store Management**: Create and customize store profiles, including logos, banners, and
  descriptions.
- **Inventory Control**: Add, edit, and manage products with support for both physical goods and
  services.
- **Order Management**: Process incoming orders, update shipping status, and track sales
  performance.
- **Analytics**: Comprehensive dashboard showing revenue, order trends, and customer insights.
- **Financial Tracking**: Monitor earnings, platform commissions, and payout statuses.
- **Customer Management**: View and interact with customers who have purchased from the store.

### 🛡️ Admin & Moderation

- **Platform Overview**: Real-time dashboard with metrics on total users, revenue, active products,
  and pending disputes.
- **Seller Onboarding**: Review and approve/reject seller applications with a formal verification
  workflow.
- **User & Store Management**: Ability to suspend/activate users and stores to maintain platform
  integrity.
- **Dispute Resolution**: Manage and resolve support tickets and disputes between buyers and
  sellers.
- **System Configuration**: Fine-tune platform-wide settings, including global commission rates and
  maintenance modes.

---

## 🛠️ Tech Stack

- **Framework**: [Flutter](https://flutter.dev/)
- **State Management**: [Riverpod](https://riverpod.dev/) (with Code Generation)
- **Backend/Database**: [Firebase](https://firebase.google.com/) (Firestore, Auth, Storage, Cloud
  Messaging)
- **Navigation**: [GoRouter](https://pub.dev/packages/go_router) (Supporting Deep Linking and Shell
  Routes)
- **Functional Programming**: [Fpdart](https://pub.dev/packages/fpdart) (Either, Unit, Option)
- **UI/UX**: Material 3, Google Fonts, Custom Theme Engine

---

## 🏗️ Architecture

The project follows **Clean Architecture** principles combined with **Domain-Driven Design (DDD)**
influences to ensure scalability, maintainability, and testability.

### Project Structure
The project is organized to support a multi-platform Flutter application with a robust Firebase backend:

```text
.
├── android/                   # Android-specific configuration and manifest
├── ios/                       # iOS-specific configuration and build settings
├── lib/                       # Main application source code
│   ├── core/                  # Platform-wide utilities and shared infrastructure
│   │   ├── constants/         # App-wide constants (spacing, radius, etc.)
│   │   ├── network/           # API and network clients
│   │   ├── providers/         # Global Riverpod providers (Firebase, Auth state)
│   │   ├── services/          # Infrastructure services (Cloudinary, Push Notifications)
│   │   ├── theme/             # App styling and Material 3 theme configuration
│   │   └── widgets/           # Reusable UI components (Buttons, Cards, Loaders)
│   ├── features/              # Feature-based modules (Clean Architecture)
│   │   ├── admin/             # Platform administration and moderation
│   │   ├── auth/              # Identity and access management
│   │   ├── buyer/             # Shopping experience for customers
│   │   ├── marketplace/       # Shared catalog and communication
│   │   ├── orders/            # Unified order processing engine
│   │   ├── seller/            # Seller business management tools
│   │   └── seller_application/# Onboarding flow for new sellers
│   ├── shared/                # Common domain logic and navigation
│   ├── app.dart               # Root widget and theme injection
│   └── main.dart              # App entry point and Firebase initialization
├── functions/                 # Firebase Cloud Functions (Node.js/TypeScript)
├── infrastructure/            # Scripts, security rules, and backend configuration
├── test/                      # Unit, Widget, and Integration tests
├── firebase.json              # Firebase CLI configuration
├── firestore.rules            # Firestore security rules
├── firestore.indexes.json     # Firestore index definitions
└── pubspec.yaml               # Flutter dependencies and project metadata
```

### Layered Breakdown

1. **Domain Layer**: Contains pure Dart Entities and Repository interfaces. No dependencies on
   external libraries or frameworks.
2. **Data Layer**: Contains Repository implementations (e.g., `FirestoreAdminRepository`), Data
   Transfer Objects (DTOs), and external data source integrations.
3. **Presentation Layer**: Contains Riverpod Notifiers (Controllers) for state management and
   Flutter Widgets/Screens for the UI.

---

## 🚦 Getting Started

### Prerequisites

- Flutter SDK (v3.12.1 or higher)
- Firebase Account and Project
- Android Studio / VS Code

### Setup

1. **Clone the repository**:
   ```bash
   git clone https://github.com/your-username/ecom.git
   cd ecom
   ```
2. **Install dependencies**:
   ```bash
   flutter pub get
   ```
3. **Firebase Configuration**:
    - Create a Firebase project.
    - Register Android/iOS apps.
    - Download and place `google-services.json` and `GoogleService-Info.plist` in respective
      directories.
    - Run `flutterfire configure` if using the Firebase CLI.
4. **Generate Code**:
   Since the project uses `build_runner` for Riverpod and JSON serialization, run:
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```
5. **Run the app**:
   ```bash
   flutter run
   ```

---

## 📄 License

This project is private and confidential. Use of this source code is restricted.
