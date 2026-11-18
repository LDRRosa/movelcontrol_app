import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/cliente_viewmodel.dart';
import '../../viewmodels/configuracoes_viewmodel.dart';
import '../../viewmodels/fornecedor_viewmodel.dart';
import '../../viewmodels/item_viewmodel.dart';
import '../../viewmodels/orcamento_viewmodel.dart';
import '../widgets/detalhe_widgets.dart';
import '../widgets/dialogos.dart';

/// Rota /configuracoes: tema, servidor da API, estoque mínimo e cache offline.
/// Tudo é persistido com shared_preferences pelo ConfiguracoesViewModel.
class ConfiguracoesPage extends StatefulWidget {
  const ConfiguracoesPage({super.key});

  @override
  State<ConfiguracoesPage> createState() => _ConfiguracoesPageState();
}

class _ConfiguracoesPageState extends State<ConfiguracoesPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _url;

  @override
  void initState() {
    super.initState();
    final config = context.read<ConfiguracoesViewModel>();
    _url = TextEditingController(text: config.urlApi ?? '');
    config.atualizarInfoCache();
  }

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  /// Recarrega todas as listas (ex.: depois de trocar o servidor).
  Future<void> _recarregarTudo() => Future.wait([
        context.read<ItemViewModel>().carregar(),
        context.read<ClienteViewModel>().carregar(),
        context.read<FornecedorViewModel>().carregar(),
        context.read<OrcamentoViewModel>().carregar(),
      ]);

  Future<void> _testar() async {
    if (!_formKey.currentState!.validate()) return;
    final erro =
        await context.read<ConfiguracoesViewModel>().testarConexao(_url.text);
    if (!mounted) return;
    mostrarMensagem(context, erro ?? 'Conexão bem-sucedida!', erro: erro != null);
  }

  Future<void> _salvarUrl({bool restaurarPadrao = false}) async {
    if (restaurarPadrao) _url.clear();
    if (!_formKey.currentState!.validate()) return;
    await context.read<ConfiguracoesViewModel>().salvarUrlApi(_url.text);
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    mostrarMensagem(context, 'Servidor salvo. Recarregando os dados...');
    await _recarregarTudo();
  }

  void _alterarEstoqueMinimo(int valor) {
    if (valor < 0) return;
    context.read<ConfiguracoesViewModel>().alterarEstoqueMinimo(valor);
    context.read<ItemViewModel>().definirEstoqueMinimo(valor);
  }

  Future<void> _limparCache() async {
    await context.read<ConfiguracoesViewModel>().limparCache();
    if (!mounted) return;
    mostrarMensagem(context, 'Dados offline apagados.');
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<ConfiguracoesViewModel>();
    final tema = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          // ---------- Aparência ----------
          const SecaoTitulo('Aparência'),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                  value: ThemeMode.system,
                  icon: Icon(Icons.brightness_auto),
                  label: Text('Sistema')),
              ButtonSegment(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode),
                  label: Text('Claro')),
              ButtonSegment(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode),
                  label: Text('Escuro')),
            ],
            selected: {config.tema},
            onSelectionChanged: (selecao) => config.alterarTema(selecao.first),
          ),

          // ---------- Servidor ----------
          const SecaoTitulo('Servidor da API'),
          Form(
            key: _formKey,
            child: TextFormField(
              controller: _url,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                labelText: 'URL da API',
                hintText: config.urlPadrao,
                helperText: 'Em uso: ${config.urlEmUso}\n'
                    'Deixe vazio para usar o padrão (${config.urlPadrao}).',
                helperMaxLines: 3,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.dns_outlined),
              ),
              validator: ConfiguracoesViewModel.validarUrl,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: config.testando ? null : _testar,
                icon: config.testando
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.network_check),
                label: const Text('Testar conexão'),
              ),
              FilledButton.icon(
                onPressed: _salvarUrl,
                icon: const Icon(Icons.save),
                label: const Text('Salvar'),
              ),
              TextButton(
                onPressed: () => _salvarUrl(restaurarPadrao: true),
                child: const Text('Restaurar padrão'),
              ),
            ],
          ),

          // ---------- Estoque ----------
          const SecaoTitulo('Estoque'),
          Card(
            child: ListTile(
              leading: Icon(Icons.warning_amber_rounded,
                  color: tema.colorScheme.error),
              title: const Text('Estoque mínimo'),
              subtitle: const Text(
                  'Itens abaixo dessa quantidade aparecem em vermelho'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Diminuir',
                    onPressed: config.estoqueMinimo > 0
                        ? () => _alterarEstoqueMinimo(config.estoqueMinimo - 1)
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text('${config.estoqueMinimo}',
                      style: tema.textTheme.titleMedium),
                  IconButton(
                    tooltip: 'Aumentar',
                    onPressed: () =>
                        _alterarEstoqueMinimo(config.estoqueMinimo + 1),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
            ),
          ),

          // ---------- Offline ----------
          const SecaoTitulo('Dados offline'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.storage_outlined),
              title: Text('${config.registrosEmCache} lista(s) salva(s) no aparelho'),
              subtitle: const Text(
                  'As listas são guardadas em um banco SQLite local e '
                  'exibidas quando não há conexão com a API.'),
              isThreeLine: true,
              trailing: TextButton(
                onPressed: config.registrosEmCache == 0 ? null : _limparCache,
                child: const Text('Limpar'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
