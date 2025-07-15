import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/ui/widgets/handled_cached_network_image.dart';
import 'package:neom_commons/ui/widgets/rating_heart_bar.dart';
import 'package:neom_commons/utils/constants/app_assets.dart';
import 'package:neom_commons/utils/constants/app_constants.dart';
import 'package:neom_commons/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/utils/constants/app_translation_constants.dart';
import 'package:neom_core/domain/model/app_media_item.dart';

import '../../mate_details_controller.dart';

class MateItems extends StatelessWidget {
  const MateItems({super.key});


  @override
  Widget build(BuildContext context) {
    return GetBuilder<MateDetailsController>(
      id: AppPageIdConstants.mate,
      /// init: MateDetailsController(),
      builder: (_) => _.totalMixedItems.isNotEmpty ? ListView.builder(
        padding: const EdgeInsets.fromLTRB(0.0, 8.0, 0.0, 8.0),
        itemCount: _.totalMixedItems.length,
        itemBuilder: (context, index) {
          AppMediaItem appMediaItem = _.totalMixedItems.values.elementAt(index);
          return ListTile(
            contentPadding: const EdgeInsets.all(8.0),
            leading: HandledCachedNetworkImage(appMediaItem.imgUrl,
            width: 50, enableFullScreen: false,),
            title: Text(appMediaItem.name.isEmpty ? ""
              : appMediaItem.name.length > AppConstants.maxAppItemNameLength ? "${appMediaItem.name.substring(0,AppConstants.maxAppItemNameLength)}...": appMediaItem.name),
            subtitle: Row(
            children: [
              Text(appMediaItem.artist.isEmpty ? ""
                  : appMediaItem.artist.length > AppConstants.maxArtistNameLength
              ? "${appMediaItem.artist.substring(0,AppConstants.maxArtistNameLength)}..."
                  : appMediaItem.artist),
              const SizedBox(width:5,),
              RatingHeartBar(state: appMediaItem.state.toDouble()),]),
                onTap: () => _.getItemDetails(appMediaItem),
          );
        },
      ) : Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.only(top: 10, bottom: 10.0),
            child: Text(
              AppTranslationConstants.noItemsYet.tr,
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
