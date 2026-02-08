import 'package:flutter/material.dart';
import 'package:neom_commons/ui/widgets/images/handled_cached_network_image.dart';
import 'package:neom_commons/ui/widgets/rating_heart_bar.dart';
import 'package:neom_commons/utils/app_utilities.dart';
import 'package:neom_commons/utils/constants/app_assets.dart';
import 'package:neom_commons/utils/constants/app_constants.dart';
import 'package:neom_commons/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/utils/constants/translations/common_translation_constants.dart';
import 'package:neom_commons/utils/mappers/base_item_mapper.dart';
import 'package:neom_core/domain/model/base_item.dart';
import 'package:sint/sint.dart';

import '../../mate_details_controller.dart';

class MateItems extends StatelessWidget {
  const MateItems({super.key});


  @override
  Widget build(BuildContext context) {
    return SintBuilder<MateDetailsController>(
      id: AppPageIdConstants.mate,
      builder: (controller) => controller.totalMixedItems.isNotEmpty ? ListView.builder(
        padding: const EdgeInsets.fromLTRB(0.0, 8.0, 0.0, 8.0),
        itemCount: controller.totalMixedItems.length,
        itemBuilder: (context, index) {
          dynamic item = controller.totalMixedItems.values.elementAt(index);
          BaseItem baseItem = BaseItemMapper.fromDynamicItem(item);

          return ListTile(
            contentPadding: const EdgeInsets.all(8.0),
            leading: HandledCachedNetworkImage(baseItem.imgUrl,
            width: 50, enableFullScreen: false,),
            title: Text(baseItem.name.isEmpty ? ""
              : baseItem.name.length > AppConstants.maxAppItemNameLength ? "${baseItem.name.substring(0,AppConstants.maxAppItemNameLength)}...": baseItem.name),
            subtitle: Row(
            children: [
              Text(baseItem.ownerName.isEmpty ? ""
                  : baseItem.ownerName.length > AppConstants.maxArtistNameLength
              ? "${baseItem.ownerName.substring(0,AppConstants.maxArtistNameLength)}..."
                  : baseItem.ownerName),
              const SizedBox(width:5,),
              RatingHeartBar(state: baseItem.state.toDouble()),]),
                onTap: () => AppUtilities.gotoItemDetails(item),
          );
        },
      ) : Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.only(top: 10, bottom: 10.0),
            child: Text(
              CommonTranslationConstants.noItemsYet.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
          ),
          Image.asset(AppAssets.noPostsMate, height: 175),
        ],
      )
    );
  }
}
