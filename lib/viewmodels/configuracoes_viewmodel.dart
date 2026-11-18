import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../repositories/configuracoes_repository.dart';
import '../services/api_client.dart';
import '../services/cache_local_service.dart';

/// Estado da tela de Configurações (padrão SettingsViewModel da Aula 13):
/// tema, URL da API, estoque mínimo e dados salvos para uso offline.
class ConfiguracoesViewModel extends ChangeNotifier {
  final ConfiguracoesRepository _repositorio;
  final CacheLocal _cache;

  ConfiguracoesViewModel({
    ConfiguracoesRepository? repositorio,
    CacheLocal? cache,
  })  : _repositorio = repositorio ?? ConfiguracoesRepository(),
        _cache = cache ?? CacheLocal.padrao();

  static const int estoqueMinimoPadrao = 5;

  ThemeMode _tema = ThemeMode.system;
  String? _urlApi;
  int _estoqueMinimo = estoqueMinimoPadrao;
  bool _testando = false;
  int _registrosEmCache = 0;

  ThemeMode get tema => _tema;
  String? get urlApi => _urlApi;
  String get urlEmUso => ApiConfig.baseUrl;
  String get urlPadrao => ApiConfig.urlPadrao;
  int get estoqueMinimo => _estoqueMinimo;
  bool get testando => _testando;
  int get registrosEmCache => _registrosEmCache;

  /// Chamado no main() antes do runApp, para que o tema e a URL já estejam
  /// definidos quando a primeira tela carregar os dados.
  Future<void> carregar() async {
    try {
      _tema = await _repositorio.lerTema();
      _urlApi = await _repositorio.lerUrlApi();
      _estoqueMinimo =
          await _repositorio.lerEstoqueMinimo() ?? estoqueMinimoPadrao;
    } catch (_) {
      // Sem preferências salvas (ou plataforma sem suporte): usa os padrões.
    }
    ApiConfig.definirUrl(_urlApi);
    await atualizarInfoCache();
    notifyListeners();
  }

  Future<void> alterarTema(ThemeMode tema) async {
    _tema = tema;
    notifyListeners(); // a troca de tema é imediata
    await _repositorio.salvarTema(tema);
  }

  Future<void> alterarEstoqueMinimo(int valor) async {
    if (valor < 0) return;
    _estoqueMinimo = valor;
    notifyListeners();
    await _repositorio.salvarEstoqueMinimo(valor);
  }

  /// Valida o formato da URL (para o TextFormField).
  static String? validarUrl(String? valor) {
    final texto = valor?.trim() ?? '';
    if (texto.isEmpty) return null; // vazio = usar a URL padrão
    final uri = Uri.tryParse(texto);
    if (uri == null ||
        !(uri.scheme == 'http' || uri.scheme == 'https') ||
        uri.host.isEmpty) {
      return 'Informe uma URL como http://192.168.0.10:8080';
    }
    return null;
  }

  /// Faz uma requisição de teste. Retorna null se conectou, ou o erro.
  Future<String?> testarConexao(String url) async {
    _testando = true;
    notifyListeners();
    try {
      final alvo = url.trim().isEmpty ? ApiConfig.urlPadrao : url.trim();
      await ApiClient(baseUrl: alvo.replaceAll(RegExp(r'/+$'), ''))
          .get('/item/todos');
      return null;
    } on ApiException catch (e) {
      return e.mensagem;
    } finally {
      _testando = false;
      notifyListeners();
    }
  }

  /// Salva a URL (vazia = voltar ao padrão) e passa a usá-la imediatamente.
  Future<void> salvarUrlApi(String? url) async {
    final texto = url?.trim() ?? '';
    _urlApi = texto.isEmpty ? null : texto;
    ApiConfig.definirUrl(_urlApi);
    notifyListeners();
    await _repositorio.salvarUrlApi(_urlApi);
  }

  Future<void> atualizarInfoCache() async {
    try {
      _registrosEmCache = await _cache.quantidadeDeRegistros();
    } catch (_) {
      _registrosEmCache = 0;
    }
    notifyListeners();
  }

  Future<void> limparCache() async {
    try {
      await _cache.limpar();
    } catch (_) {}
    await atualizarInfoCache();
  }
}
