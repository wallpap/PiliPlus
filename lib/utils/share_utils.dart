import 'dart:io' show Platform;

import 'package:PiliPlus/utils/device_utils.dart';
import 'package:PiliPlus/utils/platform_utils.dart';
import 'package:PiliPlus/utils/utils.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/rendering.dart' show Rect;
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:share_plus/share_plus.dart';

abstract final class ShareUtils {
  static Future<void> shareText(String text) async {
    if (PlatformUtils.isDesktop) {
      Utils.copyText(text);
      return;
    }
    try {
      await SharePlus.instance.share(
        ShareParams(text: text),
      );
    } catch (e) {
      SmartDialog.showToast(e.toString());
    }
  }
}
