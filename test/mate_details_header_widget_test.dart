import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neom_commons/ui/widgets/animated_follow_button.dart';
import 'package:neom_commons/utils/constants/app_page_id_constants.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/data/firestore/post_firestore.dart';
import 'package:neom_core/domain/model/app_profile.dart';
import 'package:neom_core/domain/model/app_user.dart';
import 'package:neom_core/domain/model/collective.dart';
import 'package:neom_core/domain/model/instrument.dart';
import 'package:neom_core/domain/model/post.dart';
import 'package:neom_core/domain/use_cases/geolocator_service.dart';
import 'package:neom_core/domain/use_cases/user_service.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_core/utils/enums/app_in_use.dart';
import 'package:neom_mates/ui/mate_details/header/mate_details_header.dart';
import 'package:neom_mates/ui/mate_details/mate_details_body.dart';
import 'package:neom_mates/ui/mate_details/mate_details_controller.dart';
import 'package:neom_mates/utils/constants/mate_translation_constants.dart';
import 'package:sint/sint.dart';

class _FakeUserService extends Fake implements UserService {
  @override
  final AppUser user = AppUser(id: 'viewer-user');

  @override
  final AppProfile profile = AppProfile(id: 'viewer-profile', name: 'Viewer');
}

class _FakeGeoLocatorService extends Fake implements GeoLocatorService {}

class _FakePosts extends Fake implements PostFirestore {
  @override
  Future<List<Post>> getProfilePosts(String profileId, {int limit = 20}) async =>
      <Post>[];
}

class _TestMateDetailsController extends MateDetailsController {
  _TestMateDetailsController({
    required super.postFirestore,
    required super.profileLoader,
    required super.blogPresenceLoader,
    required super.instrumentsLoader,
    required super.collectivesLoader,
  });

  int matePageUpdates = 0;

  @override
  void update([List<Object>? ids, bool condition = true]) {
    if (ids != null && ids.contains(AppPageIdConstants.mate)) {
      matePageUpdates++;
    }
    super.update(ids, condition);
  }

  @override
  Future<void> getTotalItems() async {}

  @override
  Future<void> getAddressSimple() async {}

  @override
  Future<void> getReadingProgress() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppInUse previousApp;
  late bool previousGuestMode;

  setUp(() {
    previousApp = AppConfig.instance.appInUse;
    previousGuestMode = AppConfig.instance.isGuestMode;
    Sint.reset();
    AppConfig.instance.appInUse = AppInUse.g;
    AppConfig.instance.isGuestMode = true;
    Sint.put<UserService>(_FakeUserService());
    Sint.put<GeoLocatorService>(_FakeGeoLocatorService());
  });

  tearDown(() {
    Sint.reset();
    AppConfig.instance.appInUse = previousApp;
    AppConfig.instance.isGuestMode = previousGuestMode;
  });

  _TestMateDetailsController buildController({
    Future<AppProfile> Function(String)? profileLoader,
    Future<bool> Function(String)? blogPresenceLoader,
  }) {
    return _TestMateDetailsController(
      postFirestore: _FakePosts(),
      profileLoader: profileLoader ?? (_) async => AppProfile(),
      blogPresenceLoader: blogPresenceLoader ?? (_) async => false,
      instrumentsLoader: (_) async => <String, Instrument>{},
      collectivesLoader: (_) async => <String, Collective>{},
    );
  }

