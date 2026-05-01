# Blue's Lab

Blue's Lab for Pokémon Masters — Web-first Flutter application.

## Platform

- **Primary**: Web
- **Stage 1**: No backend (client-side only)

## Architecture

Simplified Clean Architecture. See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for details.

```
lib/
├── core/           # Constants, utilities
├── domain/         # Entities, repositories (interfaces), use cases
├── data/           # Data sources, repository implementations
├── presentation/   # Screens, widgets
└── main.dart
```

## Run (Web)

```bash
# Chrome
flutter run -d chrome

# Edge
flutter run -d edge

# Web server
flutter run -d web-server
```

## Build for production

```bash
flutter build web
```
