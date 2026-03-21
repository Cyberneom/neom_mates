import 'package:flutter/material.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/widgets/web/web_theme_constants.dart';
import 'package:neom_commons/utils/constants/app_constants.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/utils/enums/app_in_use.dart';
import 'package:sint/sint.dart';

import '../../../../utils/constants/mate_constants.dart';
import '../../mate_details_controller.dart';

class MateDetailsWebActivity extends StatelessWidget {
  final MateDetailsController controller;

  const MateDetailsWebActivity({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: WebThemeConstants.glassCard,
      child: DefaultTabController(
        length: AppConstants.profileTabs.length,
        child: Obx(() => Column(
          children: [
            TabBar(
              tabs: [
                Tab(text: '${AppConstants.profileTabs.elementAt(0).tr} '
                    '${controller.matePosts.isNotEmpty ? '(${controller.matePosts.length})' : ''}'),
                Tab(text: '${AppConstants.profileTabs.elementAt(1).tr} '
                    '${controller.totalPresets.isEmpty && controller.totalMixedItems.isEmpty
                    ? '' : '(${AppConfig.instance.appInUse == AppInUse.c
                    ? controller.totalPresets.length : controller.totalMixedItems.length})'}'),
                Tab(text: '${AppConstants.profileTabs.elementAt(2).tr} '
                    '${controller.events.isEmpty ? '' : '(${controller.events.length})'}'),
              ],
              indicatorColor: Colors.white,
              labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(fontSize: 12),
              labelPadding: EdgeInsets.zero,
              dividerColor: AppColor.borderSubtle,
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            Expanded(
              child: TabBarView(
                children: AppConfig.instance.appInUse == AppInUse.c
                    ? MateConstants.neomMateTabPages
                    : MateConstants.mateTabPages,
              ),
            ),
          ],
        )),
      ),
    );
  }
}
