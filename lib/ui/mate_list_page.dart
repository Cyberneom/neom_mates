import 'package:flutter/material.dart';
import 'package:neom_commons/app_flavour.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/widgets/custom_image.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/ui/widgets/giglist/giglist_youtube_import_sheet.dart';
import 'package:neom_commons/ui/widgets/web_content_wrapper.dart';
import 'package:neom_commons/utils/constants/app_page_id_constants.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/app_properties.dart';
import 'package:neom_core/data/implementations/mate_controller.dart';
import 'package:neom_core/domain/model/app_profile.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_core/utils/enums/app_in_use.dart';
import 'package:neom_core/utils/enums/itemlist_type.dart';
import 'package:neom_core/utils/enums/media_search_type.dart';
import 'package:sint/sint.dart';

import '../utils/constants/mate_translation_constants.dart';

class MateListPage extends StatelessWidget {
  const MateListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isGigmeout = AppConfig.instance.appInUse == AppInUse.g;
    return SintBuilder<MateController>(
      id: AppPageIdConstants.mates,
      init: MateController(),
      builder: (controller) => Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: SintAppBar(
            title: isGigmeout ? 'Songmates · Match de Repertorio' : MateTranslationConstants.itemmateSearch.tr,
          ),
        ),
        body: WebContentWrapper(
          maxWidth: 780,
          padding: EdgeInsets.zero,
          child: Container(
            decoration: AppTheme.appBoxDecoration,
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.mates.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.library_music_outlined,
                          size: 64,
                          color: Colors.white.withValues(alpha: 0.35),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isGigmeout
                              ? 'Aún no hay Songmates con canciones en común'
                              : 'No se encontraron coincidencias',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          isGigmeout
                              ? 'Busca canciones en YouTube Music o en el catálogo de Gigmeout y agrégalas a tu Repertorio para conectar con músicos que tocan las mismas canciones.'
                              : 'Agrega elementos a tus listas para encontrar perfiles compatibles.',
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        if (isGigmeout) ...[
                          const SizedBox(height: 22),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            alignment: WrapAlignment.center,
                            children: [
                              FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColor.getMain(),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                ),
                                onPressed: () async {
                                  await GiglistYoutubeImportSheet.show(
                                    context,
                                    onImported: (_) => controller.loadMateProfiles(),
                                  );
                                },
                                icon: const Icon(Icons.cloud_download_outlined),
                                label: const Text('Importar Playlist de YouTube'),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => Sint.toNamed(
                                  AppRouteConstants.lists,
                                  arguments: [ItemlistType.giglist],
                                ),
                                icon: const Icon(Icons.queue_music_rounded),
                                label: const Text('Mis Giglists'),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => Sint.toNamed(
                                  AppRouteConstants.itemSearch,
                                  arguments: [MediaSearchType.song],
                                ),
                                icon: const Icon(Icons.playlist_add_rounded),
                                label: const Text('Buscar Canciones'),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                itemCount: controller.mates.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final AppProfile mate = controller.mates.values.elementAt(index);
                  final meta = controller.repertoireMatchMeta[mate.id];
                  final matchPct = (meta?['matchPercentage'] as num?)?.toInt() ?? 0;
                  final matchedCount = (meta?['matchedCount'] as num?)?.toInt() ?? 0;
                  final commonSongs = (meta?['commonSongs'] as List?) ?? const [];

                  return Card(
                    color: AppColor.surfaceElevated,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => controller.getMateDetails(mate),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                platformCircleAvatar(
                                  imageUrl: mate.photoUrl.isNotEmpty
                                      ? mate.photoUrl
                                      : AppProperties.getAppLogoUrl(),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        mate.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Icon(AppFlavour.getAppItemIcon(), color: Colors.blueGrey, size: 15),
                                          const SizedBox(width: 4),
                                          Text(
                                            mate.mainFeature.tr.capitalize,
                                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                if (matchedCount > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppColor.getMain().withValues(alpha: 0.22),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: AppColor.getMain()),
                                    ),
                                    child: Text(
                                      '$matchPct% Match · $matchedCount en común',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            if (commonSongs.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: commonSongs.take(5).map((raw) {
                                  final m = raw is Map ? raw : const {};
                                  final title = (m['name'] ?? '').toString();
                                  final artist = (m['artist'] ?? '').toString();
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      artist.isNotEmpty ? '🎵 $title · $artist' : '🎵 $title',
                                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ),
      ),
    );
  }
}
