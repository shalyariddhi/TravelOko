import 'package:logger/logger.dart';

/// Global logger instance
/// Usage: 
/// appLogger.d("Debug message");
/// appLogger.i("Info message");
/// appLogger.w("Warning message");
/// appLogger.e("Error message", error: e, stackTrace: s);
final Logger appLogger = Logger(
  printer: PrettyPrinter(
    methodCount: 0, 
    errorMethodCount: 8, 
    lineLength: 80, 
    colors: true, 
    printEmojis: true, 
    dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
  ),
);
