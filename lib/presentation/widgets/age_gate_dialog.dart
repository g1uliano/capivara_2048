import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kAgeVerifiedKey = 'age_gate_passed';

/// Returns true if the user may proceed (age >= 12).
/// Persists the result so returning users are not asked again.
Future<bool> showAgeGateIfNeeded(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool(_kAgeVerifiedKey) == true) return true;

  if (!context.mounted) return false;
  final passed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _AgeGateDialog(),
  );

  final ok = passed == true;
  if (ok) await prefs.setBool(_kAgeVerifiedKey, true);
  return ok;
}

class _AgeGateDialog extends StatefulWidget {
  const _AgeGateDialog();

  @override
  State<_AgeGateDialog> createState() => _AgeGateDialogState();
}

class _AgeGateDialogState extends State<_AgeGateDialog> {
  final _controller = TextEditingController();
  String? _error;
  bool _blocked = false;

  int get _currentYear => DateTime.now().year;

  void _confirm() {
    final raw = _controller.text.trim();
    final birth = int.tryParse(raw);

    if (birth == null || birth < 1900 || birth > _currentYear) {
      setState(() => _error = 'Informe um ano válido.');
      return;
    }

    final age = _currentYear - birth;
    if (age < 12) {
      setState(() {
        _blocked = true;
        _error = null;
      });
      return;
    }

    Navigator.of(context).pop(true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFF2E7D52), width: 3),
      ),
      title: Text(
        'Confirmação de idade 🌿',
        style: GoogleFonts.fredoka(
          fontWeight: FontWeight.bold,
          fontSize: 22,
          color: const Color(0xFF2E7D52),
        ),
        textAlign: TextAlign.center,
      ),
      content: _blocked ? _buildBlocked() : _buildForm(),
      actionsAlignment: MainAxisAlignment.center,
      actions: _blocked
          ? [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D52),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 10),
                ),
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Entendi',
                    style: GoogleFonts.fredoka(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ]
          : [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Cancelar',
                    style: GoogleFonts.nunito(
                        fontSize: 16, color: Colors.grey[600])),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D52),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 10),
                ),
                onPressed: _confirm,
                child: Text('Continuar',
                    style: GoogleFonts.fredoka(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
    );
  }

  Widget _buildForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Para criar uma conta, informe seu ano de nascimento.',
          style: GoogleFonts.nunito(fontSize: 15),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _controller,
          keyboardType: TextInputType.number,
          maxLength: 4,
          textAlign: TextAlign.center,
          style: GoogleFonts.fredoka(fontSize: 22),
          decoration: InputDecoration(
            hintText: 'Ex: 1995',
            counterText: '',
            errorText: _error,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          onSubmitted: (_) => _confirm(),
        ),
      ],
    );
  }

  Widget _buildBlocked() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('🚫', style: TextStyle(fontSize: 40)),
        const SizedBox(height: 12),
        Text(
          'Para criar uma conta você precisa ter pelo menos 12 anos.\n\nVocê pode jogar sem conta normalmente!',
          style: GoogleFonts.nunito(fontSize: 15),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
