import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../utils/validators.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/grad_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;
  String? _error;

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
    setState(() {
      _loading = true;
      _error = null;
    });
    final err = await context
        .read<AuthProvider>()
        .register(_name.text, _email.text, _password.text);
    if (mounted) {
      setState(() {
        _loading = false;
        _error = err;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Buat akun\nbaru',
      subtitle: 'Gratis dan cepat. Simpan favorit dan keranjangmu di satu tempat.',
      onBack: () => context.canPop() ? context.pop() : context.go('/login'),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            AuthField(
              controller: _name,
              label: 'Nama lengkap',
              icon: Icons.person_outline_rounded,
              textInputAction: TextInputAction.next,
              validator: validateName,
            ),
            const SizedBox(height: 14),
            AuthField(
              controller: _email,
              label: 'Email',
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: validateEmail,
            ),
            const SizedBox(height: 14),
            AuthField(
              controller: _password,
              label: 'Password',
              icon: Icons.lock_outline_rounded,
              password: true,
              textInputAction: TextInputAction.next,
              validator: validatePassword,
            ),
            const SizedBox(height: 14),
            AuthField(
              controller: _confirm,
              label: 'Ulangi password',
              icon: Icons.lock_reset_rounded,
              password: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              validator: (v) => v != _password.text ? 'Password tidak sama' : null,
            ),
            const SizedBox(height: 18),
            AuthNotice(message: _error),
            SizedBox(
              width: double.infinity,
              child: GradButton(
                label: 'Daftar',
                icon: Icons.favorite_rounded,
                loading: _loading,
                onTap: _submit,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Sudah punya akun? ',
                  style: AppText.sans(size: 13, color: AppColors.inkSoft),
                ),
                AuthLink(
                  text: 'Masuk',
                  onTap: () => context.canPop() ? context.pop() : context.go('/login'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
