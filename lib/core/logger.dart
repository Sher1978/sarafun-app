
import 'dart:developer' as developer;

class Logger {
  static void log(String message, {String name = 'App'}) {
    developer.log(message, name: name);
  }

  static void error(String message, {Object? error, StackTrace? stackTrace, String name = 'App'}) {
    developer.log(message, name: name, error: error, stackTrace: stackTrace, level: 1000);
  }
}
