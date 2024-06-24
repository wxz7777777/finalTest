import 'dart:async';
import 'package:flutter/scheduler.dart' show timeDilation;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';

// Fake locale to represent the system Locale option.

// Locale? _deviceLocale;
//
// Locale? get deviceLocale => _deviceLocale;

// set deviceLocale(Locale? locale) {
//   _deviceLocale ??= locale;
// }

const _localeKey = 'key_locale';
const _themeKey = 'key_theme';

get lastLocale {
  String? code = GetStorage().read(_localeKey);
  if (code == null) {
    return null;
  }
  switch (code.toLowerCase()) {
    case 'zh':
      return const Locale('zh');
    case 'en':
      return const Locale('en');
    default:
      return null;
  }
}

setLastLocale(Locale? locale) => GetStorage().write(_localeKey, locale?.languageCode);

saveLastTheme(int index) {
  GetStorage().write(_themeKey, index);
}

get lastTheme {
  int? index = GetStorage().read(_themeKey);
  if (index == null) {
    return ThemeMode.system;
  }
  return ThemeMode.values[index];
}

class HookData {
  HookData._internal();

  static final HookData instance = HookData._internal();

  double labelWidth = 90;
  double? switchLabelWidth;
  double? pickerLabelWidth;
  bool isChinese = true;

  updateLabelWidth(String? languageCode) {
    print('----lc: $languageCode');
    if (languageCode == 'zh') {
      isChinese = true;
      labelWidth = 90;
      switchLabelWidth = null;
      pickerLabelWidth = null;
    } else {
      isChinese = false;
      labelWidth = 130;
      switchLabelWidth = 65;
      pickerLabelWidth = 80;
    }
  }
}

class WishOptions {
  const WishOptions({
    required this.themeMode,
    // required double? textScaleFactor,
    // required this.customTextDirection,
    required this.locale,
    // required this.timeDilation,
    required this.platform,
    required this.isTestMode,
  });

  // : _locale = locale;

  // : _textScaleFactor = textScaleFactor ?? 1.0,
  //   _locale = locale;

  final ThemeMode themeMode;

  // final double _textScaleFactor;
  // final CustomTextDirection customTextDirection;
  final Locale? locale;

  // final double timeDilation;
  final TargetPlatform? platform;
  final bool isTestMode; // True for integration tests.

  // We use a sentinel value to indicate the system text scale option. By
  // default, return the actual text scale factor, otherwise return the
  // sentinel value.
  // double textScaleFactor(BuildContext context, {bool useSentinel = false}) {
  //   if (_textScaleFactor == systemTextScaleFactorOption) {
  //     return useSentinel
  //         ? systemTextScaleFactorOption
  //         : MediaQuery.of(context).textScaleFactor;
  //   } else {
  //     return _textScaleFactor;
  //   }
  // }

  // Locale? get locale => _locale ?? deviceLocale;

  /// Returns a text direction based on the [CustomTextDirection] setting.
  /// If it is based on locale and the locale cannot be determined, returns
  /// null.
  // TextDirection? resolvedTextDirection() {
  //   switch (customTextDirection) {
  //     case CustomTextDirection.localeBased:
  //       final language = locale?.languageCode.toLowerCase();
  //       if (language == null) return null;
  //       return rtlLanguages.contains(language)
  //           ? TextDirection.rtl
  //           : TextDirection.ltr;
  //     case CustomTextDirection.rtl:
  //       return TextDirection.rtl;
  //     default:
  //       return TextDirection.ltr;
  //   }
  // }

  /// Returns a [SystemUiOverlayStyle] based on the [ThemeMode] setting.
  /// In other words, if the theme is dark, returns light; if the theme is
  /// light, returns dark.
  SystemUiOverlayStyle resolvedSystemUiOverlayStyle() {
    Brightness brightness;
    switch (themeMode) {
      case ThemeMode.light:
        brightness = Brightness.light;
        break;
      case ThemeMode.dark:
        brightness = Brightness.dark;
        break;
      default:
        brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    }

    final overlayStyle = brightness == Brightness.dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark;

    return overlayStyle;
  }

  WishOptions copyWith({
    ThemeMode? themeMode,
    // double? textScaleFactor,
    // CustomTextDirection? customTextDirection,
    bool? forceLocale,
    Locale? locale,
    double? timeDilation,
    TargetPlatform? platform,
    bool? isTestMode,
  }) {
    return WishOptions(
      themeMode: themeMode ?? this.themeMode,
      // textScaleFactor: textScaleFactor ?? _textScaleFactor,
      // customTextDirection: customTextDirection ?? this.customTextDirection,
      locale: forceLocale == true ? locale : locale ?? this.locale,
      // timeDilation: timeDilation ?? this.timeDilation,
      platform: platform ?? this.platform,
      isTestMode: isTestMode ?? this.isTestMode,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is WishOptions &&
      themeMode == other.themeMode &&
      // _textScaleFactor == other._textScaleFactor &&
      // customTextDirection == other.customTextDirection &&
      locale == other.locale &&
      // timeDilation == other.timeDilation &&
      platform == other.platform &&
      isTestMode == other.isTestMode;

  // Locale? get locale => _locale ?? deviceLocale;

  @override
  int get hashCode => Object.hash(
        themeMode,
        // _textScaleFactor,
        // customTextDirection,
        locale,
        timeDilation,
        platform,
        isTestMode,
      );

  static WishOptions of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_ModelBindingScope>()!;
    return scope.modelBindingState.currentModel;
  }

  static bool isLight(BuildContext context) {
    return of(context).themeMode == ThemeMode.light;
  }

  static void update(BuildContext context, WishOptions newModel) {
    final scope = context.dependOnInheritedWidgetOfExactType<_ModelBindingScope>()!;
    scope.modelBindingState.updateModel(newModel);
  }
}

class _ModelBindingScope extends InheritedWidget {
  const _ModelBindingScope({
    required this.modelBindingState,
    required super.child,
  });

  final _ModelBindingState modelBindingState;

  @override
  bool updateShouldNotify(_ModelBindingScope oldWidget) => true;
}

class ModelBinding extends StatefulWidget {
  const ModelBinding({
    super.key,
    required this.initialModel,
    required this.child,
  });

  final WishOptions initialModel;
  final Widget child;

  @override
  State<ModelBinding> createState() => _ModelBindingState();
}

class _ModelBindingState extends State<ModelBinding> {
  late WishOptions currentModel;
  Timer? _timeDilationTimer;

  @override
  void initState() {
    super.initState();
    currentModel = widget.initialModel;
  }

  @override
  void dispose() {
    _timeDilationTimer?.cancel();
    _timeDilationTimer = null;
    super.dispose();
  }

  // void handleTimeDilation(WishOptions newModel) {
  //   if (currentModel.timeDilation != newModel.timeDilation) {
  //     _timeDilationTimer?.cancel();
  //     _timeDilationTimer = null;
  //     if (newModel.timeDilation > 1) {
  //       // We delay the time dilation change long enough that the user can see
  //       // that UI has started reacting and then we slam on the brakes so that
  //       // they see that the time is in fact now dilated.
  //       _timeDilationTimer = Timer(const Duration(milliseconds: 150), () {
  //         timeDilation = newModel.timeDilation;
  //       });
  //     } else {
  //       timeDilation = newModel.timeDilation;
  //     }
  //   }
  // }

  void updateModel(WishOptions newModel) {
    if (newModel != currentModel) {
      // handleTimeDilation(newModel);
      setState(() {
        currentModel = newModel;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _ModelBindingScope(
      modelBindingState: this,
      child: widget.child,
    );
  }
}
