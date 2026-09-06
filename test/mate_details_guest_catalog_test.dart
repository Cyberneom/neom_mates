import 'package:firebase_auth/firebase_auth.dart' as fba;
import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/data/firestore/post_firestore.dart';
import 'package:neom_core/domain/model/app_profile.dart';
import 'package:neom_core/domain/model/app_release_item.dart';
import 'package:neom_core/domain/model/app_user.dart';
import 'package:neom_core/domain/model/instrument.dart';
import 'package:neom_core/domain/model/post.dart';
import 'package:neom_core/domain/use_cases/geolocator_service.dart';
import 'package:neom_core/domain/use_cases/login_service.dart';
import 'package:neom_core/domain/use_cases/user_service.dart';
import 'package:neom_core/utils/enums/app_in_use.dart';
import 'package:neom_core/utils/enums/auth_status.dart';
import 'package:neom_core/utils/enums/post_type.dart';
import 'package:neom_mates/ui/mate_details/mate_details_controller.dart';
import 'package:sint/sint.dart';

class _UserService extends Fake implements UserService {
  @override
  final user = AppUser(id: 'account');

  @override
  final profile = AppProfile(id: 'viewer');
}

class _GeoLocatorService extends Fake implements GeoLocatorService {}

class _FirebaseUser extends Fake implements fba.User {}

class _LoginService extends Fake implements LoginService {
  @override
  AuthStatus getAuthStatus() => AuthStatus.loggedIn;

  @override
  fba.User get fbaUser => _FirebaseUser();
}

class _Posts extends Fake implements PostFirestore {
  int reads = 0;

  @override
  Future<List<Post>> getProfilePosts(String profileId, {int limit = 20}) async {
    reads++;
    return [Post(id: 'public-post', ownerId: profileId, type: PostType.image)];
  }
}

class _Controller extends MateDetailsController {
  _Controller({
    required super.postFirestore,
    required super.profileLoader,
    required super.blogPresenceLoader,
    required super.instrumentsLoader,
  });

  int itemReads = 0;

  // Catalogue repositories have their own public-source tests. Keep these
  // unrelated reads in memory while exercising the real detail orchestration.
  @override
  Future<void> getTotalItems() async {
    itemReads++;
    totalMixedItems['public-release'] = AppReleaseItem(id: 'public-release');
  }

  @override
  Future<void> getAddressSimple() async {}

  @override
  Future<void> getReadingProgress() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final config = AppConfig.instance;
  late AppInUse previousApp;
  late bool previousGuestMode;
  late _Posts posts;
  late _Controller controller;
  late int profileReads;
  late int blogReads;
  late int instrumentReads;

  setUp(() {
    previousApp = config.appInUse;
    previousGuestMode = config.isGuestMode;
    Sint.reset();
    config.appInUse = AppInUse.g;
    config.isGuestMode = true;
    Sint.put<UserService>(_UserService());
    Sint.put<GeoLocatorService>(_GeoLocatorService());
    posts = _Posts();
    profileReads = blogReads = instrumentReads = 0;
    controller = _Controller(
      postFirestore: posts,
      profileLoader: (_) async {
        profileReads++;
        return AppProfile();
      },
      blogPresenceLoader: (_) async {
        blogReads++;
        return true;
      },
      instrumentsLoader: (_) async {
        instrumentReads++;
        return {'guitar': Instrument(name: 'guitar')};
      },
    );
    controller.mate.value = AppProfile(
      id: 'public-artist',
      name: 'Public artist',
      directoryVisible: true,
      posts: ['public-post'],
    );
  });

  tearDown(() {
    controller.onClose();
    Sint.reset();
    config.appInUse = previousApp;
    config.isGuestMode = previousGuestMode;
  });

  test(
    'Gigmeout guest details load public posts and items without legacy reads',
    () async {
      controller.hasBlogEntries.value = true;

      await controller.retrieveDetails();
      await controller.getTotalInstruments();

      expect(controller.mate.value.id, 'public-artist');
      expect(posts.reads, 1);
      expect(controller.matePosts.single.id, 'public-post');
      expect(controller.itemReads, 1);
      expect(controller.totalMixedItems.keys, ['public-release']);
      expect(blogReads, 0);
      expect(instrumentReads, 0);
      expect(controller.hasBlogEntries.value, isFalse);
      expect(controller.isLoadingPosts.value, isFalse);
      expect(controller.isLoadingDetails.value, isFalse);
    },
  );

  test('a missing public profile finishes all loading states', () async {
    await controller.loadMate('missing-public-profile');

    expect(profileReads, 1);
    expect(controller.mate.value.id, isEmpty);
    expect(controller.isLoading.value, isFalse);
    expect(controller.isLoadingPosts.value, isFalse);
    expect(controller.isLoadingDetails.value, isFalse);
    expect(posts.reads, 0);
    expect(controller.itemReads, 0);
    expect(blogReads, 0);
    expect(instrumentReads, 0);
  });

  test('other apps retain their existing blog and instrument reads', () async {
    config.appInUse = AppInUse.e;

    await controller.retrieveDetails();

    expect(blogReads, greaterThan(0));
    expect(instrumentReads, 1);
    expect(controller.hasBlogEntries.value, isTrue);
    expect(controller.mate.value.instruments?.keys, ['guitar']);
    expect(posts.reads, 1);
    expect(controller.itemReads, 1);
  });

  test(
    'authenticated Gigmeout keeps public details without legacy reads',
    () async {
      config.isGuestMode = false;
      Sint.put<LoginService>(_LoginService());
      expect(config.canPersistUserActivity, isTrue);

      await controller.retrieveDetails();

      expect(blogReads, 0);
      expect(instrumentReads, 0);
      expect(controller.hasBlogEntries.value, isFalse);
      expect(controller.mate.value.instruments, anyOf(isNull, isEmpty));
      expect(posts.reads, 1);
      expect(controller.itemReads, 1);
      expect(config.isGuestMode, isFalse);
      expect(config.canPersistUserActivity, isTrue);
    },
  );
}
