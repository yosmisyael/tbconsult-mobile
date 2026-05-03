# TBCare
An Integrated Digital Ecosystem for Tuberculosis Patient Compliance and Support.

## Developer Notes
### Project Structure
This project is build with feature-first clean architecture standard
```
lib/
├── core/                         # Global resources & shared logic
│   ├── constants/                # App-wide constants (endpoints, keys)
│   ├── di/                       # Dependency Injection setup (GetIt)
│   ├── error/                    # Custom Failures & Exceptions
│   ├── network/                  # Dio/Http client configuration & Interceptors
│   ├── theme/                    # App styling (colors, typography, theme data)
│   ├── usecases/                 # Base Usecase interface
│   ├── utils/                    # Common extensions & helper functions
│   └── widgets/                  # Shared UI components (AppButton, AppTextField)
├── features/                     # Business modules (vertical slices)
│   ├── auth/                     # Authentication & Session management
│   ├── medication/               # Medication Log, Doses, & Reminders
│   ├── treatment/                # Dashboard, Streaks, & Progress Journey
│   ├── health_hub/               # CareBot (AI) & Health Screening (Triage)
│   ├── maps/                     # DOTS Facilities & Heatmaps
│   └── literacy/                 # Education articles & Resource library
│       ├── data/                 # Data Layer: Implementation
│       │   ├── data_sources/     # Remote (API) & Local (Hive/SQLite) sources
│       │   ├── models/           # Data Transfer Objects (DTOs) / JSON mapping
│       │   └── repositories/     # Repository implementations (logic for choosing source)
│       ├── domain/               # Domain Layer: Business Logic (Pure Dart)
│       │   ├── entities/         # Pure business objects
│       │   ├── repositories/     # Abstract Repository interfaces
│       │   └── usecases/         # Specific business actions (e.g., GetArticles)
│       └── presentation/         # Presentation Layer: UI
│           ├── cubit/            # State Management (Cubit/Bloc)
│           ├── pages/            # Main screens
│           └── widgets/          # Feature-specific widgets
├── main.dart                     # App entry point
└── injection_container.dart       # Service locator / DI registration
```