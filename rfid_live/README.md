# RFID LIVE — Rastreamento Inteligente de Ferramentas

Aplicativo mobile em **Flutter/Dart** para rastreamento de ferramentas industriais por
etiquetas **RFID**, com painel gerencial, mapa da planta em tempo real, inventário,
alertas e indicadores de BI.

> TCC RFID 2025 · Sistema Inteligente Industrial

---

## 1. O que o aplicativo faz

| Tela | Conteúdo |
|------|----------|
| **Login / Cadastro** | Autenticação local com senha protegida por hash SHA-256 + salt, sessão persistente e criação de conta por função na planta. |
| **Painel Geral** | KPIs (total rastreadas, em uso, disponíveis, não localizadas), distribuição de status, indicadores operacionais (utilização, visibilidade RFID, patrimônio rastreado), últimas movimentações e alertas ativos. |
| **Mapa da Planta** | Zonas da fábrica em tempo real (Linha A, Linha B, Qualidade, Manutenção, Almoxarifado e "Fora de cobertura"), ocupação por zona, leituras ao vivo das antenas e detalhe de cada zona. |
| **Inventário** | Busca por nome/código/EPC, filtros por status, ordenação, cadastro de novas ferramentas e ficha completa de cada item. |
| **Ficha da ferramenta** | Localizar via antena, registrar movimentação, enviar/concluir manutenção, ficha técnica e histórico da etiqueta. |
| **Alertas** | Ferramenta não localizada, manutenção vencida e bateria baixa de antena, com resolução individual ou em lote. |
| **Histórico** | Linha do tempo de movimentações com filtro por tipo e aba **Indicadores** (movimentações por hora, prontidão, utilização, ranking de ferramentas, ocupação por zona e patrimônio sob rastreio). |

### Recursos adicionais implementados

- **Simulação RFID ao vivo**: a cada 5 segundos o app processa leituras, movimentações,
  consumo de bateria das antenas e perda de sinal — podendo ser pausada no menu da conta.
- **Painel da conta**: status das 5 antenas (bateria, RSSI, leituras do dia), chave do
  modo ao vivo e logout.
- **Indicadores de gestão** pensados para leitura executiva: taxa de utilização,
  prontidão, visibilidade das etiquetas e exposição financeira sem rastreio.
- Interface 100% em português, tema escuro industrial, pull-to-refresh, estados vazios
  e validação em todos os formulários.
- **Acessibilidade**: KPIs, anéis de BI, histograma e barras de ranking são desenhados em
  canvas e receberam rótulos semânticos, para que um leitor de tela leia "Utilização: 33%"
  em vez de ignorar o gráfico. As abas anunciam nome e seleção.
- **Integridade da etiqueta**: o EPC é único na planta e validado no formato `E2:XX:XX:XX`
  (hexadecimal) — duas etiquetas com o mesmo código tornariam a leitura das antenas
  ambígua.

---

## 2. Requisitos

| Item | Versão usada / mínima |
|------|----------------------|
| Flutter SDK | **3.47.3** (canal `stable`) — mínimo 3.35 |
| Dart SDK | **3.13.3** (vem junto com o Flutter) — mínimo 3.12.2 |
| Android Studio ou VS Code | qualquer versão recente |
| Android SDK | API 21+ (para rodar em Android) |
| Xcode | 15+ (somente para iOS, exige macOS) |

---

## 3. Passo a passo para rodar o aplicativo

### 3.1 Instalar o Flutter

**Windows**

1. Baixe o SDK em <https://docs.flutter.dev/get-started/install/windows>.
2. Extraia o zip em `C:\src\flutter` (evite pastas com espaços ou acentos).
3. Adicione `C:\src\flutter\bin` à variável de ambiente `Path`.
4. Abra um novo terminal e rode `flutter --version`.

**macOS / Linux**

```bash
git clone https://github.com/flutter/flutter.git -b stable ~/flutter
export PATH="$HOME/flutter/bin:$PATH"     # adicione essa linha ao ~/.zshrc ou ~/.bashrc
flutter --version
```

### 3.2 Conferir o ambiente

```bash
flutter doctor
```

Resolva o que aparecer com `[!]`. Para Android, normalmente é preciso rodar:

```bash
flutter doctor --android-licenses
```

### 3.3 Baixar as dependências do projeto

```bash
cd rfid_live
flutter pub get
```

Isso instala automaticamente os pacotes declarados no `pubspec.yaml`:

| Pacote | Para que serve |
|--------|----------------|
| `provider` | Gerenciamento de estado (ChangeNotifier) |
| `intl` | Formatação de datas, horas e moeda em pt-BR |
| `shared_preferences` | Sessão do usuário e preferências no dispositivo |
| `crypto` | Hash SHA-256 das senhas |
| `flutter_localizations` | Textos nativos do Material em português |
| `cupertino_icons` | Ícones complementares |

> Não é necessário instalar nada manualmente: o `flutter pub get` resolve tudo.
> Se aparecer erro de versão, rode `flutter pub upgrade --major-versions`.

