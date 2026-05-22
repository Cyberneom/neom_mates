import 'package:neom_core/ui/deferred_loader.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:sint/sint.dart';

import 'ui/mate_details/mate_details_page.dart' deferred as mateDetails;
import 'ui/mate_list_page.dart' deferred as mateList;

class MateRoutes {

  static final List<SintPage<dynamic>> routes = [
    SintPage(
      name: AppRouteConstants.mates,
      page: () => DeferredLoader(mateList.loadLibrary, () => mateList.MateListPage()),
    ),
    SintPage(
      name: AppRouteConstants.mateDetails,
      page: () => DeferredLoader(mateDetails.loadLibrary, () => mateDetails.MateDetailsPage()),
      transition: Transition.zoom,
    ),
  ];

}
