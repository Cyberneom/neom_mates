# Changelog

All notable changes to neom_mates will be documented in this file.

## [2.0.0] - 2025-02-08

### Added
- **ProfileCacheController** - Integration for instant profile loading
- **Offline-first loading** - Load from cache, then fetch from network
- **Memory leak prevention** - Proper `onClose()` cleanup for all Rx observables
- **Network error handling** - Graceful fallback to cached data

### Changed
- **SINT framework migration** - Replaced deprecated GetX API
- **Profile loading flow** - Cache-first architecture
- **Service decoupling** - All controllers use service interfaces
- **UI optimizations** - Faster profile rendering

### Fixed
- **Memory leaks** - All Rx observables properly closed on dispose
- **Network failures** - Continue with cached data when offline
- **Following state** - Optimistic updates with rollback on failure

### Architecture
```
Loading Flow:
1. Check ProfileCacheController for cached profile
2. Display cached data immediately (if available)
3. Fetch fresh data from Firestore in background
4. Update cache with fresh data
5. Update UI if data changed
```

### Dependencies
- `neom_core` - Core services and Firestore
- `neom_commons` - Shared UI components
- `neom_profile` - Profile cache controller

---

## [1.4.0] - Previous Release

### Added
- MateTranslationConstants for localization
- Admin functions (verification, role management)
- Profile removal functionality

### Changed
- Service decoupling via interfaces
- Enhanced profile data aggregation
- Location and distance calculations

### Architecture
- Dependency Inversion Principle implementation
- Clean Architecture adherence
- Improved testability

---

## [1.3.0] - Earlier Release

### Added
- Follow/unfollow functionality
- Block/unblock profiles
- Direct messaging integration

### Changed
- Profile tabs (posts, items, events)
- Push notification triggers

---

## [1.2.0] - Initial Features

### Added
- Mate details page
- Profile header display
- Basic social interactions
