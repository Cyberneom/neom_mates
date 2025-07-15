import 'package:neom_core/domain/model/app_media_item.dart';
import 'package:neom_core/utils/enums/user_role.dart';
import 'package:neom_core/utils/enums/verification_level.dart';

abstract class MateDetailsService {

  Future<void> retrieveDetails();
  Future<void> loadMate(String mateId);
  Future<void> getMatePosts();
  Future<void> getAddressSimple();
  Future<void> getTotalInstruments();
  void getItemDetails(AppMediaItem appMediaItem);
  Future<void> follow();
  Future<void> unfollow();
  Future<void> sendMessage();
  Future<void> getTotalItems();
  Future<void> removeProfile();
  void selectVerificationLevel(VerificationLevel level);
  Future<void> updateVerificationLevel();
  void selectUserRole(UserRole role);
  Future<void> updateUserRole();
  Future<void> blockProfile();
  Future<void> unblockProfile(String profileId);

}
