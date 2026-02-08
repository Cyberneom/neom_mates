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
import 'package:neom_core/data/firestore/event_firestore.dart';
import 'package:neom_core/data/firestore/external_item_firestore.dart';
import 'package:neom_core/data/firestore/frequency_firestore.dart';
import 'package:neom_core/data/firestore/inbox_firestore.dart';
import 'package:neom_core/data/firestore/instrument_firestore.dart';
import 'package:neom_core/data/firestore/itemlist_firestore.dart';
import 'package:neom_core/data/firestore/post_firestore.dart';
import 'package:neom_core/data/firestore/profile_firestore.dart';
import 'package:neom_core/data/firestore/user_firestore.dart';
import 'package:neom_core/domain/model/activity_feed.dart';
import 'package:neom_core/domain/model/app_media_item.dart';
import 'package:neom_core/domain/model/app_profile.dart';
import 'package:neom_core/domain/model/app_release_item.dart';
import 'package:neom_core/domain/model/app_user.dart';
import 'package:neom_core/domain/model/event.dart';
import 'package:neom_core/domain/model/external_item.dart';
import 'package:neom_core/domain/model/inbox.dart';
import 'package:neom_core/domain/model/neom/neom_chamber_preset.dart';
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
import 'package:neom_core/utils/position_utilities.dart';
import 'package:neom_profile/neom_profile.dart';
import 'package:sint/sint.dart';

import '../../domain/use_cases/mate_details_service.dart';
import '../../utils/constants/mate_translation_constants.dart';

class MateDetailsController extends SintController implements MateDetailsService {

  final userServiceImpl = Sint.find<UserService>();
  final geoLocatorServiceImpl = Sint.find<GeoLocatorService>();
  final profileCacheController = ProfileCacheController();

  Map<String, AppProfile> mates = <String, AppProfile>{};
  Rx<AppProfile> mate = AppProfile().obs;

  AppProfile profile = AppProfile();

  PostFirestore postFirestore = PostFirestore();

  String address = "";
  String instrumentsText = "";
  int distance = 0;

  RxMap<String, NeomChamberPreset> totalPresets = <String, NeomChamberPreset>{}.obs;
  RxMap<String, dynamic>  totalMixedItems = <String, dynamic>{}.obs;

  RxBool following = false.obs;
  bool blockedProfile = false;

  RxMap<Post, Event> eventPosts = <Post, Event>{}.obs;
  RxMap<String, Event> events = <String, Event>{}.obs;
  
  RxBool isLoading = true.obs;
  RxBool isLoadingDetails = true.obs;
  RxBool isLoadingPosts = true.obs;

  RxList<Post> matePosts = <Post>[].obs;
  List<Post> mateBlogEntries = <Post>[];

  bool debugPushNotifications = false;

  final Rx<VerificationLevel> verificationLevel = VerificationLevel.none.obs;
  final Rx<UserRole> newUserRole = UserRole.subscriber.obs;
  AppUser mateUser = AppUser();

  @override
  void onInit() {
    super.onInit();
    AppConfig.logger.t("onInit");

    String mateId = '';

    if(Sint.arguments != null && Sint.arguments.isNotEmpty) {
      if (Sint.arguments is List) {
        mateId = Sint.arguments[0];
      } else if (Sint.arguments is AppProfile) {
        mateId = (Sint.arguments as AppProfile).id;
      } else {
        mateId = Sint.arguments ?? "";
      }
    }

    try {
      profile = userServiceImpl.profile;
      blockedProfile = profile.blockTo?.contains(mateId) ?? false;

      if(mateId.isNotEmpty && !blockedProfile) {
        loadMate(mateId);
      } else {
        AppConfig.logger.i("Profile $mateId is blocked");
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }
  }


  @override
  void onReady() {
    super.onReady();
    AppConfig.logger.d("MateDetails Controller Ready");
    try {
      sendViewProfileNotification();
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }
  }

  @override
  void onClose() {
    // FIXED: Clean up resources to prevent memory leaks
    // Close reactive collections
    totalPresets.close();
    totalMixedItems.close();
    eventPosts.close();
    events.close();
    matePosts.close();
    following.close();
    isLoading.close();
    isLoadingDetails.close();
    isLoadingPosts.close();
    mate.close();
    super.onClose();
  }


  @override
  Future<void> loadMate(String id) async {
    AppConfig.logger.d("loadMate $id");

    try {
      // Try to load from cache first for instant display
      final cachedProfile = await profileCacheController.getCachedProfile(id);
      if (cachedProfile != null) {
        AppConfig.logger.d("Loaded profile from cache: $id");
        mate.value = cachedProfile;
        following.value = profile.following?.contains(mate.value.id) ?? false;
        isLoading.value = false;
        // Continue loading fresh data in background
      }

      // Fetch fresh data from network
      try {
        final freshProfile = await ProfileFirestore().retrieve(id);
        if (freshProfile.id.isNotEmpty) {
          mate.value = freshProfile;
          // Cache the profile for offline access
          await profileCacheController.cacheProfile(freshProfile);
          retrieveDetails();
          following.value = profile.following?.contains(mate.value.id) ?? false;
        }
      } catch (e) {
        AppConfig.logger.w("Network error loading profile, using cache: $e");
        // If we have cached data, continue with it
        if (mate.value.id.isNotEmpty) {
          retrieveDetails();
        }
      }

      isLoading.value = false;
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }
  }

  void sendViewProfileNotification() {
    if(mate.value.id.isNotEmpty && (userServiceImpl.user.userRole == UserRole.subscriber) || debugPushNotifications) {
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
        title: "${MateTranslationConstants.viewedProfileOf.tr} ${mate.value.name}",
        referenceId: mate.value.id,
      );
    }
  }


