# neom_mates
neom_mates is a core module within the Open Neom ecosystem, dedicated to managing and displaying
details of other user profiles (referred to as "mates"). It provides functionalities for users
to explore the profiles of others, view their shared content, understand their interests,
and interact with them through following, messaging, or administrative actions.

This module is crucial for fostering social connections, community building, and enabling users
to discover individuals with shared interests in digital well-being, neuroscience, and technology.
Designed for rich profile display and seamless interaction, neom_mates adheres strictly to Open Neom's
Clean Architecture principles, ensuring its logic is robust, testable, and decoupled from data sources.
It seamlessly integrates with neom_core for core services and data models, neom_commons for shared UI components,
and other modules like neom_posts, neom_events, neom_inbox, and neom_instruments for a comprehensive social experience.

🌟 Features & Responsibilities
neom_mates provides a comprehensive set of functionalities for mate profile management and interaction:
•	Mate List Display: Presents lists of mates (e.g., followers, following, search results) with basic profile information.
•	Mate Details View: Provides a detailed view of a mate's profile (MateDetailsPage), including:
    o	Profile photo, cover image, name, "about me" description, main feature, genres, and location.
    o	Verification level and user role (for admin views).
    o	Aggregated content: posts, items, events, and chamber presets.
•	Social Interactions:
    o	Follow/Unfollow: Allows users to follow or unfollow other profiles.
    o	Messaging: Initiates direct messages to mates via neom_inbox.
    o	Profile Blocking/Unblocking: Provides functionality to block or unblock other profiles, enhancing user
        control over their interactions.
    o	Reporting: Enables users to report inappropriate profiles.
•	Administrative Actions (Conditional): For users with appropriate roles (e.g., admin, superAdmin), it offers tools to:
    o	Update a mate's verification level.
    o	Update a mate's user role.
    o	Remove a mate's profile from the application.
•	Data Aggregation: Collects and displays various data points from different sources (posts, items, events, instruments)
    associated with the mate's profile.
•	Location & Distance: Calculates and displays the distance to a mate's location, if available.
•	Push Notification Integration: Triggers push notifications for relevant social activities
    (e.g., "started following you," "viewed your profile").

🛠 Technical Highlights / Why it Matters (for developers)
For developers, neom_mates serves as an excellent case study for:
•	Complex Data Aggregation & Display: Demonstrates how to gather and present diverse data from multiple Firestore
    collections (profiles, posts, events, itemlists, instruments) into a single, cohesive profile view.
•	GetX for Advanced State Management: Utilizes GetX extensively in MateController and MateDetailsController for
    managing complex reactive state (Rx<AppProfile>, RxMap for content, RxBool for following/blocking status) and
    orchestrating numerous asynchronous operations.
•	Service Layer Interaction: Shows seamless interaction with a wide range of core services (UserService, GeoLocatorService,
    InboxService) and Firestore repositories (ProfileFirestore, PostFirestore, EventFirestore, ItemlistFirestore, InstrumentFirestore,
    InboxFirestore, UserFirestore) through their defined interfaces, maintaining strong architectural separation.
•	Dynamic UI Rendering: Implements adaptive UI elements and conditional rendering based on user relationships
    (following, blocked), user roles, and data availability.
•	Social Feature Implementation: Provides practical examples of implementing common social network features
    like follow/unfollow, messaging, and content display.
•	Push Notification Integration: Demonstrates how to trigger targeted push notifications for social interactions.
•	Modular Content Display: Leverages widgets from other modules (e.g., PostTile for posts, EventTile for events)
    to display aggregated content, reinforcing the modularity of the ecosystem.

How it Supports the Open Neom Initiative
neom_mates is vital to the Open Neom ecosystem and the broader Tecnozenism vision by:
•	Fostering Community & Connection: It is the primary module for users to discover, interact with, and build relationships
    with other members, strengthening the social fabric of the platform.
•	Enabling Conscious Networking: Supports users in finding individuals with shared interests in digital well-being,
    neuroscience, and technology, promoting meaningful connections.
•	Driving Engagement: Features like following, messaging, and exploring profiles are crucial 
    for driving active user engagement and interaction within the platform.
•	Supporting Decentralized Social Features: By providing the core components for social interaction,
    it lays the groundwork for more decentralized social features in the future.
•	Showcasing Architectural Excellence: As a comprehensive and complex social feature module, it exemplifies how intricate
    functionalities can be built and maintained within Open Neom's modular and decoupled architectural framework.

🚀 Usage
This module provides routes and UI components for displaying lists of mates (MateListPage) and detailed mate
profiles (MateDetailsPage). It is typically accessed from various parts of the application where user profiles
are linked (e.g., neom_home, neom_timeline, neom_events, neom_inbox).

📦 Dependencies
neom_mates relies on neom_core for core services, models, and routing constants, and on neom_commons 
for reusable UI components, themes, and utility functions.

🤝 Contributing
We welcome contributions to the neom_mates module! If you're passionate about social features, community building,
profile management, or enhancing user interaction, your contributions can significantly strengthen Open Neom's social dimension.

To understand the broader architectural context of Open Neom and how neom_mates fits into the overall
vision of Tecnozenism, please refer to the main project's MANIFEST.md.

For guidance on how to contribute to Open Neom and to understand the various levels of learning and engagement
possible within the project, consult our comprehensive guide: Learning Flutter Through Open Neom: A Comprehensive Path.

📄 License
This project is licensed under the Apache License, Version 2.0, January 2004. See the LICENSE file for details.
