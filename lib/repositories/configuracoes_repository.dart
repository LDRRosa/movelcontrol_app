import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preferências do usuário (chave-valor com shared_preferences, Aula 13).
class ConfiguracoesRepository {
  static const _chaveTema = 'tema';
  static const _chaveUrlApi = 'url_api';
  static const _chaveEstoqueMinimo = 'estoque_minimo';

  Future<ThemeMode> lerTema() async {
    final prefs = await SharedPreferences.getInstance();
    return switch (prefs.getString(_chaveTema)) {
      'claro' => ThemeMode.light,
      'escuro' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> salvarTema(ThemeMode tema) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chaveTema, switch (tema) {
      ThemeMode.light => 'claro',
      ThemeMode.dark => 'escuro',
      ThemeMode.system => 'sistema',
    });
  }

  /// Null quando o usuário usa a URL padrão.
  Future<String?> lerUrlApi() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_chaveUrlApi);
  }

  Future<void> salvarUrlApi(String? url) async {
    final prefs = await SharedPreferences.getInstance();
    if (url == null || url.trim().isEmpty) {
      await prefs.remove(_chaveUrlApi);
    } else {
      await prefs.setString(_chaveUrlApi, url.trim());
    }
  }

  Future<int?> lerEstoqueMinimo() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_chaveEstoqueMinimo);
  }

  Future<void> salvarEstoqueMinimo(int valor) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_chaveEstoqueMinimo, valor);
  }
}

/// Rascunho do orçamento em edição, salvo como JSON no shared_preferences
/// para sobreviver ao fechamento do app.
class RascunhoOrcamentoRepository {
  static const _chave = 'rascunho_orcamento';

  Future<Map<String, dynamic>?> ler() async {
    final prefs = await SharedPreferences.getInstance();
    final texto = prefs.getString(_chave);
    if (texto == null) return null;
    try {
      return jsonDecode(texto) as Map<String, dynamic>;
    } catch (_) {
      await prefs.remove(_chave); // rascunho corrompido: descarta
      return null;
    }
  }

  Future<void> salvar(Map<String, dynamic> rascunho) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chave, jsonEncode(rascunho));
  }

  Future<void> limpar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_chave);
  }
}
