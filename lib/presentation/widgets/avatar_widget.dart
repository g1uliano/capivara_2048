import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/player_profile.dart';

/// Mapa de nome do animal para o asset do tile correspondente.
const Map<String, String> kAnimalTileAssets = {
  'Tanajura': 'assets/images/animals/tile/Tanajura.webp',
  'LoboGuara': 'assets/images/animals/tile/LoboGuara.webp',
  'Cururu': 'assets/images/animals/tile/Cururu.webp',
  'Tucano': 'assets/images/animals/tile/Tucano.webp',
  'Sagui': 'assets/images/animals/tile/Sagui.webp',
  'Preguica': 'assets/images/animals/tile/Preguica.webp',
  'MicoLeao': 'assets/images/animals/tile/MicoLeao.webp',
  'Boto': 'assets/images/animals/tile/Boto.webp',
  'Onca': 'assets/images/animals/tile/Onca.webp',
  'Sucuri': 'assets/images/animals/tile/Sucuri.webp',
  'Capivara': 'assets/images/animals/tile/Capivara.webp',
  'PeixeBoi': 'assets/images/animals/tile/PeixeBoi.webp',
  'Jacare': 'assets/images/animals/tile/Jacare.webp',
};

/// Lista ordenada dos animais disponíveis como avatar (ordem do jogo).
const List<String> kAvatarAnimals = [
  'Tanajura',
  'LoboGuara',
  'Cururu',
  'Tucano',
  'Sagui',
  'Preguica',
  'MicoLeao',
  'Boto',
  'Onca',
  'Sucuri',
  'Capivara',
  'PeixeBoi',
  'Jacare',
];

/// Widget de avatar reutilizável.
///
/// Renderiza:
/// - Avatar tile animal (`"tile:NomeAnimal"`) → Image.asset
/// - URL HTTP (Google/Apple) → NetworkImage
/// - null / sem prefixo reconhecido → inicial do displayName sobre fundo verde
/// - profile null → Icons.person_outline sobre fundo verde
class AvatarWidget extends StatelessWidget {
  const AvatarWidget({super.key, required this.radius, this.profile});

  final double radius;
  final PlayerProfile? profile;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = profile?.avatarUrl;

    if (avatarUrl != null && avatarUrl.startsWith('tile:')) {
      final animalName = avatarUrl.substring(5); // remove "tile:"
      final asset = kAnimalTileAssets[animalName];
      if (asset != null) {
        return CircleAvatar(
          radius: radius,
          backgroundColor: AppColors.primary,
          child: ClipOval(
            child: Image.asset(
              asset,
              width: radius * 2,
              height: radius * 2,
              fit: BoxFit.cover,
            ),
          ),
        );
      }
    }

    if (avatarUrl != null && avatarUrl.startsWith('http')) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.primary,
        backgroundImage: NetworkImage(avatarUrl),
      );
    }

    // Inicial ou ícone padrão
    final initial = profile?.displayName.isNotEmpty == true
        ? profile!.displayName[0].toUpperCase()
        : null;

    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primary,
      child: initial != null
          ? Text(
              initial,
              style: TextStyle(
                color: Colors.white,
                fontSize: radius * 0.9,
                fontWeight: FontWeight.bold,
              ),
            )
          : Icon(Icons.person_outline, color: Colors.white, size: radius * 1.2),
    );
  }
}
