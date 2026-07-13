# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Test Commands

```bash
# Get dependencies
flutter pub get

# Run all tests
flutter test

# Run a single test file
flutter test test/services/todo_service_test.dart

# Run tests by group/name pattern
flutter test --name "TodoService"

# Analyze code
flutter analyze

# Build release APK (split by ABI)
flutter build apk --release --split-per-abi

# Run on connected device
flutter run
```

## Project Architecture

A local-first Flutter diary app (Android) with Hive for storage. **No network layer.**

### Three-Layer Architecture

```
UI (pages/)          ← StatefulWidget pages with ChangeNotifier bindings
    ↓  calls
Service (services/)  ← Business logic + in-memory cache (sync getAll())
    ↓  delegates
Repository (repositories/)  ← Data access abstract interface
    ↓  implements
Hive                  ← Local storage (per-module Box)
```

### Exceptions to the Pattern

Two services manage Hive directly without Repository abstraction:
- **CategoryService** (`lib/services/category_service.dart`) — todo categories. Owns `category_box`.
- **DiaryCategoryService** (`lib/services/diary_category_service.dart`) — diary categories. Owns `diary_category_box`.

These were built before the Repository pattern was adopted. They are NOT initialized through AppDependencies; pages access them directly via constructor. New code should follow the Repository pattern.

### Dependency Management

- **AppDependencies** (lib/core/app_dependencies.dart): Global container, initialized once at startup in `main()`. Creates all Repositories → inits them in parallel → creates Services via constructor injection → inits Services in parallel.
- Pages access services via `appDependencies.xxxService`.
- **Exception**: `CategoryService` and `DiaryCategoryService` are not in AppDependencies — pages instantiate them directly.
- `PomodoroService` extends `ChangeNotifier` (reactive timer UI); others are plain classes.
- Theme/Password state goes through `ThemeProvider` (lib/services/theme_provider.dart), which uses `ListenableBuilder` in `main.dart` for hot-reload-friendly theme switching.

### Key Patterns

| Pattern | Details |
|---------|---------|
| **Repository abstraction** | `TodoRepository`/`HiveTodoRepository` pattern repeats for Diary, Pomodoro, Goal |
| **CrudRepository<T>** | Shared generic interface: `init`, `getAll`, `save`, `delete` |
| **Constructor injection** | Services receive repository via constructor (defaults to Hive impl). **Optional param pattern**: `TodoService({TodoRepository? repository}) : _repository = repository ?? HiveTodoRepository()`. `StreakService` and `ExportService` use **required** params (inject multiple repos). |
| **In-memory cache** | Services load all data in `init()`, expose sync `getAll()`, write-through on save/delete |
| **Fake repos for tests** | `FakeTodoRepository` etc. implement the same interface in memory, no Hive dependency |
| **Model serialization** | `toMap()` / `fromMap()` on every model (Hive stores Map values). Nullable fields use conditional map entries (`if (x != null) 'x': x`). |
| **Feature modules** | Self-contained features under `lib/features/`: `stats/` (computation + widgets), `export/` (JSON dump), `streak/` (consecutive-day counting from 3 repos) |

### Page Navigation

`HomePage` uses a 4-tab `BottomNavigationBar`: 日记 → 待办 → 番茄钟 → 统计. Tab switching uses `AnimatedSwitcher` (300ms). A daily quote dialog (`SharedPreferences`-gated) appears once per day on first launch. The `onPomodoroStart` callback from `TodoPage` auto-switches to Pomodoro tab.

### Repository Pattern (repeat for every module)

```
abstract class XxxRepository extends CrudRepository<XxxModel>
class HiveXxxRepository implements XxxRepository
class FakeXxxRepository implements XxxRepository  (test/)
```

### Test Conventions

- Services tested via fake repos (no Hive). Exception: `PomodoroService` tests use real Hive with temp dir (`Directory.systemTemp`).
- `setUp`: create repo → create service with repo → `await service.init()`.
- Models use `const Uuid().v4()` or literal `'1'`, `'2'` for IDs in tests.

### Data Models

- **TodoTask**: priority (0/1/2), deadline, repeatType, subTask progress, bindTomatoId for Pomodoro linkage
- **DiaryEntry**: mood, tags, images, pinned, diaryCategory
- **PomodoroRecord**: minutes, startTime/endTime, categoryId (bound todo)
- **FocusGoal**: daily focus minutes target

### Module Boxes

Each module opens its own Hive box: `todo_box`, `diary_box`, `pomodoro_box`, `goal_box`, plus a shared `pomodoro_stats` box for timer state persistence, a `settings` box for password/theme, and `category_box` / `diary_category_box` for category data.

### State Persistence

Timer state (remaining seconds, running/paused) is persisted to Hive every second during Pomodoro. On app restart, `PomodoroService.init()` restores and resumes the timer if it was running.

### CI / CD

- Tag push (`git tag vX.Y.Z && git push origin vX.Y.Z`) triggers GitHub Actions release workflow
- Builds split-per-abi APKs, renames with version, creates GitHub Release with auto-generated changelog
- Version managed in `pubspec.yaml`, tag must match
- No Node.js / semantic-release dependency