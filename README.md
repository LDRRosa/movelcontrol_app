# MovelControl App (Flutter)

App Flutter que consome a API REST **MovelControl** (Spring Boot): monta
**Orçamentos** (cliente + itens do estoque, total em tempo real, status) e faz o
CRUD de **Itens do estoque**, **Fornecedores** e **Clientes (pessoa física)**.

Conceitos aplicados:

| Conceito | Onde |
|---|---|
| Navegação inferior | `views/home_page.dart`: `NavigationBar` (Início, Orçamentos, Cadastros) + `IndexedStack`; destino guardado no `NavegacaoViewModel` |
| Abas | `views/cadastros_page.dart`: `TabBar` + `TabBarView` com `TabController` controlado pelo ViewModel |
| Rotas nomeadas | `rotas.dart`: mapa central (`/orcamentos/7`, `/clientes/3/editar`...) com `onGenerateRoute` e pattern matching |
| Listas | `views/*/..._list_view.dart`: `ListView.builder`, busca, filtros, puxar para atualizar |
| Estado (Provider) | `main.dart`: `MultiProvider`/`ChangeNotifierProvider`; Views usam `Consumer`, `context.watch`, `context.select` e `context.read` |
| Estado derivado | `DashboardViewModel` via `ProxyProvider3`: recalculado sempre que itens, clientes ou orçamentos mudam |
| MVVM | `models/` → `services/` → `viewmodels/` (`ChangeNotifier`) → `views/` |
| ViewModel combinando dados | `OrcamentoFormViewModel` (clientes + itens) e `ClienteDetalhePage` (cliente + histórico de orçamentos) |
| Provider com escopo de tela | `rotas.dart`: formulário de orçamento e detalhe do fornecedor recebem seu próprio `ChangeNotifierProvider` na rota |
| Validação | `Form` + `GlobalKey<FormState>` + `TextFormField.validator` (`utils/validadores.dart`); `FormField` customizado para cliente e lista de itens do orçamento |
| Consumo de API | `services/api_client.dart` (pacote `http`, GET/POST/PUT/DELETE) e `services/cep_service.dart` (ViaCEP) |
| Preferências (shared_preferences) | `repositories/configuracoes_repository.dart` + `ConfiguracoesViewModel`: tema claro/escuro, URL da API e estoque mínimo |
| Banco local (sqflite) | `services/cache_local_service.dart` (singleton) + `repositories/repositorio_com_cache.dart`: cache das listas para uso offline |
| Rascunho persistente | `OrcamentoFormViewModel` grava o orçamento em edição no shared_preferences e o restaura se o app fechar |
| Máscaras de digitação | `utils/mascaras.dart`: `TextInputFormatter` para CPF, CNPJ, CEP, telefone e moeda |
| Gestos | `Dismissible` nas listas: arrastar para excluir com "Desfazer" |

## Estrutura

```
lib/
├── main.dart                     # Providers + MaterialApp
├── config/api_config.dart        # URL base da API
├── models/                       # Item, Fornecedor, Cliente, Endereco (fromJson/toJson)
├── services/                     # Acesso HTTP a cada recurso da API (sem estado)
│   ├── api_client.dart
│   ├── item_service.dart
│   ├── fornecedor_service.dart
│   └── cliente_service.dart
├── viewmodels/                   # Estado da UI + comandos (carregar, salvar, excluir, filtrar)
├── utils/                        # Validadores (CPF, CNPJ, e-mail, CEP...) e formatadores
└── views/
    ├── home_page.dart            # Abas
    ├── item/                     # Lista + formulário
    ├── fornecedor/
    ├── cliente/
    └── widgets/                  # Componentes reutilizáveis
test/                             # Testes de validação, parsing da API e ViewModel
```

## Como executar

1. Suba a API (projeto separado em `Documents/MovelControl`, com o MySQL rodando):
   ```bash
   cd ../MovelControl && ./mvnw spring-boot:run        # Windows: .\mvnw.cmd spring-boot:run
   ```
2. Nesta pasta, gere as pastas de plataforma (só na primeira vez; não altera `lib/` nem `pubspec.yaml`):
   ```bash
   flutter create . --project-name movelcontrol_app --platforms=android,windows,web
   flutter pub get
   ```
3. Execute:
   ```bash
   flutter run -d windows        # ou: flutter run -d emulator-5554
   ```

### URL da API

`lib/config/api_config.dart` escolhe automaticamente:

- Emulador Android: `http://10.0.2.2:8080`
- Windows / Web: `http://localhost:8080`

Para um celular físico, informe o IP do computador:
`flutter run --dart-define=API_URL=http://192.168.0.10:8080`

### Android: liberar HTTP sem TLS

Depois do `flutter create`, adicione em `android/app/src/main/AndroidManifest.xml`,
na tag `<application ...>`:

```xml
android:usesCleartextTraffic="true"
```

E, antes de `<application>`, garanta a permissão de internet:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

### Persistência local por plataforma

- **Android / iOS / macOS**: `sqflite` nativo.
- **Windows / Linux**: `sqflite_common_ffi` (inicializado em `services/sqflite_inicializacao.dart`)
  com a biblioteca SQLite embarcada por `sqlite3_flutter_libs`.
- **Web**: não há SQLite; o cache offline fica só em memória durante a sessão.
- A URL da API também pode ser trocada pelo app em **Configurações** (ícone de engrenagem no Início).

### Flutter Web (CORS)

A API só libera CORS para `http://localhost:8080`. Para rodar no navegador, inclua a
origem do app em `MovelControl/src/main/resources/application.properties`, por exemplo
`myapp.cors.allowed-origins=http://localhost:8080,http://localhost:5000`, e rode
`flutter run -d chrome --web-port 5000`.

## Testes

```bash
flutter test
```

## Observações sobre a API

O app contorna estes comportamentos da API:

- **Itens**: o `PUT /item/atualizar/{id}` copia o `id` do corpo para a entidade, então o
  app sempre envia o `id` (sem ele a API cria um registro novo).
- **Clientes**: `PessoaFisicaResponseDTO` não tem `id`; o app extrai o id dos links
  HATEOAS de `/pf/listar`. Quando não há clientes a API responde 404, que o app trata
  como lista vazia.
- **Fornecedores**: `/fornecedor/buscartudo` devolve uma coleção HAL (`_embedded`), e a
  coluna `cnpj` tem 14 caracteres, então o CNPJ é enviado só com dígitos.
