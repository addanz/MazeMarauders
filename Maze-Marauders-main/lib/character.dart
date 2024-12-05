import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class Character {
  final String name;
  final String role;
  final String color;
  List<String> abilities;

  Character({required this.name, required this.role, required this.abilities, required this.color});

  // Static method to create a Character from JSON
  static Character fromJson(Map<String, dynamic> json) {
    return Character(
      name: json['name'],
      role: json['role'],
      abilities: List<String>.from(json['abilities']),
      color: json['color']
    );
  }
}

Future<List<Character>> loadCharacters() async {
  // Load JSON file
  final String response = await rootBundle.loadString('assets/characters.json');
  final data = json.decode(response);

  // Parse character list
  return (data['characters'] as List)
      .map((characterJson) => Character.fromJson(characterJson))
      .toList();
}

Future<Character> getCharacter(int index) async {
  List<Character> characters = await loadCharacters();
  if (index >= 0 && index < characters.length) {
    return characters[index];
  } else {
    throw ArgumentError('Index out of bounds');
  }
}