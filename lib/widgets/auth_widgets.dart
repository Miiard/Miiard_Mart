import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'brand_mark.dart';
import 'reveal.dart';

/// Kerangka halaman login / daftar / lupa password: gelembung pastel, logo, kartu putih.
class AuthScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final VoidCallback? onBack;

  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.onBack,
  });

  Widget _blob(double size, List<Color> colors) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned(
            top: -90,
            right: -70,
            child: Reveal(
              fromScale: 0.7,
              dy: 0,
              duration: const Duration(milliseconds: 1100),
              child: _blob(280, [AppColors.pink, AppColors.lavender]),
            ),
          ),
          Positioned(
            bottom: -110,
            left: -90,
            child: Reveal(
              fromScale: 0.7,
              dy: 0,
              delayMs: 150,
              duration: const Duration(milliseconds: 1100),
              child: _blob(300, [AppColors.mint, AppColors.sky]),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 44,
                    child: onBack == null
                        ? null
                        : Reveal(
                            dy: 0,
                            dx: -12,
                            child: Pressable(
                              scale: 0.88,
                              onTap: onBack,
                              child: Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: Colors.white.o(0.9),
                                  shape: BoxShape.circle,
                                  boxShadow: AppColors.softShadow,
                                ),
                                child: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  size: 19,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 8),
                  Reveal(
                    delayMs: 80,
                    fromScale: 0.85,
                    child: const BrandMark(size: 76),
                  ),
                  const SizedBox(height: 18),
                  Reveal(
                    delayMs: 160,
                    child: Text(title, style: AppText.serif(size: 36, height: 1.05)),
                  ),
                  const SizedBox(height: 6),
                  Reveal(
                    delayMs: 220,
                    child: Text(
                      subtitle,
                      style: AppText.sans(size: 13.5, color: AppColors.inkSoft, height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Reveal(
                    delayMs: 300,
                    dy: 30,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: AppColors.cardShadow,
                      ),
                      child: child,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kolom isian pastel dengan ikon; mendukung tombol lihat/sembunyikan password.
class AuthField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool password;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final void Function(String)? onSubmitted;
  final int? maxLength;
  final TextAlign textAlign;
  final TextStyle? style;

  const AuthField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.password = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onSubmitted,
    this.maxLength,
    this.textAlign = TextAlign.start,
    this.style,
  });

  @override
  State<AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<AuthField> {
  bool _hidden = true;

  OutlineInputBorder _border(Color c, [double w = 1.5]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: c, width: w),
      );

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: widget.password && _hidden,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      validator: widget.validator,
      onFieldSubmitted: widget.onSubmitted,
      maxLength: widget.maxLength,
      textAlign: widget.textAlign,
      autocorrect: false,
      enableSuggestions: !widget.password,
      cursorColor: AppColors.ink,
      style: widget.style ?? AppText.sans(size: 14.5, weight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: widget.label,
        labelStyle: AppText.sans(size: 13.5, color: AppColors.inkSoft),
        counterText: '',
        filled: true,
        fillColor: AppColors.background,
        prefixIcon: Icon(widget.icon, color: AppColors.ink, size: 21),
        suffixIcon: widget.password
            ? IconButton(
                icon: Icon(
                  _hidden ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  color: AppColors.inkSoft,
                  size: 20,
                ),
                onPressed: () => setState(() => _hidden = !_hidden),
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: _border(AppColors.lavender),
        enabledBorder: _border(AppColors.lavender),
        focusedBorder: _border(AppColors.accent, 2),
        errorBorder: _border(AppColors.heart),
        focusedErrorBorder: _border(AppColors.heart, 2),
      ),
    );
  }
}

/// Kotak pesan di atas tombol (error merah muda / info mint) yang muncul dengan animasi.
class AuthNotice extends StatelessWidget {
  final String? message;
  final bool error;
  final IconData? icon;

  const AuthNotice({super.key, required this.message, this.error = true, this.icon});

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: message == null
          ? const SizedBox(width: double.infinity)
          : Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: error ? AppColors.rose : AppColors.mint,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    icon ?? (error ? Icons.error_outline_rounded : Icons.info_outline_rounded),
                    size: 19,
                    color: AppColors.ink,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      message!,
                      style: AppText.sans(size: 12.5, weight: FontWeight.w600, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

/// Tautan teks kecil (Lupa password?, Daftar, dst).
class AuthLink extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const AuthLink({super.key, required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      scale: 0.95,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        child: Text(
          text,
          style: AppText.sans(
            size: 13,
            weight: FontWeight.w800,
            color: AppColors.ink,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }
}