  testWidgets(
    'real MateDetailHeader renders on Gigmeout (AppInUse.g) with zero ObxError and within viewport height',
    (tester) async {
      AppConfig.instance.appInUse = AppInUse.g;
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(400, 844);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final capturedErrors = <FlutterErrorDetails>[];
      final previousOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        capturedErrors.add(details);
      };
      addTearDown(() => FlutterError.onError = previousOnError);

      final controller = buildController();
      controller.mate.value = AppProfile(
        id: 'mate-g-1',
        name: 'Estudio Sonoro',
        aboutMe: 'Estudio de grabación en Guadalajara',
        mainFeature: 'recordingStudio',
        directoryVisible: true,
      );
      controller.isLoading.value = false;
      controller.hasBlogEntries.value = false;
      Sint.put<MateDetailsController>(controller);

      await tester.pumpWidget(
        const SintMaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MateDetailHeader(),
                  Padding(
                    padding: EdgeInsets.all(20),
                    child: MateDetailsBody(),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(tester.takeException(), isNull);
      expect(
        capturedErrors,
        isEmpty,
        reason: 'MateDetailHeader must never throw ObxError on AppInUse.g',
      );
      expect(find.byType(ErrorWidget), findsNothing);

      // Header renders within normal height (not blown out to 100,000 px).
      final headerRect = tester.getRect(find.byType(MateDetailHeader));
      expect(headerRect.height, greaterThan(100));
      expect(headerRect.height, lessThan(500));

      // Avatar, follow/message buttons, and mate's name are all on-screen.
      final avatarFinder = find.byType(CircleAvatar);
      final followFinder = find.byType(AnimatedFollowButton);
      final messageFinder = find.byType(AnimatedMessageButton);
      final nameFinder = find.text('Estudio Sonoro');

      expect(avatarFinder, findsOneWidget);
      expect(followFinder, findsOneWidget);
      expect(messageFinder, findsOneWidget);
      expect(nameFinder, findsOneWidget);

      expect(tester.getRect(avatarFinder).bottom, lessThanOrEqualTo(844));
      expect(tester.getRect(followFinder).bottom, lessThanOrEqualTo(844));
      expect(tester.getRect(messageFinder).bottom, lessThanOrEqualTo(844));
      expect(tester.getRect(nameFinder).top, greaterThanOrEqualTo(0));
      expect(tester.getRect(nameFinder).bottom, lessThanOrEqualTo(844));

      // Blog CTA stays hidden on Gigmeout.
      expect(find.text(MateTranslationConstants.checkMyBlog.tr), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'real MateDetailHeader shows blog button on AppInUse.e when hasBlogEntries is true',
    (tester) async {
      AppConfig.instance.appInUse = AppInUse.e;
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(400, 844);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = buildController();
      controller.mate.value = AppProfile(
        id: 'mate-e-1',
        name: 'Autora Blog',
        directoryVisible: true,
      );
      controller.isLoading.value = false;
      controller.hasBlogEntries.value = true;
      Sint.put<MateDetailsController>(controller);

      await tester.pumpWidget(
        const SintMaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: MateDetailHeader()),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(tester.takeException(), isNull);
      expect(find.byType(ErrorWidget), findsNothing);
      expect(find.text(MateTranslationConstants.checkMyBlog.tr), findsOneWidget);

      controller.hasBlogEntries.value = false;
      await tester.pump();
      expect(find.text(MateTranslationConstants.checkMyBlog.tr), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'MateDetailsController pre-populates from AppProfile and [AppProfile] arguments and keeps fallback if loader returns empty',
    (tester) async {
      for (final wrapInList in [false, true]) {
        Sint.reset();
        Sint.put<UserService>(_FakeUserService());
        Sint.put<GeoLocatorService>(_FakeGeoLocatorService());

        final fallbackProfile = AppProfile(
          id: 'legacy-mate-1',
          name: 'Legacy Studio',
          aboutMe: 'Legacy doc missing id field in Firestore',
          directoryVisible: true,
        );

        late _TestMateDetailsController controller;

        await tester.pumpWidget(
          SintMaterialApp(
            initialRoute: '/start',
            sintPages: [
              SintPage(
                name: '/start',
                page: () => const Scaffold(body: Text('Start')),
              ),
              SintPage(
                name: AppRouteConstants.mateDetails,
                page: () {
                  controller = Sint.put<MateDetailsController>(
                    buildController(profileLoader: (_) async => AppProfile()),
                  ) as _TestMateDetailsController;
                  return const Scaffold(body: Text('Mate'));
                },
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        Sint.toNamed<void>(
          AppRouteConstants.matePath(fallbackProfile.id),
          arguments: wrapInList ? [fallbackProfile] : fallbackProfile,
        );
        await tester.pumpAndSettle();

        expect(controller.mate.value.id, 'legacy-mate-1');
        expect(controller.mate.value.name, 'Legacy Studio');
        expect(controller.isLoading.value, isFalse);
        expect(controller.isLoadingDetails.value, isFalse);
        expect(controller.matePageUpdates, greaterThanOrEqualTo(2));

        await tester.pumpWidget(const SizedBox.shrink());
      }
    },
  );
}
