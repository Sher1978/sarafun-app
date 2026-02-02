import 'package:telegram_web_app/telegram_web_app.dart';

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
        startParam = Uri.base.queryParameters['tg_start'];
      }

      if (startParam != null && startParam.startsWith('ref_')) {
        final parts = startParam.split('_');
        // Expected parts: [ref, MASTERID, USERID] OR [ref, USERID]
        
        if (parts.length == 3) {
          return DeepLinkData(
            masterId: parts[1].isEmpty ? null : parts[1],
            referrerId: parts[2].isEmpty ? null : parts[2],
          );
        } else if (parts.length == 2) {
          return DeepLinkData(
            referrerId: parts[1].isEmpty ? null : parts[1],
          );
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
