import 'package:flutter/material.dart';
import 'package:neom_commons/ui/widgets/images/handled_cached_network_image.dart';
import 'package:neom_commons/ui/widgets/rating_heart_bar.dart';
import 'package:neom_commons/utils/app_utilities.dart';
import 'package:neom_commons/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:neom_core/domain/model/neom/neom_chamber_preset.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:sint/sint.dart';

import '../../mate_details_controller.dart';

class MateChamberPresets extends StatelessWidget {
  const MateChamberPresets({super.key});

  @override
  Widget build(BuildContext context) {
    return SintBuilder<MateDetailsController>(
      id: AppPageIdConstants.profile,
      builder: (controller) => SizedBox(
        width: double.infinity,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(0.0, 8.0, 0.0, 8.0),
          itemCount: controller.totalPresets.length,
          itemBuilder: (context, index) {
            String presetKey = controller.totalPresets.keys.elementAt(index);
            NeomChamberPreset chamberPreset = controller.totalPresets[presetKey]!;
            return GestureDetector(
              child: ListTile(
                contentPadding: const EdgeInsets.all(8.0),
                leading: Hero(
                    tag: AppUtilities.getAppItemHeroTag(index),
                    child: HandledCachedNetworkImage(chamberPreset.imgUrl,
                      width: 50, enableFullScreen: false,
                    ),
                ),
                title: Text(chamberPreset.name.isEmpty ? "${AppTranslationConstants.frequency.tr} ${chamberPreset.mainFrequency?.frequency} Hz" : chamberPreset.name),
                subtitle: chamberPreset.neomParameter != null ? Text("Vol: ${chamberPreset.neomParameter!.volume.toStringAsFixed(1)} | "
                    "X: ${chamberPreset.neomParameter!.x.toStringAsFixed(1)} | "
                    "Y:${chamberPreset.neomParameter!.y.toStringAsFixed(1)} | "
                    "Z:${chamberPreset.neomParameter!.z.toStringAsFixed(1)}", style: const TextStyle(fontSize: 10),)
                      : Text(AppTranslationConstants.rootFrequency.tr),
                trailing: RatingHeartBar(state: chamberPreset.state.toDouble(),),
                onTap: () {
                  Sint.toNamed(AppRouteConstants.generator,  arguments: [chamberPreset.clone()]);
                },
              ),
            );
          },
        ),
      )
    );
  }
}
