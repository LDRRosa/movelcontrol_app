import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Um registro salvo no cache: o JSON da lista e quando foi atualizado.
class RegistroCache {
  final String json;
  final DateTime atualizadoEm;

  const RegistroCache(this.json, this.atualizadoEm);
}

/// Contrato do cache local. Há duas implementações:
/// - [SqfliteCacheLocal]: SQLite no dispositivo (Android, iOS, desktop);
/// - [MemoriaCacheLocal]: em memória (web e testes).
abstract class CacheLocal {
  Future<void> salvar(String chave, String json);
  Future<RegistroCache?> ler(String chave);
  Future<int> quantidadeDeRegistros();
  Future<void> limpar();

  /// Implementação adequada à plataforma atual.
  static CacheLocal padrao() =>
      kIsWeb ? MemoriaCacheLocal() : SqfliteCacheLocal.instancia;
}

/// Cache em SQLite (padrão singleton, como o DatabaseService da Aula 13).
///
/// Tabela única: cada lista do app (itens, clientes...) é uma linha, com o
/// JSON da última resposta da API e a data em que foi salva.
class SqfliteCacheLocal implements CacheLocal {
  static final SqfliteCacheLocal instancia = SqfliteCacheLocal._();
  SqfliteCacheLocal._();

  static Database? _database;

  Future<Database> get _banco async {
    if (_database != null) return _database!;
    final pasta = await getDatabasesPath();
    _database = await openDatabase(
      join(pasta, 'movelcontrol_cache.db'),
      version: 1,
      onCreate: (db, versao) => db.execute(
        'CREATE TABLE cache('
        'chave TEXT PRIMARY KEY, '
        'json TEXT NOT NULL, '
        'atualizado_em INTEGER NOT NULL)',
      ),
    );
    return _database!;
  }

  @override
  Future<void> salvar(String chave, String json) async {
    final db = await _banco;
    await db.insert(
      'cache',
      {
        'chave': chave,
        'json': json,
        'atualizado_em': DateTime.now().millisecondsSinceEpoch,
      },
      // Substitui o registro anterior da mesma lista.
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<RegistroCache?> ler(String chave) async {
    final db = await _banco;
    final linhas = await db.query('cache',
        where: 'chave = ?', whereArgs: [chave], limit: 1);
    if (linhas.isEmpty) return null;
    final linha = linhas.first;
    return RegistroCache(
      linha['json'] as String,
      DateTime.fromMillisecondsSinceEpoch(linha['atualizado_em'] as int),
    );
  }

  @override
  Future<int> quantidadeDeRegistros() async {
    final db = await _banco;
    return Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM cache')) ??
        0;
  }

  @override
  Future<void> limpar() async {
    final db = await _banco;
    await db.delete('cache');
  }
}

/// Cache em memória: usado na web (sem SQLite) e nos testes.
class MemoriaCacheLocal implements CacheLocal {
  final Map<String, RegistroCache> _dados = {};

  @override
  Future<void> salvar(String chave, String json) async =>
      _dados[chave] = RegistroCache(json, DateTime.now());

  @override
  Future<RegistroCache?> ler(String chave) async => _dados[chave];

  @override
  Future<int> quantidadeDeRegistros() async => _dados.length;

  @override
  Future<void> limpar() async => _dados.clear();
}
