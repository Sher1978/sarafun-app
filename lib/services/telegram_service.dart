import 'package:telegram_web_app/telegram_web_app.dart';
import '../core/logger.dart';
// import 'dart:js_util' as js_util; // Removed to fix non-web analysis/build
// import 'dart:js_interop'; 

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
        try {
           // ready() might not be available in all versions or called differently?
           // The package 0.3.3 has ready()
           TelegramWebApp.instance.ready();
        } catch (e) {
           Logger.error("Telegram ready() warning: $e", name: 'TelegramService');
        }
      }
    } catch (e) {
      Logger.error("Telegram Init Error: $e", name: 'TelegramService');
    }
  }

  /// Share a referral link via Telegram
  void shareReferral({required String referrerId, required String masterId}) {
    const String botUsername = "SaraFunBot"; // Placeholder
    final String link = "https://t.me/$botUsername/app?startapp=ref_${referrerId}_master_$masterId";
    final String text = Uri.encodeComponent("Check out this master on SaraFun! Get 5% cashback and join the elite loyalty network in Dubai.");
    final String shareUrl = "https://t.me/share/url?url=${Uri.encodeComponent(link)}&text=$text";

    try {
      if (isSupported) {
        TelegramWebApp.instance.openTelegramLink(shareUrl);
      } else {
        // Fallback for browser testing
        Logger.log("Telegram Share Triggered: $shareUrl", name: 'TelegramService');
      }
    } catch (e) {
      Logger.error("Telegram Share Error: $e", name: 'TelegramService');
    }
  }

  /// Get the raw init data string from Telegram (for backend validation)
  String? getRawInitData() {
    try {
      if (isSupported) {
        // Direct access: initData is an object, we need the 'raw' string field
        // The log showed: TelegramInitData{..., raw: ...}
        // Assuming the package exposes .raw based on the log output
        return TelegramWebApp.instance.initData.raw; 
      }
    } catch (e) {
      Logger.error("Error fetching raw Telegram init data: $e", name: 'TelegramService');
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
      Logger.error("Error fetching Telegram user: $e", name: 'TelegramService');
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
      Logger.error("Error parsing deep link: $e", name: 'TelegramService');
    }
    return null;
  }
}

class DeepLinkData {
  final String? masterId;
  final String? referrerId;

  DeepLinkData({this.masterId, this.referrerId});
}

