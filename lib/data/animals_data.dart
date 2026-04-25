import 'package:flutter/material.dart';
import 'models/animal.dart';

const List<Animal> animals = [
  Animal(level: 1,  value: 2,    name: 'Tanajura',           borderColor: Color(0xFFC0392B), assetPath: 'assets/images/animals/tanajura.png'),
  Animal(level: 2,  value: 4,    name: 'Lobo-guará',         borderColor: Color(0xFFE67E22), assetPath: 'assets/images/animals/lobo_guara.png'),
  Animal(level: 3,  value: 8,    name: 'Sapo-cururu',        borderColor: Color(0xFF8D6E63), assetPath: 'assets/images/animals/sapo_cururu.png'),
  Animal(level: 4,  value: 16,   name: 'Tucano',             borderColor: Color(0xFFFFB300), assetPath: 'assets/images/animals/tucano.png'),
  Animal(level: 5,  value: 32,   name: 'Arara-azul',         borderColor: Color(0xFF1E88E5), assetPath: 'assets/images/animals/arara_azul.png'),
  Animal(level: 6,  value: 64,   name: 'Preguiça',           borderColor: Color(0xFFBCAAA4), assetPath: 'assets/images/animals/preguica.png'),
  Animal(level: 7,  value: 128,  name: 'Mico-leão-dourado',  borderColor: Color(0xFFFF8F00), assetPath: 'assets/images/animals/mico_leao_dourado.png'),
  Animal(level: 8,  value: 256,  name: 'Boto-cor-de-rosa',   borderColor: Color(0xFFF48FB1), assetPath: 'assets/images/animals/boto_cor_de_rosa.png'),
  Animal(level: 9,  value: 512,  name: 'Onça-pintada',       borderColor: Color(0xFFFBC02D), assetPath: 'assets/images/animals/onca_pintada.png'),
  Animal(level: 10, value: 1024, name: 'Sucuri',             borderColor: Color(0xFF2E7D32), assetPath: 'assets/images/animals/sucuri.png'),
  Animal(level: 11, value: 2048, name: 'Capivara Lendária',  borderColor: Color(0xFFFFD54F), assetPath: 'assets/images/animals/capivara_lendaria.png'),
];

Animal animalForLevel(int level) =>
    animals.firstWhere((a) => a.level == level);
