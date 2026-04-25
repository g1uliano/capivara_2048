import 'package:flutter/material.dart';
import 'models/animal.dart';

const List<Animal> animals = [
  Animal(level: 1,  value: 2,    name: 'Tanajura',           tileColor: Color(0xFFC0392B)),
  Animal(level: 2,  value: 4,    name: 'Lobo-guará',         tileColor: Color(0xFFE67E22)),
  Animal(level: 3,  value: 8,    name: 'Sapo-cururu',        tileColor: Color(0xFF8D6E63)),
  Animal(level: 4,  value: 16,   name: 'Tucano',             tileColor: Color(0xFFFFB300)),
  Animal(level: 5,  value: 32,   name: 'Arara-azul',         tileColor: Color(0xFF1E88E5)),
  Animal(level: 6,  value: 64,   name: 'Preguiça',           tileColor: Color(0xFFBCAAA4)),
  Animal(level: 7,  value: 128,  name: 'Mico-leão-dourado',  tileColor: Color(0xFFFF8F00)),
  Animal(level: 8,  value: 256,  name: 'Boto-cor-de-rosa',   tileColor: Color(0xFFF48FB1)),
  Animal(level: 9,  value: 512,  name: 'Onça-pintada',       tileColor: Color(0xFFFBC02D)),
  Animal(level: 10, value: 1024, name: 'Sucuri',             tileColor: Color(0xFF2E7D32)),
  Animal(level: 11, value: 2048, name: 'Capivara Lendária',  tileColor: Color(0xFFFFD54F)),
];

Animal animalForLevel(int level) =>
    animals.firstWhere((a) => a.level == level);
