import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../data/animals_data.dart';
import '../../data/models/animal.dart';
import '../controllers/game_notifier.dart';
import '../widgets/game_background.dart';
import '../widgets/outlined_text.dart';

class CollectionScreen extends ConsumerWidget {
  const CollectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final highest = ref.watch(gameProvider.select((s) => s.maxLevel));

    return GameBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text('Coleção',
              style: GoogleFonts.fredoka(fontSize: 22, color: Colors.white)),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    OutlinedText(
                      text: '$highest/13 animais descobertos',
                      style: GoogleFonts.fredoka(fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: highest / 13.0,
                      color: AppColors.primary,
                      backgroundColor: Colors.grey.shade300,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                padding: const EdgeInsets.all(12),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.85,
                children: [
                  for (final animal in animals)
                    highest >= animal.level
                        ? _UnlockedCard(animal: animal)
                        : _LockedCard(animal: animal),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnlockedCard extends StatelessWidget {
  const _UnlockedCard({required this.animal});
  final Animal animal;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => _AnimalDetailSheet(animal: animal),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: animal.backgroundBaseColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
                color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(animal.tilePngPath, height: 72, fit: BoxFit.contain),
            const SizedBox(height: 8),
            Text(animal.name,
                style: GoogleFonts.fredoka(fontSize: 15),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _LockedCard extends StatelessWidget {
  const _LockedCard({required this.animal});
  final Animal animal;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            animal.tilePngPath,
            height: 72,
            color: Colors.black54,
            colorBlendMode: BlendMode.srcATop,
          ),
          const SizedBox(height: 8),
          Text('???',
              style:
                  GoogleFonts.fredoka(fontSize: 20, color: Colors.black38)),
        ],
      ),
    );
  }
}

class _AnimalDetailSheet extends StatelessWidget {
  const _AnimalDetailSheet({required this.animal});
  final Animal animal;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (context, scrollController) => SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Image.asset(animal.hostPngPath,
                height: 160, fit: BoxFit.contain),
            const SizedBox(height: 16),
            Text(animal.name,
                style: GoogleFonts.fredoka(
                    fontSize: 24, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center),
            if (animal.scientificName != null) ...[
              const SizedBox(height: 4),
              Text(
                animal.scientificName!,
                style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 12),
            Text(animal.funFact ?? '',
                style: GoogleFonts.nunito(fontSize: 16),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
