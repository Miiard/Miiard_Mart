import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../utils/validators.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/grad_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final err = await context.read<AuthProvider>().login(_email.text, _password.text);
    // bila berhasil, router otomatis memindahkan ke beranda
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
      title: 'Selamat datang\nkembali',
      subtitle: 'Masuk untuk melanjutkan belanja lembut di Miiard.Mart.',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
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
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              validator: (v) => (v == null || v.isEmpty) ? 'Password wajib diisi' : null,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: AuthLink(text: 'Lupa password?', onTap: () => context.push('/forgot')),
            ),
            const SizedBox(height: 4),
            AuthNotice(message: _error),
            SizedBox(
              width: double.infinity,
              child: GradButton(
                label: 'Masuk',
                icon: Icons.login_rounded,
                loading: _loading,
                onTap: _submit,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Belum punya akun? ',
                  style: AppText.sans(size: 13, color: AppColors.inkSoft),
                ),
                AuthLink(text: 'Daftar', onTap: () => context.push('/register')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
