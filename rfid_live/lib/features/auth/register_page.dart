import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../state/auth_controller.dart';
import '../../state/plant_controller.dart';
import 'widgets/auth_scaffold.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  static const List<String> _roles = <String>[
    'Operação',
    'Supervisão',
    'Manutenção',
    'Qualidade',
    'Administrador',
  ];

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirm = TextEditingController();
  String _role = _roles.first;
  bool _obscure = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final AuthController auth = context.read<AuthController>();
    final NavigatorState navigator = Navigator.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    final bool ok = await auth.signUp(
      name: _name.text,
      email: _email.text,
      password: _password.text,
      role: _role,
    );
    if (!mounted) return;
    if (ok) {
      navigator.pop();
    } else if (auth.error != null) {
      messenger.showSnackBar(SnackBar(content: Text(auth.error!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final AuthController auth = context.watch<AuthController>();
    final int antennas =
        context.select<PlantController, int>((PlantController c) => c.onlineAntennas);

    return AuthScaffold(
      onBack: () => Navigator.of(context).pop(),
      children: <Widget>[
        AppBrand(antennasOnline: antennas),
        const SizedBox(height: 30),
        Text(
          'Criar nova conta',
          style: AppText.title.copyWith(fontSize: 22),
        ),
        const SizedBox(height: 6),
        const Text(
          'O cadastro fica vinculado à unidade industrial atual',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              LabeledField(
                label: 'Nome completo',
                child: TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(fontSize: 14),
                  decoration: const InputDecoration(hintText: 'Ex.: Carlos Mendes'),
                  validator: (String? value) {
                    if ((value ?? '').trim().length < 3) {
                      return 'Informe o nome completo';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),
              LabeledField(
                label: 'E-mail',
                child: TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(fontSize: 14),
                  decoration:
                      const InputDecoration(hintText: 'usuario@empresa.com.br'),
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
              const SizedBox(height: 16),
              LabeledField(
                label: 'Função na planta',
                child: DropdownButtonFormField<String>(
                  initialValue: _role,
                  dropdownColor: AppColors.surfaceAlt,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                  icon: const Icon(Icons.expand_more, color: AppColors.textMuted),
                  items: _roles
                      .map((String role) => DropdownMenuItem<String>(
                            value: role,
                            child: Text(role),
                          ))
                      .toList(),
                  onChanged: (String? value) =>
                      setState(() => _role = value ?? _roles.first),
                ),
              ),
              const SizedBox(height: 16),
              LabeledField(
                label: 'Senha',
                child: TextFormField(
                  controller: _password,
                  obscureText: _obscure,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Mínimo de 6 caracteres',
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 19,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                  validator: (String? value) {
                    if ((value ?? '').length < 6) {
                      return 'A senha deve ter ao menos 6 caracteres';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),
              LabeledField(
                label: 'Confirmar senha',
                child: TextFormField(
                  controller: _confirm,
                  obscureText: _obscure,
                  style: const TextStyle(fontSize: 14),
                  decoration: const InputDecoration(hintText: 'Repita a senha'),
                  onFieldSubmitted: (_) => _submit(),
                  validator: (String? value) {
                    if (value != _password.text) {
                      return 'As senhas não conferem';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 26),
              FilledButton(
                onPressed: auth.busy ? null : _submit,
                child: auth.busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.onPrimary,
                        ),
                      )
                    : const Text('Criar conta'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
