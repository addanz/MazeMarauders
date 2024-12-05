import 'dart:convert';
import 'dart:io';

class Attack {
  String name;
  int damage;
  int castTime; 
  String colour;
  bool swipe;
  bool projectile;
  bool directional;
  bool targetted;
  int? duration;

  Attack({
    required this.name,
    required this.damage,
    required this.castTime,
    required this.colour,
    this.swipe = false,
    this.projectile = false,
    this.directional = false,
    this.targetted = false,
    this.duration,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'damage': damage,
      'castTime': castTime,
      'colour': colour,
      'swipe': swipe,
      'projectile': projectile,
      'directional': directional,
      'targetted': targetted,
      'duration': duration ?? null, 
    };
  }

  factory Attack.fromJson(Map<String, dynamic> json) {
    return Attack(
        name: json['name'],
        damage: json['damage'],
        castTime: json['castTime'],
        colour: json['colour'],
        swipe: json['swipe'] ?? false, 
        projectile: json['projectile'] ?? false, 
        directional: json['directional'] ?? false, 
        targetted: json['targetted'] ?? false, 
        duration: json['duration']);
  }
}

Future<List<Attack>> loadAttacksFromFile(String filePath) async {
  final File file = File(filePath);
  
  if (await file.exists()) {
    String jsonString = await file.readAsString();
    
    Map<String, dynamic> jsonMap = jsonDecode(jsonString);
    List<dynamic> jsonList = jsonMap['attacks'];
    
    List<Attack> attacks = jsonList.map((json) => Attack.fromJson(json)).toList();
    
    return attacks;
  } else {
    return [];
  }
}