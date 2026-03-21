import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:neom_commons/ui/widgets/images/handled_cached_network_image.dart';
import 'package:neom_commons/ui/widgets/rating_heart_bar.dart';
import 'package:neom_commons/ui/widgets/reading_progress_indicator.dart';
import 'package:neom_commons/utils/app_utilities.dart';
import 'package:neom_commons/utils/constants/app_assets.dart';
import 'package:neom_commons/utils/constants/app_constants.dart';
import 'package:neom_commons/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/utils/constants/translations/common_translation_constants.dart';
import 'package:neom_commons/utils/mappers/base_item_mapper.dart';
import 'package:neom_core/domain/model/base_item.dart';
import 'package:neom_core/domain/model/nupale/reading_progress.dart';
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

          if (item is ReadingProgress) {
            return ListTile(
              contentPadding: const EdgeInsets.all(8.0),
              leading: SizedBox(
                width: 50, height: 65,
                child: item.itemImgUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: HandledCachedNetworkImage(item.itemImgUrl,
                          width: 50, height: 65, enableFullScreen: false,),
                      )
                    : const Icon(Icons.menu_book, color: Colors.white54, size: 32),
              ),
              title: Text(
                item.itemName,
                maxLines: kIsWeb ? 2 : 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.itemOwnerName.isNotEmpty)
                    Text(item.itemOwnerName,
                      style: const TextStyle(fontSize: 12, color: Colors.white60),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                  ReadingProgressIndicator(progress: item),
                ],
              ),
            );
          }

          BaseItem baseItem = BaseItemMapper.fromDynamicItem(item);
          final ReadingProgress? progress = controller.readingProgressMap[baseItem.id];

          return ListTile(
            contentPadding: const EdgeInsets.all(8.0),
            leading: HandledCachedNetworkImage(baseItem.imgUrl,
            width: 50, enableFullScreen: false,),
            title: Text(
              baseItem.name,
              maxLines: kIsWeb ? 2 : 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Flexible(
                    child: Text(baseItem.ownerName,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 5),
                  RatingHeartBar(state: baseItem.state.toDouble()),
                ]),
                if (progress != null) ReadingProgressIndicator(progress: progress),
              ],
            ),
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
