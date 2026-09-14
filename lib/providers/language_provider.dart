import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class LanguageProvider extends ChangeNotifier {
  String _lang = 'uz_lat';

  String get lang => _lang;

  String get langLabel {
    switch (_lang) {
      case 'uz_lat':
        return "O'zbekcha";
      case 'uz_cyr':
        return 'Ўзбекча';
      case 'ru':
        return 'Русский';
      default:
        return "O'zbekcha";
    }
  }

  static const languages = [
    {'code': 'uz_lat', 'label': "Lotin (O'z)"},
    {'code': 'uz_cyr', 'label': 'Кирилл (Ўз)'},
    {'code': 'ru', 'label': 'Русский'},
  ];

  Future<void> init() async {
    _lang = await StorageService.getLanguage();
    notifyListeners();
  }

  Future<void> setLanguage(String lang) async {
    _lang = lang;
    await StorageService.saveLanguage(lang);
    notifyListeners();
  }
}
