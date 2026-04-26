import 'package:flutter/material.dart';
import 'models/animal.dart';

const List<Animal> animals = [
  Animal(
    level: 1, value: 2, name: 'Tanajura',
    borderColor: Color(0xFFC0392B),
    backgroundBaseColor: Color(0xFFF5C2BA),
    assetPath: 'assets/images/animals/tile/tanajura.png',
    texturePattern: TexturePattern.dots,
  ),
  Animal(
    level: 2, value: 4, name: 'Lobo-guará',
    borderColor: Color(0xFFE67E22),
    backgroundBaseColor: Color(0xFFFAD3B2),
    assetPath: 'assets/images/animals/tile/lobo_guara.png',
    texturePattern: TexturePattern.dots,
  ),
  Animal(
    level: 3, value: 8, name: 'Sapo-cururu',
    borderColor: Color(0xFF8D6E63),
    backgroundBaseColor: Color(0xFFD7C4BC),
    assetPath: 'assets/images/animals/tile/sapo_cururu.png',
    texturePattern: TexturePattern.diagonal,
  ),
  Animal(
    level: 4, value: 16, name: 'Tucano',
    borderColor: Color(0xFFFFB300),
    backgroundBaseColor: Color(0xFFFFE9A8),
    assetPath: 'assets/images/animals/tile/tucano.png',
    texturePattern: TexturePattern.diagonal,
  ),
  Animal(
    level: 5, value: 32, name: 'Arara-azul',
    borderColor: Color(0xFF1E88E5),
    backgroundBaseColor: Color(0xFFB5D7F4),
    assetPath: 'assets/images/animals/tile/arara_azul.png',
    texturePattern: TexturePattern.grid,
  ),
  Animal(
    level: 6, value: 64, name: 'Preguiça',
    borderColor: Color(0xFFBCAAA4),
    backgroundBaseColor: Color(0xFFE8E0DC),
    assetPath: 'assets/images/animals/tile/preguica.png',
    texturePattern: TexturePattern.grid,
  ),
  Animal(
    level: 7, value: 128, name: 'Mico-leão-dourado',
    borderColor: Color(0xFFFF8F00),
    backgroundBaseColor: Color(0xFFFFD7A1),
    assetPath: 'assets/images/animals/tile/mico_leao_dourado.png',
    texturePattern: TexturePattern.waves,
  ),
  Animal(
    level: 8, value: 256, name: 'Boto-cor-de-rosa',
    borderColor: Color(0xFFF48FB1),
    backgroundBaseColor: Color(0xFFFBD0DD),
    assetPath: 'assets/images/animals/tile/boto_cor_de_rosa.png',
    texturePattern: TexturePattern.waves,
  ),
  Animal(
    level: 9, value: 512, name: 'Onça-pintada',
    borderColor: Color(0xFFFBC02D),
    backgroundBaseColor: Color(0xFFFFEFB0),
    assetPath: 'assets/images/animals/tile/onca_pintada.png',
    texturePattern: TexturePattern.blobs,
  ),
  Animal(
    level: 10, value: 1024, name: 'Sucuri',
    borderColor: Color(0xFF2E7D32),
    backgroundBaseColor: Color(0xFFBFD9C0),
    assetPath: 'assets/images/animals/tile/sucuri.png',
    texturePattern: TexturePattern.scales,
  ),
  Animal(
    level: 11, value: 2048, name: 'Capivara Lendária',
    borderColor: Color(0xFFFFD54F),
    backgroundBaseColor: Color(0xFFFFEFB8),
    assetPath: 'assets/images/animals/tile/capivara_lendaria.png',
    texturePattern: TexturePattern.radial,
  ),
];

Animal animalForLevel(int level) =>
    animals.firstWhere((a) => a.level == level);
