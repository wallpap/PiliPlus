import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

abstract final class WindowsFontHelper {
  static final _fonts = <String>{};

  /// 枚举系统中所有已安装的字体名称（已去重、排序）
  static List<String> getSystemFonts() {
    _fonts.clear();
    final hdc = GetDC(null);

    final logFont = calloc<LOGFONT>()
      ..ref.lfCharSet = DEFAULT_CHARSET;

    final callback = NativeCallable<FONTENUMPROC>.isolateLocal(
      _enumFontsProc,
      exceptionalReturn: 0,
    );

    EnumFontFamiliesEx(
      hdc,
      logFont,
      callback.nativeFunction,
      LPARAM(0),
      0,
    );

    callback.close();
    calloc.free(logFont);
    ReleaseDC(null, hdc);

    final result = _fonts.toList()..sort();
    _fonts.clear();
    return result;
  }

  static int _enumFontsProc(
    Pointer<LOGFONT> logFont,
    Pointer<TEXTMETRIC> textMetric,
    int fontType,
    int lParam,
  ) {
    // 过滤光栅字体（仅位图，无矢量轮廓）
    const rasterFontType = 0x0001; // RASTER_FONTTYPE
    if ((fontType & rasterFontType) != 0) {
      return TRUE;
    }

    // 从 ENUMLOGFONTEX 获取完整字体名（比 lfFaceName 更完整）
    final logFontEx = logFont.cast<ENUMLOGFONTEX>();
    final name = logFontEx.ref.elfFullName;

    // 过滤：不以 @ 开头（纵向字体）、非空
    if (name.isNotEmpty && !name.startsWith('@')) {
      _fonts.add(name);
    }
    return TRUE;
  }
}
