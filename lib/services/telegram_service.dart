import 'package:telegram_web_app/telegram_web_app.dart';
import 'dart:js_util' as js_util;
import 'dart:js_interop'; // Keep for types if needed, or remove if strictly util

class TelegramService {
  static final TelegramService _instance = TelegramService._internal();
  factory TelegramService() => _instance;
  TelegramService._internal();

  /// Returns true if running inside Telegram Web App
  bool get isSupported => TelegramWebApp.instance.isSupported;

  /// Initialize the Web App (expand to full screen)
  void init() {
    try {
      if (isSupported) {
        TelegramWebApp.instance.expand();
        TelegramWebApp.instance.ready();
      }
    } catch (e) {
      print("Telegram Init Error: $e");
    }
  }

  /// Share a referral link via Telegram
  void shareReferral({required String referrerId, required String masterId}) {
    final String botUsername = "SaraFunBot"; // Placeholder
    final String link = "https://t.me/$botUsername/app?startapp=ref_${referrerId}_master_$masterId";
    final String text = Uri.encodeComponent("Check out this master on SaraFun! Get 5% cashback and join the elite loyalty network in Dubai.");
    final String shareUrl = "https://t.me/share/url?url=${Uri.encodeComponent(link)}&text=$text";

    try {
      if (isSupported) {
        TelegramWebApp.instance.openTelegramLink(shareUrl);
      } else {
        // Fallback for browser testing
        print("Telegram Share Triggered: $shareUrl");
      }
    } catch (e) {
      print("Telegram Share Error: $e");
    }
  }

  /// Get the raw init data string from Telegram (for backend validation)
  String? getRawInitData() {
    try {
      if (isSupported) {
        // Access raw string using js_util (dynamic access)
        final win = js_util.globalThis;
        final telegram = js_util.getProperty(win, 'Telegram');
        final webApp = js_util.getProperty(telegram, 'WebApp');
        return js_util.getProperty(webApp, 'initData');
      }
    } catch (e) {
      print("Error fetching raw Telegram init data: $e");
    }
    return null;
  }

  /// Get the current Telegram User
  WebAppUser? getTelegramUser() {
    try {
      if (isSupported) {
        return TelegramWebApp.instance.initDataUnsafe?.user;
      }
    } catch (e) {
      print("Error fetching Telegram user: $e");
    }
    return null;
  }

  /// Parse Deep Link data from Telegram start_param
  /// Format: ref_MASTERID_USERID
  DeepLinkData? getDeepLinkData() {
    try {
      String? startParam;
      if (isSupported) {
        startParam = TelegramWebApp.instance.initDataUnsafe?.startParam;
      } else {
        // MOCK for browser testing
        final uri = Uri.base;
        startParam = uri.queryParameters['tg_start_param'] ?? uri.queryParameters['startapp'];
      }

      if (startParam != null && (startParam.startsWith('ref_') || startParam.startsWith('master_'))) {
        // Handle various formats:
        // 1. ref_MASTERID_USERID
        // 2. ref_USERID (just referrer)
        // 3. master_MASTERID (direct master link)
        
        final parts = startParam.split('_');
        
        if (startParam.startsWith('ref_')) {
          if (parts.length >= 3) {
             // ref_MASTERID_REFERRERID
             return DeepLinkData(
               masterId: parts[1].isEmpty ? null : parts[1],
               referrerId: parts[2].isEmpty ? null : parts[2],
             );
          } else if (parts.length == 2) {
            // ref_REFERRERID
            return DeepLinkData(
              referrerId: parts[1].isEmpty ? null : parts[1],
            );
          }
        } else if (startParam.startsWith('master_')) {
           // master_MASTERID
           if (parts.length >= 2) {
             return DeepLinkData(
               masterId: parts[1].isEmpty ? null : parts[1],
             );
           }
        }
      }
    } catch (e) {
      print("Error parsing deep link: $e");
    }
    return null;
  }
}

class DeepLinkData {
  final String? masterId;
  final String? referrerId;

  DeepLinkData({this.masterId, this.referrerId});
}
