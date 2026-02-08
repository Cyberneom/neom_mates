# neom_mates

User profile discovery and social interaction module for the **Open Neom** ecosystem. Enables users to explore other profiles, view shared content, and interact through following, messaging, and administrative actions.

## Features

### Profile Display
- **Mate Details Page** - Complete profile view with tabs
- **Profile Header** - Photo, cover, name, verification badge
- **Content Tabs** - Posts, items, events, chamber presets
- **Location & Distance** - Geographic proximity display

### Social Interactions
- **Follow/Unfollow** - With optimistic UI updates
- **Direct Messaging** - Integration with `neom_inbox`
- **Block/Unblock** - User control over interactions
- **Report Profile** - Content moderation support

### Admin Functions
- **Verification Level** - Update user verification status
- **User Role Management** - Change subscriber/admin roles
- **Profile Removal** - Remove profiles from platform

### Performance
- **Profile Caching** - Instant loading from local cache
- **Offline-First** - Cache first, then network fetch
- **Memory Management** - Proper cleanup of Rx observables

## Architecture

```
lib/
├── domain/
│   └── use_cases/
│       └── mate_details_service.dart
├── ui/
│   ├── mate_list_page.dart
│   └── mate_details/
│       ├── mate_details_controller.dart
│       ├── mate_details_page.dart
│       ├── mate_details_body.dart
│       ├── header/
│       │   └── mate_details_header.dart
│       └── footer/
│           ├── mate_detail_footer.dart
│           └── tabs/
│               ├── mate_posts.dart
│               ├── mate_items.dart
│               ├── mate_events.dart
│               └── mate_chamber_presets.dart
├── utils/
│   └── constants/
│       ├── mate_constants.dart
│       └── mate_translation_constants.dart
└── mate_routes.dart
```

## Installation

```yaml
dependencies:
  neom_mates:
    git:
      url: git@github.com:Cyberneom/neom_mates.git
```

## Dependencies

| Module | Purpose |
|--------|---------|
| `neom_core` | Services, models, Firestore |
| `neom_commons` | UI components, themes |
| `neom_profile` | Profile cache controller |

## Quick Start

```dart
import 'package:neom_mates/mate_routes.dart';

// Navigate to mate profile
Sint.toNamed(MateRoutes.mateDetails, arguments: profileId);

// Or with AppProfile object
Sint.toNamed(MateRoutes.mateDetails, arguments: appProfile);

// Navigate to mate list (followers/following)
Sint.toNamed(MateRoutes.mateList, arguments: profileIds);
```

## Controller Features

### MateDetailsController

```dart
// Profile loading with cache
await loadMate(profileId);  // Cache first, then network

// Social actions
await follow();
await unfollow();
await blockProfile();
await unblockProfile(profileId);
await sendMessage();

// Admin actions
await updateVerificationLevel();
await updateUserRole();
await removeProfile();
```

### Memory Management

```dart
@override
void onClose() {
  // All Rx observables are properly closed
  totalPresets.close();
  totalMixedItems.close();
  eventPosts.close();
  events.close();
  matePosts.close();
  following.close();
  // ...
  super.onClose();
}
```

## Profile Tabs

| Tab | Content |
|-----|---------|
| Posts | User's image/video posts |
| Items | Media items, releases, external links |
| Events | Created, playing, attending events |
| Presets | Chamber presets (Cyberneom app) |

## Push Notifications

Triggered on:
- Profile view (`viewedYourProfile`)
- Follow action (`startedFollowingYou`)
- Public activity feed updates

## Data Aggregation

The controller aggregates data from multiple sources:
- `ProfileFirestore` - Profile data
- `PostFirestore` - User posts
- `EventFirestore` - User events
- `ItemlistFirestore` - User item lists
- `InstrumentFirestore` - User instruments
- `FrequencyFirestore` - Custom frequencies

## Contributing

Contributions welcome! Focus areas:
- Profile caching improvements
- Social feature enhancements
- Admin tool extensions
- UI/UX improvements

See [CONTRIBUTING.md](https://github.com/Cyberneom/neom_core/blob/main/CONTRIBUTING.md) for guidelines.

## License

Apache License 2.0 - See [LICENSE](LICENSE)
