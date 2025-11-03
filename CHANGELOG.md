### 1.4.0 Major Architectural Refactor & Social Interaction Specialization
This release for neom_mates introduces a major architectural refactor, solidifying its role as the central module for managing and displaying other user profiles (mates) and enabling social interactions within the Open Neom ecosystem. The primary focus has been on achieving greater modularity, testability, and a clear separation of concerns, in line with the overarching Clean Architecture principles.

Key Architectural & Feature Improvements:

Comprehensive Service Decoupling:

Controllers within neom_mates (e.g., MateController, MateDetailsController) now exclusively interact with core functionalities through their respective service interfaces (use_cases) defined in neom_core.

This includes services like UserService (for user profile data), GeoLocatorService (for location information), InboxService (for messaging), MateService (for mate-specific actions), ReportService (for reporting), and various Firestore repositories (ProfileFirestore, PostFirestore, EventFirestore, ItemlistFirestore, InstrumentFirestore, InboxFirestore, UserFirestore).

This promotes the Dependency Inversion Principle (DIP), leading to significantly improved testability and flexibility by abstracting concrete implementations.

Module-Specific Translations:

Introduced MateTranslationConstants to centralize and manage all UI text strings specific to mate profile and interaction functionalities. This ensures improved localization, maintainability, and consistency with Open Neom's global strategy.

Examples of new translation keys include: removeProfileMsg, removeProfileMsg2, removedProfileMsg, unblockedProfileMsg, itemmateSearch, checkMyBlog, itemmatesMsg, eventmatesMsg, viewedYourProfile, viewedProfileOf, isFollowingTo, verificationLevel, updateVerificationLevel, updateVerificationLevelMsg, updateVerificationLevelSame, updateUserRole, updateUserRoleMsg, updateUserRoleSame, updateUserRoleSuccess.

Centralized Mate Profile Management & Interaction:

neom_mates now fully encapsulates the logic for loading, displaying, and interacting with other user profiles.

Streamlined social features including follow/unfollow, direct messaging, and blocking/unblocking profiles.

Introduced administrative functionalities for managing mate verification levels and user roles (for authorized users).

Enhanced Profile Data Aggregation:

Improved aggregation and display of diverse data points on mate profiles, including posts, items, events, and instruments, sourced from various Firestore collections.

Optimized location and distance calculations for mate profiles.

Integration with Global Architectural Changes:

Adopts the updated service injection patterns established in neom_core's recent refactor, ensuring consistent dependency management across the ecosystem.

Benefits from consolidated utilities and shared UI components from neom_commons.

Overall Benefits of this Major Refactor:

Maximized Decoupling: neom_mates is now a highly independent module, focused purely on mate profile management and social interactions, with clear contracts for interacting with other specialized modules.

Increased Testability: The extensive use of service interfaces makes the controllers and their logic much easier to unit test in isolation.

Improved Maintainability & Scalability: Clearer responsibilities and reduced coupling make the module simpler to understand, debug, and extend for future social features.

Enhanced User Experience: Richer profile displays and seamless social interaction features contribute to a more engaging community experience.