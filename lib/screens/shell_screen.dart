import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../widgets/app_header.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/ui_kit.dart';

/// Kerangka utama: header tetap, isi tab, dan navigasi bawah.
class ShellScreen extends StatelessWidget {
  final StatefulNavigationShell shell;
  const ShellScreen({super.key, required this.shell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: false,
      body: PastelBackdrop(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const AppHeader(),
              Expanded(child: shell),
            ],
          ),
        ),
      ),
      bottomNavigationBar: MiiardBottomNav(
        index: shell.currentIndex,
        onTap: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
      ),
    );
  }
}
