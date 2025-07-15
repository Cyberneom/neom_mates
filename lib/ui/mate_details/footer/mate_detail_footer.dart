import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/utils/constants/app_constants.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/utils/enums/app_in_use.dart';

import '../../../utils/mate_constants.dart';
import '../mate_details_controller.dart';

class MateShowcase extends StatelessWidget {
  const MateShowcase({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<MateDetailsController>(
      builder: (_) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: DefaultTabController(
        length: AppConstants.profileTabs.length,
        child: Column(
          children: <Widget>[
            TabBar(
              tabs: [
                Tab(text: '${AppConstants.profileTabs.elementAt(0).tr} ${_.matePosts.isNotEmpty ? '(${_.matePosts.length})':''}'),
                Tab(text: '${AppConstants.profileTabs.elementAt(1).tr} ${_.totalPresets.isEmpty && _.totalMediaItems.length+_.totalReleaseItems.length==0
                    ? '': '(${AppConfig.instance.appInUse == AppInUse.c ?
                _.totalPresets.length : (_.totalMediaItems.length + _.totalReleaseItems.length)})'}'),
                Tab(text: '${AppConstants.profileTabs.elementAt(2).tr} ${_.events.isEmpty ? '' : '(${_.events.length})'}')
              ],
              indicatorColor: Colors.white,
              labelStyle: const TextStyle(fontSize: 15),
              unselectedLabelStyle: const TextStyle(fontSize: 12),
              labelPadding: const EdgeInsets.symmetric(horizontal: 0.0),
            ),
            SizedBox(
              height: AppTheme.fullHeight(context)/2.5,
              child: TabBarView(
                children: AppConfig.instance.appInUse == AppInUse.c
                  ? MateConstants.neomMateTabPages : MateConstants.mateTabPages,
              ),
            ),
          ],
        ),
      ),),
    );
  }

}
