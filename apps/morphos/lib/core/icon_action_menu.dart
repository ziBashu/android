/// First-level icon long-press catalog + extras + Remove cascade.
/// Pure — tests call these strings and classifiers directly.
library;

/// First-level choices (never Delete / Cancel).
class IconActionMenu {
  IconActionMenu._();

  static const appInfo = 'App info';
  static const select = 'Select';
  static const hide = 'Hide';
  static const remove = 'Remove';
  static const editHomescreen = 'Edit Homescreen';

  /// Remove cascade (second sheet).
  static const deleteFromHomeScreen = 'Delete from Home screen';
  static const deleteApplication = 'Delete application';
  static const cancel = 'Cancel';

  static const wlan = 'WLAN';
  static const bluetooth = 'Bluetooth';
  static const display = 'Display';
  static const sound = 'Sound';
  static const apps = 'Apps';
  static const newTab = 'New Tab';
  static const privateTab = 'Private Tab';
  static const compose = 'Compose';
  static const account = 'Account';

  static const List<String> coreChoices = [
    appInfo,
    select,
    hide,
    remove,
    editHomescreen,
  ];

  static const List<String> settingsExtras = [
    wlan,
    bluetooth,
    display,
    sound,
    apps,
  ];

  static const List<String> browserExtras = [
    newTab,
    privateTab,
  ];

  static const List<String> gmailExtras = [
    compose,
    account,
  ];

  static const List<String> removeCascade = [
    deleteFromHomeScreen,
    deleteApplication,
    cancel,
  ];

  static const ColorValue removeRed = ColorValue(0xFFE53935);

  /// First-level list: core + classified extras. Never includes Delete/Cancel.
  static List<String> firstLevel({
    required String id,
    String? packageName,
    String label = '',
  }) {
    return [
      ...coreChoices,
      ...extrasFor(id: id, packageName: packageName, label: label),
    ];
  }

  static List<String> extrasFor({
    required String id,
    String? packageName,
    String label = '',
  }) {
    return switch (classify(
      id: id,
      packageName: packageName,
      label: label,
    )) {
      IconExtraKind.settings => settingsExtras,
      IconExtraKind.browser => browserExtras,
      IconExtraKind.gmail => gmailExtras,
      IconExtraKind.none => const [],
    };
  }

  static IconExtraKind classify({
    required String id,
    String? packageName,
    String label = '',
  }) {
    final hay =
        '${id.toLowerCase()} ${(packageName ?? '').toLowerCase()} ${label.toLowerCase()}';
    if (_isGmail(hay, id, packageName)) return IconExtraKind.gmail;
    if (_isSettings(hay, id, packageName)) return IconExtraKind.settings;
    if (_isBrowser(hay, id, packageName)) return IconExtraKind.browser;
    return IconExtraKind.none;
  }

  static bool _isGmail(String hay, String id, String? packageName) {
    final pkg = (packageName ?? id).toLowerCase();
    if (pkg == 'com.google.android.gm' ||
        pkg.startsWith('com.google.android.gm.') ||
        pkg == 'com.google.android.gm.lite') {
      return true;
    }
    return hay.contains('gmail');
  }

  static bool _isSettings(String hay, String id, String? packageName) {
    final pkg = (packageName ?? id).toLowerCase();
    if (pkg == 'com.android.settings' ||
        pkg.endsWith('.settings') ||
        id.toLowerCase() == 'settings') {
      return true;
    }
    return hay.contains('settings') && !hay.contains('keyboard');
  }

  static bool _isBrowser(String hay, String id, String? packageName) {
    final pkg = (packageName ?? id).toLowerCase();
    if (id.toLowerCase() == 'browser') return true;
    const needles = [
      'chrome',
      'firefox',
      'brave',
      'opera',
      'edge',
      'browser',
      'samsung.android.sbrowser',
    ];
    for (final n in needles) {
      if (pkg.contains(n) || hay.contains(n)) return true;
    }
    return false;
  }

  static bool isAppInfo(String choice) => choice == appInfo;
  static bool isSelect(String choice) => choice == select;
  static bool isHide(String choice) => choice == hide;
  static bool isRemove(String choice) => choice == remove;
  static bool isEditHomescreen(String choice) => choice == editHomescreen;

  static bool isHomeRemove(String choice) => choice == deleteFromHomeScreen;
  static bool isUninstall(String choice) => choice == deleteApplication;
  static bool isCancel(String choice) => choice == cancel;

  static bool isRed(String choice) =>
      choice == remove || choice == deleteApplication;

  /// First-level must never surface these verbs.
  static bool isForbiddenFirstLevel(String choice) {
    final c = choice.toLowerCase();
    return c == 'delete' ||
        c == 'cancel' ||
        c == deleteFromHomeScreen.toLowerCase() ||
        c == deleteApplication.toLowerCase() ||
        c == cancel.toLowerCase();
  }

  static bool firstLevelContainsForbidden(List<String> choices) =>
      choices.any(isForbiddenFirstLevel);
}

/// Extra shortcut family for Settings / Browser / Gmail.
enum IconExtraKind { settings, browser, gmail, none }

/// Tiny color token so the menu unit stays Flutter-free.
class ColorValue {
  const ColorValue(this.argb);
  final int argb;
}

/// Cascade strings kept under the old name so occupancy apply stays stable.
class IconMinusMenu {
  IconMinusMenu._();

  static const deleteFromHomeScreen = IconActionMenu.deleteFromHomeScreen;
  static const deleteApplication = IconActionMenu.deleteApplication;
  static const cancel = IconActionMenu.cancel;

  /// Second sheet only — not the first-level long-press list.
  static const List<String> choices = IconActionMenu.removeCascade;

  static bool isHomeRemove(String choice) => IconActionMenu.isHomeRemove(choice);
  static bool isUninstall(String choice) => IconActionMenu.isUninstall(choice);
  static bool isCancel(String choice) => IconActionMenu.isCancel(choice);
}
