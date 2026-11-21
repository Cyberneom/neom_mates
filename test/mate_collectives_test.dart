import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/data/firestore/post_firestore.dart';
import 'package:neom_core/domain/model/app_profile.dart';
import 'package:neom_core/domain/model/app_user.dart';
import 'package:neom_core/domain/model/collective.dart';
import 'package:neom_core/domain/model/instrument.dart';
import 'package:neom_core/domain/model/post.dart';
import 'package:neom_core/domain/use_cases/geolocator_service.dart';
import 'package:neom_core/domain/use_cases/user_service.dart';
import 'package:neom_core/utils/enums/app_in_use.dart';
import 'package:neom_mates/ui/mate_details/mate_details_controller.dart';
import 'package:sint/sint.dart';

class _UserService extends Fake implements UserService {
  @override
  final user = AppUser(id: 'u1');
  @override
  final profile = AppProfile(id: 'viewer');
}

class _GeoLocatorService extends Fake implements GeoLocatorService {}

class _Posts extends Fake implements PostFirestore {
  @override
  Future<List<Post>> getProfilePosts(String profileId, {int limit = 20}) async => [];
}

class _TestMateDetailsController extends MateDetailsController {
  _TestMateDetailsController({
    required super.postFirestore,
    required super.profileLoader,
    required super.blogPresenceLoader,
    required super.instrumentsLoader,
    required super.collectivesLoader,
  });

  @override
  Future<void> getTotalItems() async {}

  @override
  Future<void> getAddressSimple() async {}

  @override
  Future<void> getReadingProgress() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppInUse prevApp;
  late bool prevGuest;

  setUp(() {
    prevApp = AppConfig.instance.appInUse;
    prevGuest = AppConfig.instance.isGuestMode;
    AppConfig.instance.appInUse = AppInUse.g;
    AppConfig.instance.isGuestMode = true;
    Sint.reset();
    Sint.put<UserService>(_UserService());
    Sint.put<GeoLocatorService>(_GeoLocatorService());
  });

  tearDown(() {
    Sint.reset();
    AppConfig.instance.appInUse = prevApp;
    AppConfig.instance.isGuestMode = prevGuest;
  });

  test('getMateCollectives loads active named bands for a mate profile', () async {
    List<String>? requestedIds;
    final controller = _TestMateDetailsController(
      postFirestore: _Posts(),
      profileLoader: (_) async => AppProfile(),
      blogPresenceLoader: (_) async => false,
      instrumentsLoader: (_) async => <String, Instrument>{},
      collectivesLoader: (ids) async {
        requestedIds = ids;
        return {
          'b1': Collective(id: 'b1', name: 'Los Rayos', slug: 'los-rayos', isActive: true),
          'b2': Collective(id: 'b2', name: 'Archived Band', isActive: false),
          'b3': Collective(id: 'b3', name: '   ', isActive: true),
        };
      },
    );
    addTearDown(controller.onClose);

    controller.mate.value = AppProfile(
      id: 'm1',
      name: 'Diego',
      collectives: ['b1', 'b2', 'b3'],
    );

    await controller.getMateCollectives();

    expect(requestedIds, ['b1', 'b2', 'b3']);
    expect(controller.mateCollectives.keys, ['b1']);
    expect(controller.mateCollectives['b1']?.name, 'Los Rayos');

    // Empty collectives clears state cleanly
    controller.mate.value = AppProfile(id: 'm1', name: 'Diego', collectives: []);
    await controller.getMateCollectives();
    expect(controller.mateCollectives, isEmpty);
  });
}
