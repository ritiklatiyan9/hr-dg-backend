import 'package:flutter/material.dart';
import 'package:drift/drift.dart' show Value;
import 'offline.dart';
import 'ui/tokens.dart';
export 'ui/tokens.dart'
    show ReducedMotionTransitions, AppTokens, Space, Radii, Motion;

class DisplaySettings {
  const DisplaySettings({this.language = 'en', this.dark = false});
  final String language;
  final bool dark;
}

final displaySettings = ValueNotifier(const DisplaySettings());
OfflineDatabase? _preferencesDb;
Future<void> loadDisplaySettings() async {
  try {
    _preferencesDb = OfflineDatabase();
    final rows = await _preferencesDb!
        .select(_preferencesDb!.uiPreferences)
        .get();
    displaySettings.value = DisplaySettings(
      language:
          rows.where((r) => r.key == 'language').firstOrNull?.value ?? 'en',
      dark: rows.where((r) => r.key == 'theme').firstOrNull?.value == 'dark',
    );
  } catch (_) {
    /* UI preferences are optional; never block secure login. */
  }
}

/// Non-sensitive UI preference storage (language, theme, last site selector).
Future<String?> readPreference(String key) async {
  try {
    final rows = await _preferencesDb
        ?.select(_preferencesDb!.uiPreferences)
        .get();
    return rows?.where((r) => r.key == key).firstOrNull?.value;
  } catch (_) {
    return null;
  }
}

Future<void> writePreference(String key, String value) async {
  try {
    await _preferencesDb
        ?.into(_preferencesDb!.uiPreferences)
        .insertOnConflictUpdate(
          UiPreferencesCompanion(key: Value(key), value: Value(value)),
        );
  } catch (_) {
    /* Preferences are best effort. */
  }
}

Future<void> setDisplaySettings({String? language, bool? dark}) async {
  final next = DisplaySettings(
    language: language ?? displaySettings.value.language,
    dark: dark ?? displaySettings.value.dark,
  );
  displaySettings.value = next;
  await writePreference('language', next.language);
  await writePreference('theme', next.dark ? 'dark' : 'light');
}

String tr(String english, String hindi) =>
    displaySettings.value.language == 'hi' ? hindi : english;

ThemeData employeeTheme(Brightness brightness) =>
    buildEmployeeTheme(brightness);

const permissionHindi = <String, String>{
  'view': 'देखें',
  'create': 'बनाएँ',
  'edit': 'संपादित करें',
  'submit': 'जमा करें',
  'review': 'समीक्षा',
  'approve': 'स्वीकार करें',
  'export': 'निर्यात',
  'manage': 'प्रबंधन',
  'contact': 'संपर्क',
  'employment': 'रोजगार',
  'salary': 'वेतन',
  'bank': 'बैंक',
  'identity': 'पहचान',
  'confidential': 'गोपनीय',
  'own': 'अपने रिकॉर्ड',
  'team': 'नियुक्त टीम',
  'site': 'चयनित साइट',
  'organization': 'संगठन रिपोर्ट',
  'super_admin': 'सुपर एडमिन',
  'admin': 'एडमिन',
  'hr': 'एचआर',
  'jr_hr': 'जूनियर एचआर',
  'employee': 'कर्मचारी',
  'manager': 'प्रबंधक',
  'supervisor': 'पर्यवेक्षक',
  'pending': 'लंबित',
  'approved': 'स्वीकृत',
  'rejected': 'अस्वीकृत',
};
String accessLabel(String key) {
  final leaf = key.replaceFirst('field.', '');
  final label = tr(leaf, permissionHindi[leaf] ?? leaf);
  return key.startsWith('field.') ? '${tr('Field', 'फ़ील्ड')}: $label' : label;
}

const _authHindi = <String, String>{
  'Two-step verification': 'दो-चरणीय सत्यापन',
  'Your people workspace': 'आपका कर्मचारी कार्यक्षेत्र',
  'Use your authenticator to continue.':
      'आगे बढ़ने के लिए ऑथेंटिकेटर का उपयोग करें।',
  'Sign in to Defence Garden Employee.':
      'Defence Garden कर्मचारी में साइन इन करें।',
  'Email ID': 'ईमेल आईडी',
  'Work email': 'कार्य ईमेल',
  'Password': 'पासवर्ड',
  'Add this key to your authenticator:': 'यह कुंजी अपने ऑथेंटिकेटर में जोड़ें:',
  'Six-digit code': 'छह अंकों का कोड',
  'Please wait…': 'कृपया प्रतीक्षा करें…',
  'Verify': 'सत्यापित करें',
  'Sign in': 'साइन इन',
  'Send password recovery email': 'पासवर्ड रीसेट ईमेल भेजें',
  'Access is assigned by your HR team. Your designation does not determine app permissions.':
      'अनुमति आपकी एचआर टीम देती है। आपका पदनाम ऐप की अनुमति तय नहीं करता।',
  'Welcome back': 'फिर से स्वागत है',
  'Forgot your password?': 'पासवर्ड भूल गए?',
  'Restoring your session…': 'आपका सत्र बहाल हो रहा है…',
};
String authText(String value) => tr(value, _authHindi[value] ?? value);
