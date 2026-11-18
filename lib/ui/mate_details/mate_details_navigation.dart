import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:sint/sint.dart';

/// A refreshed public profile can be the only route in SINT's history.
/// Preserve the previous page for in-app visits, otherwise return to Home.
void navigateBackFromMateDetails() {
  if (Sint.canBack) {
    Sint.back();
  } else {
    Sint.offAllNamed(AppRouteConstants.home);
  }
}