### 3.4 Executar

```bash
flutter devices          # lista emuladores/aparelhos conectados
flutter run              # roda em modo debug no dispositivo selecionado
```

- **Android**: ative a *depuração USB* no celular ou abra um emulador pelo Android Studio.
- **iOS**: `open ios/Runner.xcworkspace`, selecione um time de assinatura e rode.
- **Web (para demonstrar no navegador)**: `flutter run -d chrome`.

### 3.5 Acesso de demonstração

```
E-mail: admin@rfidlive.com.br
Senha:  123456
```

Na tela de login há o botão **"Preencher acesso de demonstração"**.
Também é possível criar uma conta nova pela opção **Criar nova conta**.

### 3.6 Identidade do aplicativo

| Onde | Valor |
|------|-------|
| Nome exibido (Android/iOS/Web) | **RFID Live** |
| Package / Application ID | `br.com.rfidlive.app` |
| Bundle Identifier (iOS) | `br.com.rfidlive.app` |
| Nome do pacote Dart | `rfid_live` |

> O aplicativo não usa GPS: o `AndroidManifest.xml` não declara nenhuma permissão de
> localização. As permissões `ACCESS_FINE_LOCATION`/`ACCESS_COARSE_LOCATION` que existiam
> eram resíduo dos exercícios em `examples/` e foram removidas.

### 3.7 Gerar o APK para entrega

```bash
flutter build apk --release
# saída: build/app/outputs/flutter-apk/app-release.apk
```

Para publicar na Play Store use `flutter build appbundle --release`.

---

## 4. Testes

```bash
flutter analyze   # análise estática — deve terminar com "No issues found!"
flutter test      # 51 testes automatizados
```

Cobertura da suíte:

- `test/plant_repository_test.dart` — regras de negócio: inventário inicial, busca,
  movimentações, manutenção, localização por antena, cadastro, alertas e 500 ciclos da
  simulação em tempo real verificando a consistência dos dados. Inclui as regras da
  etiqueta: o EPC é único na planta, precisa estar no formato hexadecimal lido pelas
  antenas e o código patrimonial nunca é reaproveitado.
- `test/auth_repository_test.dart` — login, cadastro, senha incorreta, e-mail duplicado,
  sessão persistente e garantia de que a senha nunca é gravada em texto puro.
- `test/formatters_test.dart` — formatação de datas, horas, durações, percentuais e moeda.
- `test/widget_test.dart` — telas reais: login, validação de formulário, navegação entre
  as cinco abas, busca e filtros do inventário, abertura da ficha da ferramenta e recusa
  de EPC duplicado ou fora do formato no cadastro.
- Acessibilidade — verifica que KPIs, gráficos, abas e botões expõem rótulos ao leitor
  de tela (`find.bySemanticsLabel`).

---

## 5. Estrutura do código

```
lib/
├── main.dart                    # inicialização (locale pt-BR, orientação)
├── app.dart                     # MaterialApp, providers e roteamento por estado de login
├── core/
│   ├── theme/                   # paleta e tema escuro industrial
│   ├── utils/formatters.dart    # datas, horas, moeda e "tempo atrás"
│   └── widgets/                 # cartões, badges, cabeçalho ao vivo e gráficos
├── data/
│   ├── models/                  # Tool, Zone, Antenna, Movement, PlantAlert, AppUser
│   ├── seed_data.dart           # base de demonstração da planta
│   └── repositories/            # PlantRepository (middleware RFID) e AuthRepository
├── state/                       # PlantController e AuthController (ChangeNotifier)
└── features/                    # uma pasta por tela: auth, shell, dashboard, map,
                                 # inventory, alerts, history
examples/                        # exercícios antigos de mapa/GPS, mantidos fora do app
```

---

## 6. Integrando com hardware RFID real

Toda a leitura das etiquetas está isolada em `lib/data/repositories/plant_repository.dart`.
Para conectar o sistema a um leitor/middleware de verdade, basta substituir a origem dos
dados mantendo a mesma interface pública (`tools`, `movements`, `alerts`, `antennas`,
`registerMovement`, `locate`, ...):

1. **Leitor via rede (mais comum em planta)** — o concentrador das antenas publica as
   leituras via HTTP ou MQTT. Adicione `http: ^1.2.0` (ou `mqtt_client`) ao `pubspec.yaml`
   e troque o método `tick()` por um `Stream` alimentado pelo servidor.
2. **Leitor Bluetooth de mão (handheld)** — adicione `flutter_blue_plus` e converta as
   notificações do leitor em objetos `TagReading`.
3. **Leitor NFC embutido no celular** — adicione `nfc_manager`, útil para conferência
   ponto a ponto de etiquetas HF.
4. **Banco de dados** — para persistir o inventário no aparelho use `sqflite` ou
   `hive`; para nuvem, `firebase_core` + `cloud_firestore` ou uma API REST própria.

Nenhum desses pacotes é necessário para a versão atual: o app já roda completo com a
simulação embarcada.
