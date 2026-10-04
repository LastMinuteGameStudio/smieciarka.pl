import 'package:get_it/get_it.dart';
import 'package:uczciwa_cena/core/auth/auth_repository.dart';
import 'package:uczciwa_cena/core/auth/token_storage.dart';
import 'package:uczciwa_cena/core/network/api_client.dart';
import 'package:uczciwa_cena/features/alerts/data/alerts_repository.dart';
import 'package:uczciwa_cena/features/items/data/listings_repository.dart';

void setupDependencies() {
  final tokens = TokenStorage();
  final dio = createApiClient(tokens);

  GetIt.instance.registerSingleton<AuthRepository>(
    AuthRepository(dio: dio, tokens: tokens),
  );
  GetIt.instance.registerSingleton<ListingsRepository>(
    ListingsRepository(dio: dio),
  );
  GetIt.instance.registerSingleton<AlertsRepository>(
    AlertsRepository(dio: dio),
  );
}
