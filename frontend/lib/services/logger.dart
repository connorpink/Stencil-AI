import 'package:logger/logger.dart';

final appLogger = Logger(
  printer: PrettyPrinter(
    methodCount: 6,
    errorMethodCount: 8,
    lineLength: 12,
    colors: true,
    dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
  ),
);