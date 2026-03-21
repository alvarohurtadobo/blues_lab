# AI Rules — Minimal Flutter Web App (Simplified Architecture)

This document is a **lightweight** counterpart to `rules.md` (SuperApp Retail). Use it for a **small, web-first** Flutter project: **no backend initially**, with a **planned, simple** integration later **only for persisting user sessions** (tokens / session ids), not for full domain APIs.

You are an expert in Flutter and Dart for **web**. The goal is a maintainable app with **BLoC** and **layered architecture**, without monorepo complexity or cross-feature contracts until they are needed.

---

## 1. Core principles

* **Architecture:** Follow a **simplified Clean Architecture** (presentation → domain ← data). Do not skip layers: UI does not call HTTP or `shared_preferences` directly; it goes through cubits/blocs and use cases.
* **Language:** All code, names, comments, and logs in **English**. UI copy may be localized later (e.g. ARB) if the product requires it.
* **Commits:** **Conventional Commits** (`feat:`, `fix:`, `refactor:`, `docs:`, etc.).
* **Dependencies:** Prefer **pinned versions** in `pubspec.yaml` once the project stabilizes; during early prototyping, caret (`^`) is acceptable if the team agrees.
* **Static analysis:** Enable a strict `analysis_options.yaml` (e.g. `flutter_lints` or `very_good_analysis`). Treat analyzer warnings seriously.
* **AI output:** Avoid unnecessary comments, `dynamic` casts, redundant try/catch, and style that does not match surrounding files.

---

## 2. Project shape (single app, web-first)

* **One Flutter package** (no Melos / Pub workspaces required). Optional folders:

```text
lib/
  main.dart                 # entry, minimal
  app.dart                  # MaterialApp.router, theme
  src/
    core/                   # router, theme, di, env flags
    features/
      <feature_name>/
        presentation/       # pages, widgets, blocs
        domain/             # entities, repository interfaces, use cases
        data/               # repository implementations, local/remote sources
```

* **Feature isolation (soft rule):** A feature should not import another feature’s **implementation** files. Shared code lives under `lib/src/core/` or `lib/src/shared/`. If two features need the same thing, **move it to shared** instead of coupling features.
* **No** cross-feature “action bus” or `core` contracts package **until** you have more than one feature and real integration pain.

---

## 3. Layers (simplified)

### 3.1 Presentation

* Widgets, pages, **BLoC/Cubit** only.
* Pages/blocs depend on **use cases** (or a narrow façade), **not** on concrete repositories or `http` clients.
* Use **`go_router`** for navigation (paths suitable for web: `/`, `/login`, etc.).

### 3.2 Domain

* **Entities / value objects:** immutable models; **`freezed`** + `sealed class` is recommended when you want unions and equality.
* **Repository interfaces:** `abstract class XRepository` — describe what the app needs, not how it is stored.
* **Use cases:** small classes or functions that orchestrate one user intention (e.g. `SignInWithPassword`, `LoadSession`, `SignOut`).
* **No** Flutter, `dart:html`, `http`, or `shared_preferences` imports in this layer.

### 3.3 Data

* **Repository implementations** implement domain interfaces.
* **Data sources:** split **local** (web: `shared_preferences`, `IndexedDB` via a package, or in-memory for prototypes) and **remote** (future **session-only** API).
* **DTOs:** when JSON appears (future session API), use **freezed** + **json_serializable** with `fieldRename: FieldRename.snake` if the API uses snake_case.
* **No backend today:** implement repositories with **in-memory** or **local persistence** only, behind the same interfaces you will later swap for a remote session client.

---

## 4. State management (BLoC)

* Use **flutter_bloc** (BLoC or Cubit). Prefer **Cubit** for single-screen, simple state; **BLoC** when events and transitions grow.
* Model states with **freezed** sealed classes for immutability and exhaustive `when` / `map`.
* Async flows: use a small **`ResultState<T>`**-style union (`initial`, `loading`, `data`, `error`) **or** explicit sealed states per feature — keep **one** consistent pattern per project.
* Provide blocs/cubits **as close as needed** to the subtree (`BlocProvider`), not necessarily a single global provider tree.

---

## 5. Dependency injection (keep it simple)

* **Default:** manual constructors + `BlocProvider`/`RepositoryProvider` from `flutter_bloc`, or a single **`get_it`** registrar in `main.dart` / `app.dart`.
* **Optional later:** `injectable` + code generation if registration grows.
* **Rule:** Domain depends on abstractions; `main` / `app` wires implementations.

---

## 6. Web-specific notes

* **Target web** as the primary platform; avoid plugins that do not support web without a documented fallback.
* **Responsive UI:** reasonable layouts for desktop and mobile browsers (e.g. `LayoutBuilder`, max width constraints). No need for a full design system unless the product requires it.
* **Performance:** prefer `ListView.builder` for long lists; use `const` where possible.
* **Storage:** for session prototypes, prefer something that works on web (e.g. `shared_preferences` with web support, or an explicit in-memory session store with a clear TODO for persistence).

---

## 7. Future: session-only backend

* **Scope:** Only **session persistence** (e.g. create/refresh/validate session, revoke on logout). **Do not** turn this into a general-purpose API ruleset until needed.
* **Approach:**
  * Keep **`SessionRepository`** (or `AuthSessionRepository`) in **domain**.
  * Add **`RemoteSessionDataSource`** in **data** with a thin HTTP client (e.g. `http` or `dio` — one choice for the whole app).
  * Map JSON ↔ DTO ↔ domain session model.
  * **No Retrofit requirement**; simple explicit calls are enough for a minimal API surface.
* **Migration:** replace or compose the existing local implementation (e.g. `LocalSessionRepository`) with `RemoteSessionRepository` without changing presentation if interfaces stay stable.

---

## 8. Testing & tooling

* **Tests:** `flutter test` — unit tests for use cases and repositories (mock data sources); widget tests for critical screens.
* **Mocks:** `mocktail` (or `mockito`) for interfaces.
* **Formatting:** `dart format` on **changed files** (avoid mass-formatting unrelated code in one commit).

---

## 9. What this document deliberately omits

* Monorepo, feature packages, barrels per package, `MessageBus`, `UseCaseGateway`, UI composition registry, Retrofit, multi-app shells, and CI/Melos/FVM specifics — **add them only when the project outgrows this minimal setup.**

---

## 10. Relationship to SuperApp Retail `rules.md`

If this project later merges patterns from SuperApp Retail, treat **`docs/rules.md`** as the **stricter** reference and adopt additional rules **incrementally** (e.g. injectable, ResultState conventions, full CI). Until then, **this file** is the source of truth for the minimal web app.
