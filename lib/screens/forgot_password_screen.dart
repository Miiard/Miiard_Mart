import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../utils/validators.dart';
import '../widgets/app_toast.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/grad_button.dart';

/// Lupa password dua langkah: (1) masukkan email → kode dikirim, (2) masukkan kode + password baru.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailKey = GlobalKey<FormState>();
  final _resetKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  int _step = 0;
  bool _loading = false;
  String? _error;
  String? _devCode;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _back() {
    if (_step == 1) {
      setState(() {
        _step = 0;
        _error = null;
      });
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go('/login');
    }
  }

  Future<void> _sendCode() async {
    FocusScope.of(context).unfocus();
    if (!_emailKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await context.read<AuthProvider>().requestReset(_email.text);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.ok) {
        _step = 1;
        _devCode = res.devCode;
      } else {
        _error = res.error;
      }
    });
  }

  Future<void> _resetPassword() async {
    FocusScope.of(context).unfocus();
    if (!_resetKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final err = await context
        .read<AuthProvider>()
        .resetPassword(_email.text, _code.text, _password.text);
    if (!mounted) return;
    if (err != null) {
      setState(() {
        _loading = false;
        _error = err;
      });
      return;
    }
    setState(() => _loading = false);
    showAppToast(
      context,
      message: 'Password berhasil diubah',
      subtitle: 'Silakan masuk dengan password baru',
      icon: Icons.lock_open_rounded,
      color: AppColors.mint,
    );
    context.go('/login');
  }

  Widget _stepIndicator() {
    Widget bar(bool on) => Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            height: 5,
            decoration: BoxDecoration(
              color: on ? AppColors.accent : AppColors.lavender,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          bar(true),
          const SizedBox(width: 6),
          bar(_step == 1),
        ],
      ),
    );
  }

  Widget _stepEmail() {
    return Form(
      key: _emailKey,
      child: Column(
        key: const ValueKey('step-email'),
        children: [
          AuthField(
            controller: _email,
            label: 'Email akunmu',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _sendCode(),
            validator: validateEmail,
          ),
          const SizedBox(height: 16),
          AuthNotice(message: _error),
          SizedBox(
            width: double.infinity,
            child: GradButton(
              label: 'Kirim kode',
              icon: Icons.send_rounded,
              loading: _loading,
              onTap: _sendCode,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepReset() {
    return Form(
      key: _resetKey,
      child: Column(
        key: const ValueKey('step-reset'),
        children: [
          AuthNotice(
            message: _devCode == null
                ? 'Jika email terdaftar, kode 6 digit sudah dikirim ke ${_email.text.trim()}.'
                : 'Mode pengembangan: kode kamu $_devCode. (Di produksi, kode hanya dikirim lewat email.)',
            error: false,
            icon: Icons.mark_email_read_outlined,
          ),
          AuthField(
            controller: _code,
            label: 'Kode 6 digit',
            icon: Icons.pin_outlined,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            maxLength: 6,
            style: AppText.sans(size: 20, weight: FontWeight.w800, letterSpacing: 6),
            validator: (v) =>
                RegExp(r'^\d{6}$').hasMatch((v ?? '').trim()) ? null : 'Masukkan 6 digit kode',
          ),
          const SizedBox(height: 14),
          AuthField(
            controller: _password,
            label: 'Password baru',
            icon: Icons.lock_outline_rounded,
            password: true,
            textInputAction: TextInputAction.next,
            validator: validatePassword,
          ),
          const SizedBox(height: 14),
          AuthField(
            controller: _confirm,
            label: 'Ulangi password baru',
            icon: Icons.lock_reset_rounded,
            password: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _resetPassword(),
            validator: (v) => v != _password.text ? 'Password tidak sama' : null,
          ),
          const SizedBox(height: 16),
          AuthNotice(message: _error),
          SizedBox(
            width: double.infinity,
            child: GradButton(
              label: 'Ubah password',
              icon: Icons.check_rounded,
              loading: _loading,
              onTap: _resetPassword,
            ),
          ),
          const SizedBox(height: 6),
          AuthLink(text: 'Kirim ulang kode', onTap: _loading ? () {} : _sendCode),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: _step == 0 ? 'Lupa\npassword?' : 'Buat password\nbaru',
      subtitle: _step == 0
          ? 'Tenang, masukkan emailmu dan kami kirim kode untuk mengatur ulang.'
          : 'Masukkan kode dari email dan pilih password baru yang mudah kamu ingat.',
      onBack: _back,
      child: Column(
        children: [
          _stepIndicator(),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            switchInCurve: Curves.easeOutCubic,
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.08, 0),
                  end: Offset.zero,
                ).animate(anim),
                child: child,
              ),
            ),
            child: _step == 0 ? _stepEmail() : _stepReset(),
          ),
        ],
      ),
    );
  }
}