  @override
  Future<void> retrieveDetails() async {
    AppConfig.logger.d("retrieveDetails");
    try {
      verificationLevel.value = mate.value.verificationLevel;

      if(mate.value.posts?.isNotEmpty ?? false) {
        await getMatePosts();
      } else {
        isLoadingPosts.value = false;
      }

      if((mate.value.events?.isNotEmpty ?? false)
          || (mate.value.goingEvents?.isNotEmpty ?? false)
          || (mate.value.playingEvents?.isNotEmpty ?? false)) {
        getTotalEvents();
      }

      for (var post in matePosts) {
        eventPosts[post] = events[post.referenceId] ?? Event();
      }

      instrumentsText = TextUtilities.getInstruments(mate.value.instruments ?? {});

      Future.wait([
        getAddressSimple(),
        getTotalInstruments(),
        getTotalItems(),
      ]);

    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    isLoadingDetails.value = false;

    update([AppPageIdConstants.search]);
  }


  @override
  Future<void> getMatePosts() async {
    AppConfig.logger.d("getMatePosts");

    try {
      matePosts.value = await postFirestore.getProfilePosts(mate.value.id);

      for (var post in matePosts) {
        if(post.type == PostType.blogEntry && !post.isDraft) {
          mateBlogEntries.add(post);
        }
      }
      matePosts.removeWhere((element) => element.type == PostType.blogEntry);
      matePosts.removeWhere((element) => element.type == PostType.caption);
      matePosts.removeWhere((element) => element.type == PostType.youtube);
      AppConfig.logger.d("${mateBlogEntries.length} Total Blog Entries for Profile");
      AppConfig.logger.d("${matePosts.length} Total Posts for Profile");
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    isLoadingPosts.value = false;
  }


  void clear() {
    mates = <String, AppProfile>{};
  }


  @override
  Future<void> getAddressSimple() async {
    AppConfig.logger.t('getAddressSimple');

    try {
      if(profile.position != null && mate.value.position != null
          && mate.value.position!.latitude != 0 && mate.value.position!.longitude != 0) {
        address = await geoLocatorServiceImpl.getAddressSimple(mate.value.position!);
        distance = PositionUtilities.distanceBetweenPositionsRounded(profile.position!, mate.value.position!);
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    AppConfig.logger.d("$address and $distance km");
  }

  @override
  Future<void> getTotalItems() async {
    AppConfig.logger.t("getTotalItems");

    mate.value.itemlists = await ItemlistFirestore().fetchAll(ownerId: mate.value.id);
    Map<String, AppMediaItem> totalMediaItems = {};
    Map<String, AppReleaseItem> totalReleaseItems = {};
    Map<String, ExternalItem> totalExternalItems = {};

    if(mate.value.itemlists?.isNotEmpty ?? false) {
      if(AppConfig.instance.appInUse == AppInUse.c) {
        mate.value.frequencies = await FrequencyFirestore().retrieveFrequencies(mate.value.id);
        for (var freq in mate.value.frequencies!.values) {
          totalPresets[freq.frequency.toString()] = NeomChamberPreset.custom(frequency: freq);
        }
        totalPresets.addAll(CoreUtilities.getTotalPresets(mate.value.chambers!));
      } else {
        totalMediaItems = CoreUtilities.getTotalMediaItems(mate.value.itemlists!);
        totalReleaseItems = CoreUtilities.getTotalReleaseItems(mate.value.itemlists!);
        totalExternalItems = CoreUtilities.getTotalExternalItems(mate.value.itemlists!);

        AppConfig.logger.d("${totalMixedItems.length} Total Items for Profile" );
      }
    } else if(mate.value.favoriteItems?.isNotEmpty ?? false){
      totalMediaItems = await AppMediaItemFirestore().retrieveFromList(mate.value.favoriteItems!);
      totalReleaseItems = await AppReleaseItemFirestore().retrieveFromList(mate.value.favoriteItems!);
      totalExternalItems = await ExternalItemFirestore().retrieveFromList(mate.value.favoriteItems!);
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

  Future<void> getTotalEvents()  async{
    AppConfig.logger.t("getTotalEvents for mate");

    try {
      if(mate.value.events != null && mate.value.events!.isNotEmpty) {
        Map<String, Event> createdEvents = await EventFirestore().getEventsById(mate.value.events!);
        AppConfig.logger.d("${createdEvents.length} created events founds for mate ${mate.value.id}");
        events.addAll(createdEvents);
      }

      if(mate.value.playingEvents != null && mate.value.playingEvents!.isNotEmpty) {
        Map<String, Event> playingEvents = await EventFirestore().getEventsById(mate.value.playingEvents!);
        AppConfig.logger.d("${playingEvents.length} playing events founds for mate ${mate.value.id}");
        events.addAll(playingEvents);
      }

      if(mate.value.goingEvents != null && mate.value.goingEvents!.isNotEmpty) {
        Map<String, Event> goingEvents = await EventFirestore().getEventsById(mate.value.goingEvents!);
        AppConfig.logger.d("${goingEvents.length} going events founds for mate ${mate.value.id}");
        events.addAll(goingEvents);
      }

    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    AppConfig.logger.d("${events.length} Total Events for Itemmate");
    update([AppPageIdConstants.mate]);
  }


  @override
  Future<void> getTotalInstruments() async {
    AppConfig.logger.t('getTotalInstruments');

    try {
      mate.value.instruments = await InstrumentFirestore().retrieveInstruments(mate.value.id);
      AppConfig.logger.t("${mate.value.instruments?.length ?? 0} Total Instruments for Profile");
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    update([AppPageIdConstants.mate]);
  }

  @override
  Future<void> follow() async {
    AppConfig.logger.t("Follow profile ${mate.value.id}");
    following.value = true;
    try {
      if(await ProfileFirestore().followProfile(profileId: profile.id, followedProfileId:  mate.value.id)) {
        mate.value.followers!.add(profile.id);

        try {
          if(userServiceImpl.profile.following != null) {
            if(!userServiceImpl.profile.following!.contains(mate.value.id)) {
              userServiceImpl.profile.following!.add(mate.value.id);
            }
          } else {
            userServiceImpl.profile.following = [mate.value.id];
          }

        } catch (e) {
          AppConfig.logger.e(e.toString());
        }

        ActivityFeed activityFeed = ActivityFeed();
        activityFeed.ownerId =  mate.value.id;
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

        FirebaseMessagingCalls.sendPublicPushNotification(
          fromProfile: profile,
          toProfileId: mate.value.id,
          title: "${MateTranslationConstants.isFollowingTo.tr} ${mate.value.name}",
          notificationType: PushNotificationType.following,
          referenceId: mate.value.id,
        );

      } else {
        following.value = false;
      }

    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    update([AppPageIdConstants.mate]);
  }


  @override
  Future<void> unfollow() async {
    AppConfig.logger.t("Unfollow ${mate.value.id}");
    following.value = false;
    try {
      if (await ProfileFirestore().unfollowProfile(profileId: profile.id,unfollowProfileId:  mate.value.id)) {

        if(userServiceImpl.profile.following != null) {
          if(userServiceImpl.profile.following!.contains(mate.value.id)) {
            userServiceImpl.profile.following!.remove(mate.value.id);
          }
        }
        mate.value.followers!.remove(profile.id,);
      } else {
        following.value = true;
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    update([AppPageIdConstants.mate, AppPageIdConstants.profile]);
  }


  @override
  Future<void> blockProfile() async {
    AppConfig.logger.d("");
    try {
      if (await ProfileFirestore().blockProfile(
          profileId: profile.id, profileToBlock: mate.value.id)) {
        following.value = false;
        userServiceImpl.profile.following!.remove(mate.value.id);
        mate.value.followers?.remove(profile.id);
        mate.value.blockedBy?.add(profile.id);

        userServiceImpl.profile.blockTo!.add(mate.value.id);

        AppUtilities.showSnackBar(
            title: CommonTranslationConstants.blockProfile.tr,
            message: MessageTranslationConstants.blockedProfileMsg.tr);
      } else {
        AppConfig.logger.i("Something happened while blocking profile");
      }
    } catch (e) {
        AppConfig.logger.e(e.toString());
    }

    Sint.back();
    Sint.back();
    update([AppPageIdConstants.mate, AppPageIdConstants.profile]);
  }

  @override
  Future<void> unblockProfile(String profileId) async {
    AppConfig.logger.d("");
    try {
      if (await ProfileFirestore().unblockProfile(profileId: userServiceImpl.profile.id, profileToUnblock:  profileId)) {
        userServiceImpl.profile.blockTo!.remove(profileId);
        AppUtilities.showSnackBar(
            title: CommonTranslationConstants.unblockProfile.tr,
            message: MateTranslationConstants.unblockedProfileMsg.tr
        );
      } else {
        AppConfig.logger.i("Somethnig happened while unblocking profile");
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    Sint.back();
    update([AppPageIdConstants.mate, AppPageIdConstants.profile]);
  }

  @override
  Future<void> sendMessage() async {
    AppConfig.logger.d("");

    Inbox inbox = Inbox();

    try {
      inbox = await InboxFirestore().getOrCreateInboxRoom(profile, mate.value);

      inbox.id.isNotEmpty ? Sint.toNamed(AppRouteConstants.inboxRoom, arguments: [inbox])
        : Sint.toNamed(AppRouteConstants.home);
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }
  }

  @override
  Future<void> removeProfile() async {
    AppConfig.logger.d("Remove Profile from Application - Admin Function");
    try {
      AppUser userFromProfile = await UserFirestore().getByProfileId(mate.value.id);

      if (await ProfileFirestore().remove(userId: userFromProfile.id, profileId: mate.value.id)) {
        if(following.value) {
          ProfileFirestore().unfollowProfile(profileId: profile.id, unfollowProfileId: mate.value.id);
          userServiceImpl.profile.following!.remove(mate.value.id);
        }

        AppUtilities.showSnackBar(
          title: CommonTranslationConstants.removeProfile.tr,
          message: MateTranslationConstants.removedProfileMsg.tr
        );
      } else {
        AppConfig.logger.i("Something happened while removing profile");
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    Sint.back();
    Sint.back();
    update([AppPageIdConstants.mate, AppPageIdConstants.profile, AppPageIdConstants.home]);
  }

  @override
  void selectVerificationLevel(VerificationLevel level) {
    try {
      verificationLevel.value = level;
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }
  }

  @override
  Future<void> updateVerificationLevel() async {
    try {
      if(await ProfileFirestore().updateVerificationLevel(mate.value.id, verificationLevel.value)) {
        mate.value.verificationLevel = verificationLevel.value;
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    update([AppPageIdConstants.mate]);
  }

  @override
  void selectUserRole(UserRole role) {
    try {
      newUserRole.value = role;
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }
  }

  @override
  Future<void> updateUserRole() async {
    try {
      if(newUserRole.value != mateUser.userRole && mateUser.id.isNotEmpty) {
        await UserFirestore().updateUserRole(mateUser.id, newUserRole.value);
        Sint.back();
        AppUtilities.showSnackBar(
            title: MateTranslationConstants.updateUserRole.tr,
            message: MateTranslationConstants.updateUserRoleSuccess.tr);
      } else {
        AppUtilities.showSnackBar(
            title: MateTranslationConstants.updateUserRoleSame.tr,
            message: MateTranslationConstants.updateUserRoleSame.tr);
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

  }

  Future<void> getUserInfo() async {

    try {
      mateUser = await UserFirestore().getByProfileId(mate.value.id);
      newUserRole.value = mateUser.userRole;
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    update([AppPageIdConstants.mate]);
  }

}
