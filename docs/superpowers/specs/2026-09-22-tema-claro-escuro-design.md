# Tema claro e escuro no RFID Live

**Data:** 2026-09-22
**Estado:** aprovado, aguardando plano de implementação

## Problema

O app só tem tema escuro. Clientes pediram poder usar os dois.

Hoje não existe mecanismo de tema: são **250 referências a `AppColors.*`** em
**25 arquivos**, todas `static const`, resolvidas em tempo de compilação.
`Theme.of(context)` não aparece em lugar nenhum de `lib/`. Existe um único
`ThemeData`, `AppTheme.dark`.

Ou seja, o trabalho não é "acrescentar um tema claro" — é dar ao app a
capacidade de ler tema, que ele não tem.

## Objetivos

1. Três modos: Sistema (padrão), Claro e Escuro, escolhidos pelo usuário e
   persistidos entre sessões.
2. Paleta clara derivada da identidade da Atlas, não inventada.
3. As quatro cores de status continuam legíveis nos dois temas.
4. Impossível, por construção, esquecer uma cor fixa para trás.

## Não-objetivos

- **Corrigir o contraste de `textMuted`.** Ele já está em 2,96:1 no tema
  escuro atual, abaixo dos 4,5:1 de AA. É anterior a esta mudança e vale para
  texto terciário decorativo (legendas, rótulos de apoio). O valor claro
  proposto fica em 3,39:1 — melhor que hoje, ainda abaixo de AA. Mexer nisso é
  uma decisão de design separada, com impacto visual em toda tela, e não entra
  aqui. O teste de contraste desta spec **exclui `textMuted` explicitamente**,
  com esse motivo escrito no teste.
- Tema claro no iOS e na web (o app é Android por ora).
- Temas customizados por cliente.
- Redesenho de layout. A responsividade em paisagem é trabalho separado.

## Origem da paleta clara

O site da Atlas (`theatlasdev.com.br/style.css`) já define um tema claro em
`html.light`, invertendo os mesmos tokens. Como `AppColors` foi derivada
desses tokens, o mapeamento é direto.

| Token do app    | Escuro                    | Claro                   | Origem              |
|-----------------|---------------------------|-------------------------|---------------------|
| `background`    | `#0A0A0A`                 | `#FAFAF8`               | site `--black`      |
| `backgroundTop` | `#121212`                 | `#F0F0F0`               | site `--black-soft` |
| `surface`       | `#1A1A1A`                 | `#E8E8E8`               | site `--surface`    |
| `surfaceAlt`    | `#232323`                 | `#D8D8D8`               | site `--surface-2`  |
| `surfaceInput`  | `#161616`                 | `#F2F2F0`               | derivado¹           |
| `border`        | `rgba(255,255,255,.08)`   | `rgba(0,0,0,.10)`       | site `--line`       |
| `borderStrong`  | `rgba(255,255,255,.18)`   | `rgba(0,0,0,.22)`       | derivado¹           |
| `primary`       | `#FAFAF8`                 | `#0A0A0A`               | site `--white`      |
| `onPrimary`     | `#0A0A0A`                 | `#FAFAF8`               | site `--black`      |
| `textPrimary`   | `#FAFAF8`                 | `#0A0A0A`               | site `--white`      |
| `textSecondary` | `#8A8A8A`                 | `#666666`               | site `--grey`       |
| `textMuted`     | `#5C5C5C`                 | `#888888`               | site `--grey-dim`   |

¹ O site não tem equivalente; o valor espelha a relação que o token tem com
`background` no tema escuro.

Note a inversão de proeminência: no escuro `textSecondary` (`#8A8A8A`) é mais
claro que `textMuted` (`#5C5C5C`); no claro ele é mais **escuro**
(`#666666` contra `#888888`). Em ambos, secundário se destaca mais que
terciário.

## Cores de status

O site não tem cores de status — são do app. As quatro atuais passam AA no
escuro e **as quatro falham no claro**:

| Status        | Valor     | sobre `#0A0A0A` | Valor claro | sobre `#FAFAF8` |
|---------------|-----------|-----------------|-------------|-----------------|
| `available`   | `#22C55E` | 8,69:1 ✓        | `#15803D`   | 4,80:1 ✓        |
| `inUse`       | `#3B82F6` | 5,38:1 ✓        | `#1D4ED8`   | 6,41:1 ✓        |
| `maintenance` | `#F59E0B` | 9,22:1 ✓        | `#B45309`   | 4,81:1 ✓        |
| `missing`     | `#EF4444` | 5,26:1 ✓        | `#B91C1C`   | 6,19:1 ✓        |

Sem os tons próprios, "MANUTENÇÃO" em âmbar no fundo claro fica em **2,06:1**,
menos da metade do mínimo legível.

`live`, `critical`, `warning` e `info` acompanham seus pares semânticos
(`available`, `missing`, `maintenance`, `inUse`).

## Arquitetura

### `AppPalette` — os dados

`lib/core/theme/app_palette.dart`:

```dart
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({ required this.background, ... });

  final Color background;   // superfícies
  final Color backgroundTop;
  final Color surface;
  final Color surfaceAlt;
  final Color surfaceInput;
  final Color border;
  final Color borderStrong;

  final Color primary;      // conteúdo
  final Color onPrimary;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  final Color inUse;        // status
  final Color available;
  final Color maintenance;
  final Color missing;
  final Color live;
  final Color critical;
  final Color warning;
  final Color info;

  static const AppPalette dark = AppPalette(...);
  static const AppPalette light = AppPalette(...);

  @override AppPalette copyWith({...});
  @override AppPalette lerp(ThemeExtension<AppPalette>? other, double t);

  /// Preto sobre acento claro, branco sobre cores de status.
  Color onAccent(Color background);
}
```

