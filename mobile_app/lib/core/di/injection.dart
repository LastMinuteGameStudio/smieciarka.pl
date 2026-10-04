import 'package:get_it/get_it.dart';
import 'package:uczciwa_cena/core/auth/auth_repository.dart';
import 'package:uczciwa_cena/core/auth/token_storage.dart';
import 'package:uczciwa_cena/core/network/api_client.dart';

void setupDependencies() {
  final tokens = TokenStorage();
  final dio = createApiClient(tokens);

  GetIt.instance.registerSingleton<AuthRepository>(
    AuthRepository(dio: dio, tokens: tokens),
  );
}
