import 'package:get_it/get_it.dart';
import '../services/connectivity_service.dart';
import '../services/websocket_service.dart';
import '../services/api_service.dart';

final GetIt getIt = GetIt.instance;

void configureDependencies() {
  // Register services as singletons
  getIt.registerSingleton<ConnectivityService>(ConnectivityService());
  getIt.registerSingleton<WebSocketService>(WebSocketService());
  getIt.registerSingleton<ApiService>(ApiService());
}
