import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';

/// Marca do aplicativo (logo + nome + assinatura) usada nas telas de acesso.
class AppBrand extends StatelessWidget {
  const AppBrand({super.key, required this.antennasOnline});

  final int antennasOnline;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        // Marca monocromática, no espírito do site da Atlas: disco branco
        // com o ícone em preto e o nome em Alata.
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: context.colors.primary,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.sensors, color: context.colors.onPrimary, size: 28),
        ),
        const SizedBox(height: 18),
        Text(
          'RFID LIVE',
          style: TextStyle(
            fontFamily: AppText.display,
            fontSize: 24,
            letterSpacing: 2.5,
            color: context.colors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Rastreamento de Ferramentas',
          style: TextStyle(
            fontSize: 12,
            letterSpacing: 0.4,
            color: context.colors.textSecondary,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const LiveDot(size: 6),
            const SizedBox(width: 7),
            Text(
              '$antennasOnline antenas online · API conectada',
              style: context.texts.code.copyWith(color: context.colors.textSecondary),
            ),
          ],
        ),
      ],
    );
  }
}

/// Campo de formulário com rótulo em caixa alta acima do input.
class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label.toUpperCase(), style: context.texts.label),
        const SizedBox(height: 7),
        child,
      ],
    );
  }
}

/// Estrutura comum das telas de login e cadastro.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({super.key, required this.children, this.onBack});

  final List<Widget> children;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[context.colors.backgroundTop, context.colors.background],
            stops: <double>[0, 0.55],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: <Widget>[
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        ...children,
                        const SizedBox(height: 28),
                        Text(
                          'TCC RFID 2025 · Sistema Inteligente Industrial',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: AppText.mono,
                            fontSize: 10,
                            letterSpacing: 0.4,
                            color: context.colors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (onBack != null)
                Positioned(
                  left: 4,
                  top: 4,
                  child: IconButton(
                    onPressed: onBack,
                    icon: Icon(Icons.arrow_back,
                        color: context.colors.textSecondary),
                    tooltip: 'Voltar',
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
