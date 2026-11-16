import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:neom_commons/utils/app_utilities.dart';
import 'package:neom_commons/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/utils/constants/translations/common_translation_constants.dart';
import 'package:neom_commons/utils/constants/translations/message_translation_constants.dart';
import 'package:neom_commons/utils/text_utilities.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/data/api_services/push_notification/firebase_messaging_calls.dart';
import 'package:neom_core/data/firestore/activity_feed_firestore.dart';
import 'package:neom_core/data/firestore/app_media_item_firestore.dart';
import 'package:neom_core/data/firestore/app_release_item_firestore.dart';
import 'package:neom_core/data/firestore/blog_entry_firestore.dart';
import 'package:neom_core/data/firestore/event_firestore.dart';
import 'package:neom_core/data/firestore/external_item_firestore.dart';
import 'package:neom_core/data/firestore/frequency_firestore.dart';
import 'package:neom_core/data/firestore/inbox_firestore.dart';
import 'package:neom_core/data/firestore/instrument_firestore.dart';
import 'package:neom_core/data/firestore/itemlist_firestore.dart';
import 'package:neom_core/data/firestore/nupale_session_firestore.dart';
import 'package:neom_core/data/firestore/post_firestore.dart';
import 'package:neom_core/data/firestore/profile_firestore.dart';
import 'package:neom_core/data/firestore/public_catalog_read_policy.dart';
import 'package:neom_core/data/firestore/user_firestore.dart';
import 'package:neom_core/domain/model/activity_feed.dart';
import 'package:neom_core/domain/model/app_media_item.dart';
import 'package:neom_core/domain/model/app_profile.dart';
import 'package:neom_core/domain/model/app_release_item.dart';
import 'package:neom_core/domain/model/app_user.dart';
import 'package:neom_core/domain/model/event.dart';
import 'package:neom_core/domain/model/external_item.dart';
import 'package:neom_core/domain/model/inbox.dart';
import 'package:neom_core/domain/model/instrument.dart';
import 'package:neom_core/domain/model/item_list.dart';
import 'package:neom_core/domain/model/neom/neom_chamber_preset.dart';
import 'package:neom_core/domain/model/nupale/nupale_session.dart';
import 'package:neom_core/domain/model/nupale/reading_progress.dart';
import 'package:neom_core/domain/model/post.dart';
import 'package:neom_core/domain/use_cases/geolocator_service.dart';
import 'package:neom_core/domain/use_cases/user_service.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_core/utils/core_utilities.dart';
import 'package:neom_core/utils/enums/activity_feed_type.dart';
import 'package:neom_core/utils/enums/app_in_use.dart';
import 'package:neom_core/utils/enums/post_type.dart';
import 'package:neom_core/utils/enums/push_notification_type.dart';
import 'package:neom_core/utils/enums/user_role.dart';
import 'package:neom_core/utils/enums/verification_level.dart';
import 'package:neom_core/utils/neom_error_logger.dart';
import 'package:neom_core/utils/position_utilities.dart';
import 'package:neom_core/utils/profile_directory_policy.dart';
import 'package:neom_profile/neom_profile.dart';
import 'package:sint/sint.dart';

import '../../domain/use_cases/mate_details_service.dart';
import '../../utils/constants/mate_translation_constants.dart';

