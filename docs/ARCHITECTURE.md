# Blue's Lab - Architecture

## Overview

This document describes the **simplified Clean Architecture** adopted for Blue's Lab. The architecture prioritizes **simplicity** and is designed for **Stage 1** (web-only, no backend).

---

## Platform Strategy

- **Primary platform**: Web
- **Stage 1**: Client-side only, no backend API
- **Future stages**: Backend integration can be added without major refactoring

---

## Folder Structure

```
lib/
├── core/                    # Shared utilities, constants, extensions
│   └── constants/
│       └── app_constants.dart
│
├── domain/                  # Business logic (framework-agnostic)
│   ├── entities/            # Domain models
│   ├── repositories/        # Abstract repository contracts (interfaces)
│   └── usecases/            # Single-responsibility business operations
│
├── data/                    # Data layer (implementations)
│   ├── datasources/         # Local/remote data sources (local only in Stage 1)
│   └── repositories/       # Repository implementations
│
├── presentation/            # UI layer
│   ├── screens/             # Full-page views
│   └── widgets/             # Reusable UI components
│
└── main.dart
```

---

## Layer Dependencies

```
Presentation → Domain ← Data
     ↓            ↑
   (uses)    (implements)
```

- **Domain**: No dependencies on other layers. Pure Dart.
- **Data**: Depends only on Domain (implements repository interfaces).
- **Presentation**: Depends on Domain (uses entities, use cases).

---

## Layer Responsibilities

### Domain
- **Entities**: Plain Dart classes representing business concepts.
- **Repositories**: Abstract interfaces defining data operations.
- **Use cases**: One class per business action (e.g., `GetItemsUseCase`).

### Data
- **Data sources**: Where data comes from (in-memory, local storage, future: API).
- **Repository implementations**: Implement domain repository interfaces.

### Presentation
- **Screens**: Full-page widgets, route destinations.
- **Widgets**: Reusable components.

---

## Stage 1: No Backend

For the first stage, data lives entirely on the client:

| Need | Solution |
|------|----------|
| Persistence | `shared_preferences` or `localstorage` (web) |
| Initial data | JSON assets, hardcoded mock data |
| State | `ChangeNotifier`, `ValueNotifier`, or `Riverpod` (optional) |

---

## Adding Backend Later

When moving to Stage 2:

1. Create a new data source in `data/datasources/` (e.g., `api_datasource.dart`).
2. Update repository implementations to use the API.
3. Keep local data source for offline/cache if needed.
4. Domain and presentation layers remain unchanged.

---

## Naming Conventions

- **Entities**: `Item`, `User` (nouns)
- **Repositories**: `ItemRepository` (interface), `ItemRepositoryImpl` (implementation)
- **Use cases**: `GetItemsUseCase`, `SaveItemUseCase` (verb + noun)
- **Screens**: `HomeScreen`, `ItemDetailScreen` (noun + Screen)
- **Widgets**: `ItemCard`, `LoadingIndicator` (descriptive noun)

---

## Running the App (Web)

```bash
# Chrome (default)
flutter run -d chrome

# Edge
flutter run -d edge

# Web server (for deployment testing)
flutter run -d web-server
```
