import 'package:logger/logger.dart';

final appLogger = Logger(
  printer: PrettyPrinter(
    methodCount: 2,
    errorMethodCount: 8,
    lineLength: 140,
    colors: true,
    dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
  ),
);