class MateDetailsController extends SintController
    implements MateDetailsService {
  MateDetailsController({
    PostFirestore? postFirestore,
    Future<AppProfile> Function(String)? profileLoader,
    Future<bool> Function(String)? blogPresenceLoader,
    Future<Map<String, Instrument>> Function(String)? instrumentsLoader,
  }) : postFirestore = postFirestore ?? PostFirestore(),
       _profileLoader =
           profileLoader ?? ((id) => ProfileFirestore().retrieve(id)),
       _blogPresenceLoader =
           blogPresenceLoader ??
           ((id) => BlogEntryFirestore().hasPublishedEntries(id)),
       _instrumentsLoader =
           instrumentsLoader ??
           ((id) => InstrumentFirestore().retrieveInstruments(id));

  final Future<AppProfile> Function(String) _profileLoader;
  final Future<bool> Function(String) _blogPresenceLoader;
  final Future<Map<String, Instrument>> Function(String) _instrumentsLoader;

  final userServiceImpl = Sint.find<UserService>();
  final GeoLocatorService? geoLocatorServiceImpl =
      kIsWeb || !Sint.isRegistered<GeoLocatorService>()
      ? null
      : Sint.find<GeoLocatorService>();
  final profileCacheController = ProfileCacheController();
  bool _isClosed = false;

  Map<String, AppProfile> mates = <String, AppProfile>{};
  Rx<AppProfile> mate = AppProfile().obs;

  AppProfile profile = AppProfile();

  PostFirestore postFirestore;

  String address = "";
  String instrumentsText = "";
  int distance = 0;

  RxMap<String, NeomChamberPreset> totalPresets =
      <String, NeomChamberPreset>{}.obs;
  RxMap<String, dynamic> totalMixedItems = <String, dynamic>{}.obs;
  RxMap<String, ReadingProgress> readingProgressMap =
      <String, ReadingProgress>{}.obs;

  RxBool following = false.obs;
  bool blockedProfile = false;

  RxMap<Post, Event> eventPosts = <Post, Event>{}.obs;
  RxMap<String, Event> events = <String, Event>{}.obs;

  RxBool isLoading = true.obs;
  RxBool isLoadingDetails = true.obs;
  RxBool isLoadingPosts = true.obs;

  RxList<Post> matePosts = <Post>[].obs;
  RxBool hasBlogEntries = false.obs;

  bool debugPushNotifications = false;

  final Rx<VerificationLevel> verificationLevel = VerificationLevel.none.obs;
  final Rx<UserRole> newUserRole = UserRole.subscriber.obs;
  AppUser mateUser = AppUser();

  static const int maxMateIdLength = 128;

  static final RegExp _unsafeMateIdChars = RegExp(
    r'[\x00-\x1F\x7F-\x9F\u0085\u061C\u200B-\u200F\u2028\u2029\u202A-\u202E\u2060\u2066-\u2069\uFEFF/\\:?#]',
  );
  static final RegExp _reservedDunderMateIdRe = RegExp(r'^__.*__$');
  static final RegExp _encodedTraversalMateIdRe = RegExp(
    r'%2e|%2f|%5c|%00',
    caseSensitive: false,
  );

  @visibleForTesting
  static String resolveMateId({String? routeParam, Object? arguments}) {
    String rawCandidate = '';
    if (routeParam != null && routeParam.trim().isNotEmpty) {
      rawCandidate = routeParam;
    }
    if (arguments != null) {
      if (arguments is AppProfile) {
        if (arguments.id.trim().isNotEmpty) {
          rawCandidate = arguments.id;
        }
      } else if (arguments is List && arguments.isNotEmpty) {
        final first = arguments.first;
        if (first is AppProfile) {
          rawCandidate = first.id;
        } else if (first is String && first.trim().isNotEmpty) {
          rawCandidate = first;
        }
      } else if (arguments is Map) {
        final rawId =
            arguments['mateId'] ?? arguments['profileId'] ?? arguments['id'];
        if (rawId is AppProfile) {
          rawCandidate = rawId.id;
        } else if (rawId != null && rawId.toString().trim().isNotEmpty) {
          rawCandidate = rawId.toString();
        }
      } else if (arguments is String && arguments.trim().isNotEmpty) {
        rawCandidate = arguments;
      }
    }
    if (_unsafeMateIdChars.hasMatch(rawCandidate)) return '';
    final candidate = rawCandidate.trim();
    if (candidate.isEmpty ||
        candidate.length > maxMateIdLength ||
        candidate == '.' ||
        candidate == '..' ||
        candidate.contains('..') ||
        candidate == 'constructor' ||
        candidate == 'prototype' ||
        _reservedDunderMateIdRe.hasMatch(candidate) ||
        _encodedTraversalMateIdRe.hasMatch(candidate) ||
        _unsafeMateIdChars.hasMatch(candidate) ||
        candidate.startsWith('{') ||
        candidate.startsWith('Instance of ')) {
      return '';
    }
    return candidate;
  }

  @override
  void onInit() {
    super.onInit();

    // Read route parameter for deep linking / web URL state
    final routeId = Sint.routeParam;

    AppConfig.logger.t("MateDetails Controller Init");

    final mateId = resolveMateId(
      routeParam: routeId,
      arguments: Sint.arguments,
    );

    AppConfig.logger.d(
      "Mate ID: $mateId (type: ${Sint.arguments?.runtimeType})",
    );

    try {
      profile = userServiceImpl.profile;
      blockedProfile =
          mateId.isNotEmpty && (profile.blockTo?.contains(mateId) ?? false);

      if (mateId.isNotEmpty && !blockedProfile) {
        loadMate(mateId);
      } else {
        isLoading.value = false;
        isLoadingDetails.value = false;
        isLoadingPosts.value = false;
        AppConfig.logger.i("Profile $mateId is empty or blocked");
      }
    } catch (e, st) {
      isLoading.value = false;
      isLoadingDetails.value = false;
      isLoadingPosts.value = false;
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_mates',
        operation: 'onInit',
      );
    }
  }

  @override
  void onReady() {
    super.onReady();
    AppConfig.logger.d("MateDetails Controller Ready");
    try {
      sendViewProfileNotification();
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_mates',
        operation: 'onReady',
      );
    }
  }

  @override
  void onClose() {
    _isClosed = true;
    // FIXED: Clean up resources to prevent memory leaks
    // Close reactive collections
    totalPresets.close();
    totalMixedItems.close();
    readingProgressMap.close();
    eventPosts.close();
    events.close();
    matePosts.close();
    following.close();
    isLoading.close();
    isLoadingDetails.close();
    isLoadingPosts.close();
    hasBlogEntries.close();
    verificationLevel.close();
    newUserRole.close();
    mate.close();
    super.onClose();
  }

  @override
  Future<void> loadMate(String id) async {
    final cleanId = resolveMateId(arguments: id);
    if (cleanId.isEmpty) {
      if (!_isClosed) {
        isLoading.value = false;
        isLoadingPosts.value = false;
        isLoadingDetails.value = false;
      }
      return;
    }
    AppConfig.logger.d("loadMate $cleanId");

    try {
      // Try to load from cache first for instant display
      final canUsePersonalCache = AppConfig.instance.canPersistUserActivity;
      final cachedProfile = canUsePersonalCache
          ? await profileCacheController.getCachedProfile(cleanId)
          : null;
      if (_isClosed) return;
      if (cachedProfile != null) {
        AppConfig.logger.d("Loaded profile from cache: $cleanId");
        mate.value = cachedProfile;
        following.value = profile.following?.contains(mate.value.id) ?? false;
        isLoading.value = false;
        // Continue loading fresh data in background
      }

      // Fetch fresh data from network
      try {
        final freshProfile = await _profileLoader(cleanId);
        if (_isClosed) return;
        if (freshProfile.id.isNotEmpty) {
          mate.value = freshProfile;
          // Cache the profile for offline access
          if (AppConfig.instance.canPersistUserActivity) {
            await profileCacheController.cacheProfile(freshProfile);
          }
          if (_isClosed) return;
          retrieveDetails();
          following.value = profile.following?.contains(mate.value.id) ?? false;
        } else if (PublicCatalogReadPolicy.enabled) {
          mate.value = AppProfile();
        }
      } catch (e, st) {
        NeomErrorLogger.recordError(
          e,
          st,
          module: 'neom_mates',
          operation: 'loadMate.network',
        );
        // If we have cached data, continue with it
        if (!_isClosed && mate.value.id.isNotEmpty) {
          retrieveDetails();
        }
      }

      if (!_isClosed) {
        isLoading.value = false;
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_mates',
        operation: 'loadMate',
      );
    } finally {
      if (!_isClosed && mate.value.id.isEmpty) {
        isLoading.value = false;
        isLoadingPosts.value = false;
        isLoadingDetails.value = false;
      }
    }
  }

  void sendViewProfileNotification() {
    if (!AppConfig.instance.canPersistUserActivity ||
        mate.value.id.isEmpty ||
        profile.id.isEmpty) {
      return;
    }

    if (userServiceImpl.user.userRole == UserRole.subscriber ||
        debugPushNotifications) {
      FirebaseMessagingCalls.sendPrivatePushNotification(
        toProfileId: mate.value.id,
        fromProfile: profile,
        notificationType: PushNotificationType.viewProfile,
        title: MateTranslationConstants.viewedYourProfile,
        message: '',
        referenceId: profile.id,
      );

      FirebaseMessagingCalls.sendPublicPushNotification(
        fromProfile: profile,
        toProfileId: mate.value.id,
        notificationType: PushNotificationType.viewProfile,
        title:
            "${MateTranslationConstants.viewedProfileOf.tr} ${mate.value.name}",
        referenceId: mate.value.id,
      );
    }
  }

  @override
  Future<void> retrieveDetails() async {
    AppConfig.logger.d("retrieveDetails");
    try {
      if (!AppConfig.instance.canPersistUserActivity) {
        mate.value = ProfileDirectoryPolicy.publicProjection(mate.value);
        if (mate.value.id.isEmpty) {
          isLoadingPosts.value = false;
          isLoadingDetails.value = false;
          update([AppPageIdConstants.mate]);
          return;
        }
        readingProgressMap.clear();
        totalMixedItems.clear();
        _clearPrivateEventData();
        mateUser = AppUser();
        mate.value.itemlists = Map.fromEntries(
          (mate.value.itemlists ?? <String, Itemlist>{}).entries.where(
            (entry) => entry.value.public,
          ),
        );
      }

      verificationLevel.value = mate.value.verificationLevel;

      // Always check for blog entries (independent of posts)
      _checkMateBlogEntries();

      if (!AppConfig.instance.canPersistUserActivity ||
          (mate.value.posts?.isNotEmpty ?? false)) {
        await getMatePosts();
      } else {
        isLoadingPosts.value = false;
      }

      if (AppConfig.instance.canPersistUserActivity &&
          ((mate.value.events?.isNotEmpty ?? false) ||
              (mate.value.goingEvents?.isNotEmpty ?? false) ||
              (mate.value.playingEvents?.isNotEmpty ?? false))) {
        await getTotalEvents();
      }

      for (var post in matePosts) {
        eventPosts[post] = events[post.referenceId] ?? Event();
      }

      instrumentsText = TextUtilities.getInstruments(
        mate.value.instruments ?? {},
      );

      await Future.wait([
        getAddressSimple(),
        getTotalInstruments(),
        getTotalItems(),
        if (AppConfig.instance.canPersistUserActivity) getReadingProgress(),
      ]);
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_mates',
        operation: 'retrieveDetails',
      );
    }

    isLoadingDetails.value = false;

    update([AppPageIdConstants.search]);
  }

  @override
  Future<void> getMatePosts() async {
    AppConfig.logger.d("getMatePosts");

    try {
      final retrievedPosts = await postFirestore.getProfilePosts(mate.value.id);
      matePosts.value = !AppConfig.instance.canPersistUserActivity
          ? retrievedPosts.where((post) => post.isPubliclyVisible).toList()
          : retrievedPosts;

      // Filter out blog entries and other non-displayable posts from matePosts
      matePosts.removeWhere((element) => element.type == PostType.blogEntry);
      matePosts.removeWhere((element) => element.type == PostType.caption);
      matePosts.removeWhere((element) => element.type == PostType.youtube);

      AppConfig.logger.d("${matePosts.length} Total Posts for Profile");

      // Check if mate has blog entries in the new BlogEntry collection
      await _checkMateBlogEntries();
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_mates',
        operation: 'getMatePosts',
      );
    }

    isLoadingPosts.value = false;
  }

  /// Check if mate has blog entries in the BlogEntry collection.
  /// Uses a simple limit(1) query to minimize Firestore reads.
  Future<void> _checkMateBlogEntries() async {
    // The guest catalogue has no public projection for legacy blog entries.
    if (PublicCatalogReadPolicy.enabled) {
      hasBlogEntries.value = false;
      return;
    }
    try {
      final mateId = mate.value.id;
      AppConfig.logger.d(
        "_checkMateBlogEntries: Checking for mateId=$mateId, mateName=${mate.value.name}",
      );

      if (mateId.isEmpty) {
        AppConfig.logger.w("_checkMateBlogEntries: mateId is empty, skipping");
        hasBlogEntries.value = false;
        return;
      }

      hasBlogEntries.value = await _blogPresenceLoader(mateId);
      AppConfig.logger.d(
        "_checkMateBlogEntries: hasBlogEntries=${hasBlogEntries.value} for $mateId",
      );
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_mates',
        operation: '_checkMateBlogEntries',
      );
      hasBlogEntries.value = false;
    }
  }

  void clear() {
    mates = <String, AppProfile>{};
  }

  @override
  Future<void> getAddressSimple() async {
    AppConfig.logger.t('getAddressSimple');

    try {
      if (profile.position != null &&
          mate.value.position != null &&
          mate.value.position!.latitude != 0 &&
          mate.value.position!.longitude != 0) {
        address =
            await geoLocatorServiceImpl?.getAddressSimple(
              mate.value.position!,
            ) ??
            '';
        distance = PositionUtilities.distanceBetweenPositionsRounded(
          profile.position!,
          mate.value.position!,
        );
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_mates',
        operation: 'getAddressSimple',
      );
    }

    AppConfig.logger.d("$address and $distance km");
  }

  @override
  Future<void> getTotalItems() async {
    AppConfig.logger.t("getTotalItems");

    final retrievedItemlists = await ItemlistFirestore().fetchAll(
      ownerId: mate.value.id,
      onlyPublic: true,
    );
    final isPublicReader = !AppConfig.instance.canPersistUserActivity;
    retrievedItemlists.removeWhere((_, itemlist) => !itemlist.public);
    mate.value.itemlists = retrievedItemlists;
    Map<String, AppMediaItem> totalMediaItems = {};
    Map<String, AppReleaseItem> totalReleaseItems = {};
    Map<String, ExternalItem> totalExternalItems = {};

    if (mate.value.itemlists?.isNotEmpty ?? false) {
      if (AppConfig.instance.appInUse == AppInUse.c) {
        mate.value.frequencies = await FrequencyFirestore().retrieveFrequencies(
          mate.value.id,
        );
        for (var freq in mate.value.frequencies!.values) {
          totalPresets[freq.frequency.toString()] = NeomChamberPreset.custom(
            frequency: freq,
          );
        }
        totalPresets.addAll(
          CoreUtilities.getTotalPresets(mate.value.chambers ?? {}),
        );
      } else {
        totalMediaItems = CoreUtilities.getTotalMediaItems(
          mate.value.itemlists!,
        );
        totalReleaseItems = CoreUtilities.getTotalReleaseItems(
          mate.value.itemlists!,
        );
        totalExternalItems = CoreUtilities.getTotalExternalItems(
          mate.value.itemlists!,
        );

        AppConfig.logger.d("${totalMixedItems.length} Total Items for Profile");
      }
    } else if (!isPublicReader &&
        (mate.value.favoriteItems?.isNotEmpty ?? false)) {
      totalMediaItems = await AppMediaItemFirestore().retrieveFromList(
        mate.value.favoriteItems!,
      );
      totalReleaseItems = await AppReleaseItemFirestore().retrieveFromList(
        mate.value.favoriteItems!,
      );
      totalExternalItems = await ExternalItemFirestore().retrieveFromList(
        mate.value.favoriteItems!,
      );
    }

    for (var item in totalReleaseItems.values) {
      totalMixedItems[item.id] = item;
    }

    for (var item in totalMediaItems.values) {
      totalMixedItems[item.id] = item;
    }

    for (var item in totalExternalItems.values) {
      totalMixedItems[item.id] = item;
    }

    AppConfig.logger.d("${totalMixedItems.length} Total Items for Profile");
    update([AppPageIdConstants.mate]);
  }

  Future<void> getReadingProgress() async {
    AppConfig.logger.d("getReadingProgress for mate ${mate.value.id}");

    if (!AppConfig.instance.canPersistUserActivity) {
      _clearPrivateReadingData();
      return;
    }

    try {
      if (mateUser.id.isEmpty) {
        mateUser = await UserFirestore().getByProfileId(mate.value.id);
      }

      if (!AppConfig.instance.canPersistUserActivity) {
        _clearPrivateReadingData();
        return;
      }

      if (mateUser.email.isEmpty) return;

      final sessions = await NupaleSessionFirestore().fetchByReaderEmail(
        mateUser.email,
      );
      if (!AppConfig.instance.canPersistUserActivity) {
        _clearPrivateReadingData();
        return;
      }
      if (sessions.isEmpty) return;

      final Map<String, List<NupaleSession>> grouped = {};
      for (final session in sessions.values) {
        grouped.putIfAbsent(session.itemId, () => []).add(session);
      }

      for (final entry in grouped.entries) {
        final progress = ReadingProgress.fromSessions(entry.key, entry.value);
        readingProgressMap[entry.key] = progress;

        if (!totalMixedItems.containsKey(entry.key)) {
          totalMixedItems[entry.key] = progress;
        }
      }

      // Enrich standalone ReadingProgress items with cover/author from item data
      final standaloneIds = readingProgressMap.keys
          .where((id) => totalMixedItems[id] is ReadingProgress)
          .toList();

      if (standaloneIds.isNotEmpty) {
        final releaseItems = await AppReleaseItemFirestore().retrieveFromList(
          standaloneIds,
        );
        final mediaItems = await AppMediaItemFirestore().retrieveFromList(
          standaloneIds,
        );
        final externalItems = await ExternalItemFirestore().retrieveFromList(
          standaloneIds,
        );

        if (!AppConfig.instance.canPersistUserActivity) {
          _clearPrivateReadingData();
          return;
        }

        for (final id in standaloneIds) {
          String imgUrl = '';
          String ownerName = '';

          if (releaseItems.containsKey(id)) {
            imgUrl = releaseItems[id]!.imgUrl;
            ownerName = releaseItems[id]!.ownerName;
          } else if (mediaItems.containsKey(id)) {
            imgUrl = mediaItems[id]!.imgUrl;
            ownerName = mediaItems[id]!.ownerName;
          } else if (externalItems.containsKey(id)) {
            imgUrl = externalItems[id]!.imgUrl;
            ownerName = externalItems[id]!.ownerName;
          }

          if (imgUrl.isNotEmpty || ownerName.isNotEmpty) {
            final enriched = readingProgressMap[id]!.copyWith(
              itemImgUrl: imgUrl,
              itemOwnerName: ownerName,
            );
            readingProgressMap[id] = enriched;
            totalMixedItems[id] = enriched;
          }
        }
      }

      if (!AppConfig.instance.canPersistUserActivity) {
        _clearPrivateReadingData();
        return;
      }
      AppConfig.logger.d(
        "${readingProgressMap.length} reading progress entries found",
      );
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_mates',
        operation: 'getReadingProgress',
      );
    }

    update([AppPageIdConstants.mate]);
  }

  void _clearPrivateReadingData() {
    readingProgressMap.clear();
    totalMixedItems.removeWhere((_, item) => item is ReadingProgress);
    mateUser = AppUser();
  }

  void _clearPrivateEventData() {
    events.clear();
    eventPosts.clear();
  }

  Future<void> getTotalEvents() async {
    AppConfig.logger.t("getTotalEvents for mate");

    if (!AppConfig.instance.canPersistUserActivity) {
      _clearPrivateEventData();
      update([AppPageIdConstants.mate]);
      return;
    }

    try {
      if (mate.value.events != null && mate.value.events!.isNotEmpty) {
        Map<String, Event> createdEvents = await EventFirestore().getEventsById(
          mate.value.events!,
        );
        AppConfig.logger.d(
          "${createdEvents.length} created events founds for mate ${mate.value.id}",
        );
        events.addAll(createdEvents);
      }

      if (mate.value.playingEvents != null &&
          mate.value.playingEvents!.isNotEmpty) {
        Map<String, Event> playingEvents = await EventFirestore().getEventsById(
          mate.value.playingEvents!,
        );
        AppConfig.logger.d(
          "${playingEvents.length} playing events founds for mate ${mate.value.id}",
        );
        events.addAll(playingEvents);
      }

      if (mate.value.goingEvents != null &&
          mate.value.goingEvents!.isNotEmpty) {
        Map<String, Event> goingEvents = await EventFirestore().getEventsById(
          mate.value.goingEvents!,
        );
        AppConfig.logger.d(
          "${goingEvents.length} going events founds for mate ${mate.value.id}",
        );
        events.addAll(goingEvents);
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_mates',
        operation: 'getTotalEvents',
      );
    }

    if (!AppConfig.instance.canPersistUserActivity) {
      _clearPrivateEventData();
    }

    AppConfig.logger.d("${events.length} Total Events for Itemmate");
    update([AppPageIdConstants.mate]);
  }

  @override
  Future<void> getTotalInstruments() async {
    AppConfig.logger.t('getTotalInstruments');

    // Instruments require a legacy profile-subcollection lookup. Public
    // profile fields are already loaded from the approved projection.
    if (PublicCatalogReadPolicy.enabled) return;

    try {
      mate.value.instruments = await _instrumentsLoader(mate.value.id);
      AppConfig.logger.t(
        "${mate.value.instruments?.length ?? 0} Total Instruments for Profile",
      );
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_mates',
        operation: 'getTotalInstruments',
      );
    }

    update([AppPageIdConstants.mate]);
  }

  @override
  Future<void> follow() async {
    if (_isClosed || !AppConfig.instance.canPersistUserActivity) return;
    final myId = resolveMateId(arguments: profile.id);
    final targetId = resolveMateId(arguments: mate.value.id);
    if (myId.isEmpty || targetId.isEmpty || myId == targetId) return;
    AppConfig.logger.t("Follow profile $targetId");
    following.value = true;
    try {
      if (await ProfileFirestore().followProfile(
        profileId: myId,
        followedProfileId: targetId,
      )) {
        final followers = mate.value.followers ??= <String>[];
        if (!followers.contains(profile.id)) {
          followers.add(profile.id);
        }

        try {
          if (userServiceImpl.profile.following != null) {
            if (!userServiceImpl.profile.following!.contains(mate.value.id)) {
              userServiceImpl.profile.following!.add(mate.value.id);
            }
          } else {
            userServiceImpl.profile.following = [mate.value.id];
          }
        } catch (e, st) {
          NeomErrorLogger.recordError(
            e,
            st,
            module: 'neom_mates',
            operation: 'follow.updateFollowing',
          );
        }

        ActivityFeed activityFeed = ActivityFeed();
        activityFeed.ownerId = mate.value.id;
        activityFeed.profileId = profile.id;
        activityFeed.createdTime = DateTime.now().millisecondsSinceEpoch;
        activityFeed.activityFeedType = ActivityFeedType.follow;
        activityFeed.profileName = profile.name;
        activityFeed.profileImgUrl = profile.photoUrl;
        activityFeed.activityReferenceId = profile.id;

        ActivityFeedFirestore().insert(activityFeed);

        FirebaseMessagingCalls.sendPrivatePushNotification(
          toProfileId: mate.value.id,
          fromProfile: profile,
          notificationType: PushNotificationType.following,
          title: CommonTranslationConstants.startedFollowingYou,
          message: '',
          referenceId: profile.id,
        );

        ///VERIFY COSTS OF PUBLIC PUSH NOTIFICATIONS
        // FirebaseMessagingCalls.sendPublicPushNotification(
        //   fromProfile: profile,
        //   toProfileId: mate.value.id,
        //   title: "${MateTranslationConstants.isFollowingTo.tr} ${mate.value.name}",
        //   notificationType: PushNotificationType.following,
        //   referenceId: mate.value.id,
        // );
      } else {
        following.value = false;
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_mates',
        operation: 'follow',
      );
    }

    update([AppPageIdConstants.mate]);
  }

  @override
  Future<void> unfollow() async {
    if (_isClosed || !AppConfig.instance.canPersistUserActivity) return;
    final myId = resolveMateId(arguments: profile.id);
    final targetId = resolveMateId(arguments: mate.value.id);
    if (myId.isEmpty || targetId.isEmpty || myId == targetId) return;
    AppConfig.logger.t("Unfollow $targetId");
    following.value = false;
    try {
      if (await ProfileFirestore().unfollowProfile(
        profileId: myId,
        unfollowProfileId: targetId,
      )) {
        if (userServiceImpl.profile.following != null) {
          if (userServiceImpl.profile.following!.contains(targetId)) {
            userServiceImpl.profile.following!.remove(targetId);
          }
        }
        mate.value.followers?.remove(myId);
      } else if (!_isClosed) {
        following.value = true;
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_mates',
        operation: 'unfollow',
      );
    }

    if (!_isClosed) {
      update([AppPageIdConstants.mate, AppPageIdConstants.profile]);
    }
  }

  @override
  Future<void> blockProfile() async {
    if (_isClosed || !AppConfig.instance.canPersistUserActivity) return;
    final myId = resolveMateId(arguments: profile.id);
    final targetId = resolveMateId(arguments: mate.value.id);
    if (myId.isEmpty || targetId.isEmpty || myId == targetId) return;
    AppConfig.logger.d("");
    try {
      if (await ProfileFirestore().blockProfile(
        profileId: myId,
        profileToBlock: targetId,
      )) {
        if (!_isClosed) {
          following.value = false;
        }
        userServiceImpl.profile.following?.remove(targetId);
        mate.value.followers?.remove(myId);
        mate.value.blockedBy?.add(myId);

        final blockTo = userServiceImpl.profile.blockTo ??= <String>[];
        if (!blockTo.contains(targetId)) {
          blockTo.add(targetId);
        }

        AppUtilities.showSnackBar(
          title: CommonTranslationConstants.blockProfile.tr,
          message: MessageTranslationConstants.blockedProfileMsg.tr,
        );
      } else {
        AppConfig.logger.i("Something happened while blocking profile");
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_mates',
        operation: 'blockProfile',
      );
    }

    Sint.back();
    Sint.back();
    if (!_isClosed) {
      update([AppPageIdConstants.mate, AppPageIdConstants.profile]);
    }
  }

  @override
  Future<void> unblockProfile(String profileId) async {
    if (_isClosed || !AppConfig.instance.canPersistUserActivity) return;
    final myId = resolveMateId(arguments: userServiceImpl.profile.id);
    final cleanTargetId = resolveMateId(arguments: profileId);
    if (myId.isEmpty || cleanTargetId.isEmpty) return;
    AppConfig.logger.d("");
    try {
      if (await ProfileFirestore().unblockProfile(
        profileId: myId,
        profileToUnblock: cleanTargetId,
      )) {
        userServiceImpl.profile.blockTo?.remove(cleanTargetId);
        AppUtilities.showSnackBar(
          title: CommonTranslationConstants.unblockProfile.tr,
          message: MateTranslationConstants.unblockedProfileMsg.tr,
        );
      } else {
        AppConfig.logger.i("Somethnig happened while unblocking profile");
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_mates',
        operation: 'unblockProfile',
      );
    }

    Sint.back();
    if (!_isClosed) {
      update([AppPageIdConstants.mate, AppPageIdConstants.profile]);
    }
  }

  @override
  Future<void> sendMessage() async {
    if (!AppConfig.instance.canPersistUserActivity) return;
    AppConfig.logger.d("");

    Inbox inbox = Inbox();

    try {
      inbox = await InboxFirestore().getOrCreateInboxRoom(profile, mate.value);

      inbox.id.isNotEmpty
          ? Sint.toNamed(AppRouteConstants.inboxRoom, arguments: [inbox])
          : Sint.toNamed(AppRouteConstants.home);
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_mates',
        operation: 'sendMessage',
      );
    }
  }

  @override
  Future<void> removeProfile() async {
    if (!AppConfig.instance.canPersistUserActivity) return;
    AppConfig.logger.d("Remove Profile from Application - Admin Function");
    try {
      AppUser userFromProfile = await UserFirestore().getByProfileId(
        mate.value.id,
      );

      if (await ProfileFirestore().remove(
        userId: userFromProfile.id,
        profileId: mate.value.id,
      )) {
        if (following.value) {
          ProfileFirestore().unfollowProfile(
            profileId: profile.id,
            unfollowProfileId: mate.value.id,
          );
          userServiceImpl.profile.following?.remove(mate.value.id);
        }

        AppUtilities.showSnackBar(
          title: CommonTranslationConstants.removeProfile.tr,
          message: MateTranslationConstants.removedProfileMsg.tr,
        );
      } else {
        AppConfig.logger.i("Something happened while removing profile");
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_mates',
        operation: 'removeProfile',
      );
    }

    Sint.back();
    Sint.back();
    update([
      AppPageIdConstants.mate,
      AppPageIdConstants.profile,
      AppPageIdConstants.home,
    ]);
  }

  @override
  void selectVerificationLevel(VerificationLevel level) {
    try {
      verificationLevel.value = level;
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_mates',
        operation: 'selectVerificationLevel',
      );
    }
  }

  @override
  Future<void> updateVerificationLevel() async {
    if (!AppConfig.instance.canPersistUserActivity) return;
    try {
      if (await ProfileFirestore().updateVerificationLevel(
        mate.value.id,
        verificationLevel.value,
      )) {
        mate.value.verificationLevel = verificationLevel.value;
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_mates',
        operation: 'updateVerificationLevel',
      );
    }

    update([AppPageIdConstants.mate]);
  }

  @override
  void selectUserRole(UserRole role) {
    try {
      newUserRole.value = role;
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_mates',
        operation: 'selectUserRole',
      );
    }
  }

  @override
  Future<void> updateUserRole() async {
    if (!AppConfig.instance.canPersistUserActivity) return;
    try {
      if (newUserRole.value != mateUser.userRole && mateUser.id.isNotEmpty) {
        await UserFirestore().updateUserRole(mateUser.id, newUserRole.value);
        Sint.back();
        AppUtilities.showSnackBar(
          title: MateTranslationConstants.updateUserRole.tr,
          message: MateTranslationConstants.updateUserRoleSuccess.tr,
        );
      } else {
        AppUtilities.showSnackBar(
          title: MateTranslationConstants.updateUserRoleSame.tr,
          message: MateTranslationConstants.updateUserRoleSame.tr,
        );
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_mates',
        operation: 'updateUserRole',
      );
    }
  }

  Future<void> getUserInfo() async {
    if (!AppConfig.instance.canPersistUserActivity) {
      mateUser = AppUser();
      return;
    }

    try {
      mateUser = await UserFirestore().getByProfileId(mate.value.id);
      newUserRole.value = mateUser.userRole;
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_mates',
        operation: 'getUserInfo',
      );
    }

    update([AppPageIdConstants.mate]);
  }
}
