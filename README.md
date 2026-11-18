# MovelControl App (Flutter)

App Flutter que consome a API REST **MovelControl** (Spring Boot) e faz o CRUD de
**Itens do estoque**, **Fornecedores** e **Clientes (pessoa física)**.

Conceitos aplicados:

| Conceito | Onde |
|---|---|
| Abas | `views/home_page.dart`: `DefaultTabController` + `TabBar` + `TabBarView` |
| Listas | `views/*/..._list_view.dart`: `ListView.builder`, busca, puxar para atualizar |
| Estado (Provider) | `main.dart`: `MultiProvider`/`ChangeNotifierProvider`; Views usam `Consumer`, `context.watch` e `context.read` |
| MVVM | `models/` → `services/` → `viewmodels/` (`ChangeNotifier`) → `views/` |
| Validação | `Form` + `GlobalKey<FormState>` + `TextFormField.validator` (`utils/validadores.dart`) |
| Consumo de API | `services/api_client.dart` (pacote `http`, GET/POST/PUT/DELETE) |

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
