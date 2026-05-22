import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:neom_commons/app_flavour.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/ui/widgets/web/web_breadcrumb.dart';
import 'package:neom_commons/ui/widgets/web/web_keyboard_manager.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_home/ui/web/left_sidebar.dart';
import 'package:sint/sint.dart';

import '../mate_details_controller.dart';
import 'widgets/mate_details_web_activity.dart';
import 'widgets/mate_details_web_header.dart';

/// Instagram-style profile page for web.
/// - Top: horizontal header (avatar + name/stats/bio + action buttons + 3-dots)
/// - Bottom: full-width tabbed activity (posts grid, items, events)
/// Centered in a max-width container so the layout doesn't sprawl on
/// large monitors.
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
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1040),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // ─── IG-style horizontal header ────────────
                              MateDetailsWebHeader(controller: controller),

                              // Subtle divider between profile and content
                              Container(
                                height: 1,
                                color: AppColor.borderSubtle,
                                margin: const EdgeInsets.symmetric(horizontal: 24),
                              ),

                              // ─── Full-width tabs + grid ────────────────
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                                  child: MateDetailsWebActivity(controller: controller),
                                ),
                              ),
                            ],
                          ),
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
