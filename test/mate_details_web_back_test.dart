import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neom_commons/ui/widgets/web_content_wrapper.dart';
import 'package:neom_commons/ui/widgets/web/web_keyboard_manager.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_mates/ui/mate_details/mate_details_navigation.dart';
import 'package:sint/sint.dart';

void main() {
  const profileRoute = '/mate/public-artist';
  const previousRoute = '/test-search';

  tearDown(Sint.reset);

  Future<void> mount(WidgetTester tester, String initialRoute) async {
    // VM tests render this shared web wrapper above its non-web width cutoff.
    // The callback is the same one used by the narrow public web profile.
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1000, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      SintMaterialApp(
        initialRoute: initialRoute,
        sintPages: [
          SintPage(
            name: AppRouteConstants.home,
            page: () => const Scaffold(body: Text('Home destination')),
          ),
          SintPage(
            name: previousRoute,
            page: () => const Scaffold(body: Text('Previous search page')),
          ),
          SintPage(
            name: AppRouteConstants.mateDetails,
            page: () => const WebKeyboardManager(
              pageId: 'mate_details',
              pageShortcuts: {
                SingleActivator(LogicalKeyboardKey.escape):
                    navigateBackFromMateDetails,
              },
              child: Scaffold(
                body: WebContentWrapper(
                  showBackButton: true,
                  onBack: navigateBackFromMateDetails,
                  child: Text('Public profile'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Back from a single public profile entry opens Home', (
    tester,
  ) async {
    await mount(tester, profileRoute);
    expect(find.byType(BackButton), findsOneWidget);
    expect(Sint.canBack, isFalse);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('Home destination'), findsOneWidget);
    expect(Sint.currentRoute, AppRouteConstants.home);
    expect(Sint.canBack, isFalse);
  });

  testWidgets('Back from an in-app profile visit preserves the previous page', (
    tester,
  ) async {
    await mount(tester, previousRoute);
    Sint.toNamed<void>(profileRoute);
    await tester.pumpAndSettle();
    expect(Sint.canBack, isTrue);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('Previous search page'), findsOneWidget);
    expect(find.text('Home destination'), findsNothing);
    expect(Sint.currentRoute, previousRoute);
    expect(Sint.canBack, isFalse);
  });

  testWidgets('Escape from a single public profile entry opens Home', (
    tester,
  ) async {
    await mount(tester, profileRoute);
    expect(Sint.canBack, isFalse);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.text('Home destination'), findsOneWidget);
    expect(Sint.currentRoute, AppRouteConstants.home);
    expect(Sint.canBack, isFalse);
  });
}
