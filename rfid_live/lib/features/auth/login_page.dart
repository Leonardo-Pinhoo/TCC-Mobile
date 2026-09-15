import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/auth_repository.dart';
import '../../state/auth_controller.dart';
import '../../state/plant_controller.dart';
import 'register_page.dart';
import 'widgets/auth_scaffold.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final AuthController auth = context.read<AuthController>();
    final bool ok = await auth.signIn(
      email: _email.text,
      password: _password.text,
    );
    if (!mounted) return;
    if (!ok && auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error!)),
      );
    }
  }

  void _fillDemo() {
    _email.text = AuthRepository.demoEmail;
    _password.text = AuthRepository.demoPassword;
    setState(() {});
  }

  void _forgotPassword() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Recuperação de acesso', style: AppText.cardTitle),
        content: const Text(
          'A redefinição de senha é feita pelo administrador do sistema na '
          'central de ferramentaria.\n\nAcesso de demonstração:\n'
          'admin@rfidlive.com.br / 123456',
          style: AppText.caption,
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AuthController auth = context.watch<AuthController>();
    final int antennas =
        context.select<PlantController, int>((PlantController c) => c.onlineAntennas);

    return AuthScaffold(
      children: <Widget>[
        AppBrand(antennasOnline: antennas),
        const SizedBox(height: 34),
        const Text(
          'Entrar na plataforma',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Acesso restrito — Sistema Industrial v1.0.0',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 26),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              LabeledField(
                label: 'E-mail',
                child: TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const <String>[AutofillHints.email],
                  style: const TextStyle(fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'usuario@empresa.com.br',
                  ),
                  validator: (String? value) {
                    final String v = (value ?? '').trim();
                    if (v.isEmpty) return 'Informe o e-mail corporativo';
                    if (!v.contains('@') || !v.contains('.')) {
                      return 'E-mail inválido';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 18),
              LabeledField(
                label: 'Senha',
                child: TextFormField(
                  controller: _password,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  autofillHints: const <String>[AutofillHints.password],
                  style: const TextStyle(fontSize: 14),
                  onFieldSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 19,
                        color: AppColors.textMuted,
                      ),
                      tooltip: _obscure ? 'Mostrar senha' : 'Ocultar senha',
                    ),
                  ),
                  validator: (String? value) {
                    if ((value ?? '').isEmpty) return 'Informe a senha';
                    if ((value ?? '').length < 6) {
                      return 'A senha deve ter ao menos 6 caracteres';
                    }
                    return null;
                  },
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _forgotPassword,
                  child: const Text('Esqueceu a senha?'),
                ),
              ),
              const SizedBox(height: 6),
              FilledButton(
                onPressed: auth.busy ? null : _submit,
                child: auth.busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Entrar'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Row(
          children: <Widget>[
            const Expanded(child: Divider(color: AppColors.border)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('ou', style: AppText.caption.copyWith(color: AppColors.textMuted)),
            ),
            const Expanded(child: Divider(color: AppColors.border)),
          ],
        ),
        const SizedBox(height: 22),
        OutlinedButton(
          onPressed: auth.busy
              ? null
              : () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const RegisterPage(),
                    ),
                  ),
          child: const Text('Criar nova conta'),
        ),
        const SizedBox(height: 14),
        TextButton.icon(
          onPressed: auth.busy ? null : _fillDemo,
          icon: const Icon(Icons.bolt, size: 16),
          label: const Text('Preencher acesso de demonstração'),
        ),
      ],
    );
  }
}
