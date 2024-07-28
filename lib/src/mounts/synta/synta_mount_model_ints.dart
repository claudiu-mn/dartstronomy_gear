import 'package:dartstronomy_gear/src/mounts/synta/synta_mount_model.dart';

extension SyntaMountModelInts on int {
  SyntaMountModel? toSyntaMountModel() => switch (this) {
        0x00 => SyntaMountModel.skyWatcherEq6,
        0x01 => SyntaMountModel.skyWatcherHeq5,
        0x02 => SyntaMountModel.skyWatcherEq5,
        0x03 => SyntaMountModel.skyWatcherEq3,
        0x80 => SyntaMountModel.celestronNexStar80Gt,
        0x81 => SyntaMountModel.mF,
        0x82 => SyntaMountModel.celestronNexStar114Gt,
        0x90 => SyntaMountModel.dob,
        0xA5 => SyntaMountModel.skyWatcherAzGtI,
        _ => null,
      };
}
