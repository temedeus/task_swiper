import 'package:get_it/get_it.dart';
import 'package:taskswiper/service/database_service.dart';
import 'package:taskswiper/service/recurrence_service.dart';

GetIt locator = GetIt.instance;

setupServiceLocator() {
  locator.registerLazySingleton<DatabaseService>(() => DatabaseService());
  locator.registerLazySingleton<RecurrenceService>(
      () => RecurrenceService(locator<DatabaseService>()));
}
