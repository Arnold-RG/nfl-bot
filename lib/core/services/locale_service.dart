import 'package:flutter/foundation.dart';

import '../data/world_countries.dart';
import '../data/world_currencies.dart';
import '../data/world_languages.dart';
import '../l10n/app_copy.dart';
import 'preferences_service.dart';

/// Language, country, and billing currency chosen by the member.
class LocaleService extends ChangeNotifier {
  final PreferencesService prefs;

  LocaleService(this.prefs);

  WorldLanguage get language => WorldLanguages.byCode(prefs.languageCode);
  WorldCountry get country => WorldCountries.byIso(prefs.countryCode);
  WorldCurrency get currency => WorldCurrencies.byCode(prefs.currencyCode);
  AppCopy get copy => AppCopy(language.code);

  String get speechLocale => language.speechLocale;

  Future<void> setLanguage(String code) async {
    await prefs.setLanguageCode(code);
    notifyListeners();
  }

  Future<void> applyCountry(String iso2) async {
    final nation = WorldCountries.byIso(iso2);
    await prefs.setCountryCode(nation.iso2);
    await prefs.setCurrencyCode(nation.currencyCode);
    if (prefs.languageCode == 'en' || prefs.languageUntouched) {
      await prefs.setLanguageCode(nation.languageCode);
    }
    notifyListeners();
  }

  Future<void> setCurrency(String code) async {
    await prefs.setCurrencyCode(code);
    notifyListeners();
  }

  /// First launch: browser/device locale if we know that country.
  void suggestFromDevice() {
    if (prefs.countryChosen) return;
    final locale = PlatformDispatcher.instance.locale;
    final iso = locale.countryCode;
    if (iso != null && iso.isNotEmpty) {
      final match = WorldCountries.all.where((c) => c.iso2 == iso.toUpperCase());
      if (match.isNotEmpty) {
        prefs.setCountryCode(match.first.iso2);
        prefs.setCurrencyCode(match.first.currencyCode);
        prefs.setLanguageCode(locale.languageCode);
      }
    }
  }
}
