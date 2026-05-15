// lib/presentation/screens/redeem_code_screen.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/iap_delivery.dart';
import '../../data/models/shop_package.dart';
import '../../data/repositories/gift_code_repository.dart';
import '../widgets/game_background.dart';
import 'onboarding_auth_screen.dart';

class RedeemCodeScreen extends ConsumerStatefulWidget {
  const RedeemCodeScreen({super.key});

  @override
  ConsumerState<RedeemCodeScreen> createState() => _RedeemCodeScreenState();
}

class _RedeemCodeScreenState extends ConsumerState<RedeemCodeScreen> {
  final _controller = TextEditingController();
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _redeem() async {
    final code = _controller.text.trim();
    if (code.isEmpty) {
      setState(() => _error = 'Digite um código antes de continuar.');
      return;
    }
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const OnboardingAuthScreen(showSkip: false),
        ),
      );
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(giftCodeRepositoryProvider);
      final bundle = await repo.redeemCode(code, userId);
      if (!mounted) return;
      setState(() => _loading = false);
      deliverRewardBundle(ref, bundle);
      _showSuccessSheet(bundle);
    } on RedeemException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _messageFor(e.error);
      });
    }
  }

  String _messageFor(RedeemError error) => switch (error) {
        RedeemError.notFound => 'Código não encontrado.',
        RedeemError.alreadyRedeemed => 'Este código já foi utilizado.',
        RedeemError.expired => 'Este código expirou.',
        RedeemError.ownCode =>
          'Você não pode resgatar seu próprio presente.',
        RedeemError.offline => 'Sem conexão. Tente novamente.',
      };

  void _showSuccessSheet(RewardBundle bundle) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Presente recebido! 🎁',
              style: GoogleFonts.fredoka(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3E2723),
              ),
            ),
            const SizedBox(height: 16),
            _BundleRow(bundle: bundle),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context); // close sheet
                  Navigator.pop(context); // back to shop
                },
                child: Text('Ótimo!', style: GoogleFonts.fredoka(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GameBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            'Resgatar Código',
            style: GoogleFonts.fredoka(fontSize: 22, color: Colors.white),
          ),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              TextField(
                controller: _controller,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'Digite o código do presente',
                  errorText: _error,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF2E7D32),
                      width: 2,
                    ),
                  ),
                ),
                style: GoogleFonts.nunito(fontSize: 16),
                onSubmitted: (_) => _redeem(),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loading ? null : _redeem,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Resgatar',
                        style: GoogleFonts.fredoka(fontSize: 18),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BundleRow extends StatelessWidget {
  final RewardBundle bundle;
  const _BundleRow({required this.bundle});

  @override
  Widget build(BuildContext context) {
    final items = [
      if (bundle.lives > 0) '${bundle.lives} vidas',
      if (bundle.bomb3 > 0) '${bundle.bomb3}× Bomba 3',
      if (bundle.bomb2 > 0) '${bundle.bomb2}× Bomba 2',
      if (bundle.undo3 > 0) '${bundle.undo3}× Desfazer 3',
      if (bundle.undo1 > 0) '${bundle.undo1}× Desfazer 1',
    ];
    return Text(
      items.join(' · '),
      style: GoogleFonts.nunito(fontSize: 15, color: Colors.black87),
      textAlign: TextAlign.center,
    );
  }
}
