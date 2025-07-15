import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/ui/widgets/handled_cached_network_image.dart';
import 'package:neom_commons/ui/widgets/rating_heart_bar.dart';
import 'package:neom_commons/utils/app_utilities.dart';
import 'package:neom_commons/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/utils/constants/app_translation_constants.dart';
import 'package:neom_core/domain/model/neom/chamber_preset.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';

import '../../mate_details_controller.dart';

class MateChamberPresets extends StatelessWidget {
  const MateChamberPresets({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<MateDetailsController>(
      id: AppPageIdConstants.profile,
      /// init: MateDetailsController(),
      builder: (_) => SizedBox(
        width: double.infinity,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(0.0, 8.0, 0.0, 8.0),
          itemCount: _.totalPresets.length,
          itemBuilder: (context, index) {
            String presetKey = _.totalPresets.keys.elementAt(index);
            ChamberPreset chamberPreset = _.totalPresets[presetKey]!;
            return GestureDetector(
              child: ListTile(
                contentPadding: const EdgeInsets.all(8.0),
                leading: Hero(
                    tag: AppUtilities.getAppItemHeroTag(index),
                    child: HandledCachedNetworkImage(chamberPreset.imgUrl,
                      width: 50, enableFullScreen: false,
                    ),
                ),
                title: Text(chamberPreset.name.isEmpty ? "${AppTranslationConstants.frequency.tr} ${chamberPreset.neomFrequency?.frequency} Hz" : chamberPreset.name),
                subtitle: chamberPreset.neomParameter != null ? Text("Vol: ${chamberPreset.neomParameter!.volume.toStringAsFixed(1)} | "
                    "X: ${chamberPreset.neomParameter!.x.toStringAsFixed(1)} | "
                    "Y:${chamberPreset.neomParameter!.y.toStringAsFixed(1)} | "
                    "Z:${chamberPreset.neomParameter!.z.toStringAsFixed(1)}", style: const TextStyle(fontSize: 10),)
                      : Text(AppTranslationConstants.rootFrequency.tr),
                trailing: RatingHeartBar(state: chamberPreset.state.toDouble(),),
                onTap: () {
                  Get.toNamed(AppRouteConstants.generator,  arguments: [chamberPreset.clone()]);
                },
              ),
            );
          },
        ),
      )
    );
  }
}
