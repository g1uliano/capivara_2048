import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/utils/age_check.dart';
import '../../domain/auth/auth_service.dart';

const _kEmerald = Color(0xFF2E7D52);
const _months = <String>[
  'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
  'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
];

/// Mostra o modal de data de nascimento. Retorna a data escolhida se o usuário
/// tem 12+ e confirmou; null se cancelou ou foi bloqueado (o próprio modal
/// exibe a mensagem de bloqueio para menores de 12).
Future<DateTime?> showAgeGateDialog(BuildContext context) {
  return showDialog<DateTime>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _AgeGateDialog(),
  );
}

/// Para os fluxos de login: garante que a conta atual tem birthDate. Lê do
/// backend; se ausente, mostra o modal e salva. Retorna false (e faz signOut)
/// se o usuário cancelar ou for menor de 12.
Future<bool> ensureBirthDate(BuildContext context, WidgetRef ref) async {
  final auth = ref.read(authServiceProvider);
  if (await auth.getBirthDate() != null) return true;
  if (!context.mounted) return false;
  final dob = await showAgeGateDialog(context);
  if (dob == null) {
    await auth.signOut();
    return false;
  }
  await auth.saveBirthDate(dob);
  return true;
}

class _AgeGateDialog extends StatefulWidget {
  const _AgeGateDialog();

  @override
  State<_AgeGateDialog> createState() => _AgeGateDialogState();
}

class _AgeGateDialogState extends State<_AgeGateDialog> {
  int? _day;
  int? _month;
  int? _year;
  bool _blocked = false;

  int get _currentYear => DateTime.now().year;

  bool get _complete => _day != null && _month != null && _year != null;

  /// Máximo de dias para a seleção atual. Sem ano definido usa 2000 (bissexto)
  /// para permitir 29 em fevereiro até o ano ser escolhido.
  int get _maxDay {
    final m = _month;
    if (m == null) return 31;
    return daysInMonth(_year ?? 2000, m);
  }

  void _clampDay() {
    if (_day != null && _day! > _maxDay) _day = null;
  }

  void _confirm() {
    if (!_complete) return;
    final birth = DateTime(_year!, _month!, _day!);
    if (!isAtLeast12(birth, DateTime.now())) {
      setState(() => _blocked = true);
      return;
    }
    Navigator.of(context).pop(birth);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: _kEmerald, width: 3),
      ),
      title: Text(
        'Confirmação de idade 🌿',
        style: GoogleFonts.fredoka(
          fontWeight: FontWeight.bold,
          fontSize: 22,
          color: _kEmerald,
        ),
        textAlign: TextAlign.center,
      ),
      content: _blocked ? _buildBlocked() : _buildForm(),
      actionsAlignment: MainAxisAlignment.center,
      actions: _blocked ? _blockedActions() : _formActions(),
    );
  }

  Widget _buildForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Para criar uma conta, informe sua data de nascimento.',
          style: GoogleFonts.nunito(fontSize: 15),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        _menu(
          label: 'Dia',
          value: _day,
          entries: [
            for (var d = 1; d <= _maxDay; d++)
              DropdownMenuEntry(value: d, label: '$d'),
          ],
          search: false,
          onSelected: (v) => setState(() => _day = v),
        ),
        const SizedBox(height: 12),
        _menu(
          label: 'Mês',
          value: _month,
          entries: [
            for (var m = 1; m <= 12; m++)
              DropdownMenuEntry(value: m, label: _months[m - 1]),
          ],
          search: false,
          onSelected: (v) => setState(() {
            _month = v;
            _clampDay();
          }),
        ),
        const SizedBox(height: 12),
        _menu(
          label: 'Ano',
          value: _year,
          entries: [
            for (var y = _currentYear; y >= _currentYear - 110; y--)
              DropdownMenuEntry(value: y, label: '$y'),
          ],
          search: true,
          onSelected: (v) => setState(() {
            _year = v;
            _clampDay();
          }),
        ),
      ],
    );
  }

  Widget _menu({
    required String label,
    required int? value,
    required List<DropdownMenuEntry<int>> entries,
    required bool search,
    required ValueChanged<int?> onSelected,
  }) {
    return DropdownMenu<int>(
      // a chave força o DropdownMenu a refletir mudanças em `value`/entries
      // (ex.: dia limpo ao trocar o mês).
      key: ValueKey('$label-$value-${entries.length}'),
      expandedInsets: EdgeInsets.zero,
      initialSelection: value,
      label: Text(label, style: GoogleFonts.nunito(fontSize: 14)),
      enableFilter: search,
      enableSearch: search,
      requestFocusOnTap: search,
      menuHeight: 280,
      dropdownMenuEntries: entries,
      onSelected: onSelected,
    );
  }

  List<Widget> _formActions() => [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancelar',
              style: GoogleFonts.nunito(fontSize: 16, color: Colors.grey[600])),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _kEmerald,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey[300],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          ),
          onPressed: _complete ? _confirm : null,
          child: Text('Continuar',
              style: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ];

  Widget _buildBlocked() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('🚫', style: TextStyle(fontSize: 40)),
        const SizedBox(height: 12),
        Text(
          'Para criar uma conta você precisa ter pelo menos 12 anos.\n\n'
          'Você pode jogar sem conta normalmente!',
          style: GoogleFonts.nunito(fontSize: 15),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  List<Widget> _blockedActions() => [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _kEmerald,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
          ),
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Entendi',
              style: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ];
}
