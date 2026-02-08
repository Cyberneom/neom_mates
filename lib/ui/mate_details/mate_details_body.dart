import 'package:flutter/material.dart';
import 'package:neom_commons/app_flavour.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/ui/widgets/genres_grid_view.dart';
import 'package:neom_commons/ui/widgets/read_more_container.dart';
import 'package:neom_commons/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:neom_commons/utils/constants/translations/common_translation_constants.dart';
import 'package:neom_commons/utils/text_utilities.dart';
import 'package:neom_core/utils/constants/core_constants.dart';
import 'package:neom_core/utils/enums/verification_level.dart';
import 'package:sint/sint.dart';

import 'mate_details_controller.dart';

class MateDetailsBody extends StatelessWidget {
  const MateDetailsBody({super.key});

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var textTheme = theme.textTheme;
    return SintBuilder<MateDetailsController>(
      id: AppPageIdConstants.mate,
      builder: (controller) => Obx(()=> controller.isLoading.value ? const Center(child: CircularProgressIndicator())
      : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  height: 30,
                  child: Text(TextUtilities.capitalizeFirstLetter(controller.mate.value.name),
                    style: Theme.of(context).textTheme.titleLarge!.copyWith(color: Colors.white),
                  ),
                ),
                AppTheme.widthSpace5,
                if(controller.mate.value.verificationLevel != VerificationLevel.none)
                  SizedBox(height: 30, child: AppFlavour.getVerificationIcon(controller.mate.value.verificationLevel, size: 18)),
              ]
          ),
          controller.mate.value.mainFeature.isNotEmpty ?
          Row(
            children: [
              Icon(AppFlavour.getInstrumentIcon(), size: 15.0),
              AppTheme.widthSpace5,
              Text(controller.mate.value.mainFeature.tr.capitalize,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColor.white
                ),
              ),
            ],
          ) : const SizedBox.shrink(),
          controller.mate.value.genres != null ? GenresGridView(
            controller.mate.value.genres?.keys.toList() ?? [],
            AppColor.white,
            alignment: Alignment.centerLeft,
            fontSize: 15,
          ) : const SizedBox.shrink(),
          SizedBox(
            child: controller.address.isNotEmpty && controller.distance > 0.0
                ? _buildLocationInfo(controller.address, controller.distance, textTheme)
                : const SizedBox.shrink(),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: ReadMoreContainer(
              text: controller.mate.value.aboutMe.isEmpty
                  ? CommonTranslationConstants.noProfileDesc.tr
                  : TextUtilities.capitalizeFirstLetter(controller.mate.value.aboutMe),
              color: Colors.white70,
            )
          ),
        ]
      ),),
    );
  }

  Widget _buildLocationInfo(String addressSimple, int distance,  TextTheme textTheme) {
    return Row(
        children: <Widget>[
          Icon(Icons.place,
            color: AppColor.white80,
            size: 16.0,
          ),
          AppTheme.widthSpace5,
          Text(addressSimple.isEmpty ? AppTranslationConstants.notSpecified.tr : addressSimple.length > CoreConstants.maxLocationNameLength
              ? "${addressSimple.substring(0, CoreConstants.maxLocationNameLength)}..." : addressSimple,
            style: textTheme.titleSmall!.copyWith(color: AppColor.white80),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 5.0),
            child: Text(distance == 0 ? "" : "- ${distance.ceil().toString()} ${CoreConstants.km}",
              style: textTheme.titleSmall!.copyWith(color: AppColor.white80),
            ),
          ),
        ],
      );
  }
}
