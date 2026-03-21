import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:neom_commons/app_flavour.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/ui/widgets/web/web_breadcrumb.dart';
import 'package:neom_commons/ui/widgets/web/web_keyboard_manager.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_home/ui/web/left_sidebar.dart';
import 'package:sint/sint.dart';

import '../mate_details_controller.dart';
import 'widgets/mate_details_web_activity.dart';
import 'widgets/mate_details_web_card.dart';

class MateDetailsWebPage extends StatelessWidget {
  final MateDetailsController controller;

  const MateDetailsWebPage({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final sidebarExpanded = screenWidth > 1400;

    return WebKeyboardManager(
      pageId: 'mate_details',
      pageShortcuts: {
        const SingleActivator(LogicalKeyboardKey.escape): () => Sint.back(),
      },
      child: Scaffold(
        backgroundColor: AppFlavour.getBackgroundColor(),
        body: Row(
          children: [
            LeftSidebar(
              expanded: sidebarExpanded,
              currentTabIndex: -1,
              onTabSelected: (_) => Sint.offAllNamed(AppRouteConstants.home),
            ),
            Expanded(
              child: Container(
                decoration: AppTheme.appBoxDecoration,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Obx(() => WebBreadcrumb(items: [
                        BreadcrumbItem(
                          label: AppTranslationConstants.goBack.tr,
                          icon: Icons.arrow_back,
                          onTap: () => Sint.back(),
                        ),
                        BreadcrumbItem(
                          label: controller.mate.value.name.isNotEmpty
                              ? controller.mate.value.name
                              : AppTranslationConstants.profile.tr,
                        ),
                      ])),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            MateDetailsWebCard(controller: controller),
                            const SizedBox(width: 24),
                            Expanded(
                              child: MateDetailsWebActivity(controller: controller),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