`copyWith` e `lerp` são exigidos pela `ThemeExtension`. O `lerp` dá a
transição animada entre temas sem trabalho extra.

### O acesso — a interface

No mesmo arquivo:

```dart
extension AppPaletteContext on BuildContext {
  AppPalette get colors => Theme.of(this).extension<AppPalette>()!;
}
```

Todo call site: `AppColors.surface` → `context.colors.surface`.

O `!` é seguro porque ambos os `ThemeData` registram a extensão; se algum dia
um tema esquecer, quebra alto e imediato em vez de silenciosamente usar cor
errada.

### `AppText` — tipografia sem cor

Os 7 `static const TextStyle` da `AppText` (`label`, `labelStrong`, `value`,
`title`, `cardTitle`, `metric`, `caption`) embutem `color:`. Esse é o ponto
que mais espalha, porque são usados em toda tela.

Eles perdem o `color:` e passam a ser só tipografia (família, tamanho, peso,
espaçamento). A cor vem do `textTheme` do tema, ou explicitamente no call site
quando o papel exige (`.copyWith(color: context.colors.missing)`).

### Os dois temas — uma fábrica só

`AppTheme.dark` e `AppTheme.light` são produzidos por uma única função
privada `_build(AppPalette palette, Brightness brightness)`.

Dois `ThemeData` escritos à mão divergem na primeira manutenção: alguém ajusta
o raio de um botão no escuro e esquece o claro. Com uma fábrica, isso é
impossível — a diferença entre os temas é exatamente a paleta e nada mais.

### `ThemeController` — o modo

`lib/state/theme_controller.dart`, seguindo o padrão já usado em
`PlantController.loadPreferences()`:

```dart
class ThemeController extends ChangeNotifier {
  static const String _prefKey = 'rfid_live_theme_mode';
  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  Future<void> loadPreference();      // lê; ausente ou inválido => system
  Future<void> setMode(ThemeMode m);  // grava e notifica
}
```

Registrado no `MultiProvider` de `app.dart`, ligado a
`MaterialApp.themeMode`, `theme: AppTheme.light`, `darkTheme: AppTheme.dark`.

Aceita injeção como os outros controladores, para os testes.

### O controle — onde o usuário troca

`profile_sheet.dart` já tem um `Switch` para "MODO AO VIVO (RFID)" sob um
título `AppText.labelStrong`. O controle de tema entra logo abaixo, no mesmo
padrão: título "APARÊNCIA" e um `SegmentedButton` de três opções — Sistema,
Claro, Escuro. O `segmentedButtonTheme` já está estilizado nos dois temas, então
a aparência vem de graça.

### Barra de status do sistema

`AppTheme.overlayStyle` é hoje um `SystemUiOverlayStyle` único. Os ícones do
sistema precisam inverter: claros sobre o tema escuro, escuros sobre o claro.
Sem isso, no tema claro ficam ícones brancos em fundo branco.

Passa a existir um por tema, aplicado via `AppBarTheme.systemOverlayStyle` em
cada `ThemeData` — que é o caminho que acompanha a troca de tema sozinho, ao
contrário de uma chamada solta a `SystemChrome`.

## Como o risco é eliminado

São 250 edições mecânicas em 25 arquivos. O perigo não é errar uma — é
**esquecer** uma, deixando cor escura fixa que some no tema claro e que só um
humano olhando tela por tela descobre.

Ao final da migração, **`AppColors` é apagada**. Qualquer referência esquecida
vira erro de compilação. O compilador passa a ser a garantia, no lugar de
inspeção visual.

Isso torna a ordem da implementação obrigatória: criar `AppPalette`, migrar
todos os call sites, e só então apagar `AppColors` — com `flutter analyze`
limpo como critério de conclusão.

## Testes

Além de manter os 53 existentes verdes:

1. **`ThemeController`** — padrão é `system`; `setMode` persiste; valor
   ausente ou corrompido no `SharedPreferences` volta para `system` em vez de
   lançar.
2. **Widget, nos dois temas** — a mesma tela renderizada com
   `ThemeMode.light` e `ThemeMode.dark` produz cores de fundo diferentes, e um
   badge de status usa o tom claro no tema claro.
3. **Contraste (o que protege o trabalho de acessibilidade)** — para cada
   paleta, percorre os status mais `textPrimary` e `textSecondary` e falha
   abaixo de 4,5:1 contra `background`. `textMuted` fica de fora, com o motivo
   escrito no próprio teste (ver Não-objetivos).
4. **Cobertura da paleta** — todo campo de `AppPalette` é diferente entre
   `dark` e `light`, exceto os que devem mesmo coincidir. Pega token esquecido
   na cópia.

Os 53 testes existentes **não referenciam cor alguma** — nem `AppColors`, nem
`AppText`, nem `Color`. Verificado por varredura em `test/`. Eles buscam texto
e semântica, então apagar `AppColors` não os afeta e eles servem de rede de
segurança para a migração: se continuarem verdes, nenhum comportamento mudou.

## Arquivos

**Novos:** `core/theme/app_palette.dart`, `state/theme_controller.dart`,
`test/theme_controller_test.dart`, `test/palette_contrast_test.dart`

**Reescritos:** `core/theme/app_theme.dart`, `app.dart`,
`features/shell/profile_sheet.dart`

**Troca mecânica:** os 25 arquivos que referenciam `AppColors`

**Apagado:** `core/theme/app_colors.dart`
