import 'dart:convert'; // For JSON encoding/decoding
import 'package:flutter/services.dart';

class GameSession {
  final int id;
  final int time;
  final String date;

  GameSession({required this.id, required this.time, required this.date});

  static GameSession fromJson(Map<String, dynamic> json) {
    return GameSession(
      id: json['id'],
      time: json['time'], // Corrected from 'role' to 'time'
      date: json['date'], // Corrected from 'abilities' to 'date'
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'time': time,
      'date': date,
    };
  }
}

class Leaderboard {
  // A list to store game sessions
  List<GameSession> _leaderboard = [];

  // Load the leaderboard from a JSON file
  Future<void> loadLeaderboard() async {
    // Load JSON file
    final String response = await rootBundle.loadString('assets/leaderboard.json');
    final data = json.decode(response);

    // Parse game session list
    _leaderboard = (data['sessions'] as List)
        .map((sessionJson) => GameSession.fromJson(sessionJson))
        .toList();
  }

  // Add a game session to the leaderboard
  void addGameToLeaderboard(GameSession gameSession) {
    // Check if the session already exists based on ID or other criteria (optional)
    if (_leaderboard.any((session) => session.id == gameSession.id)) {
      print("Session with ID ${gameSession.id} already exists.");
      return; // Exit if the session already exists
    }

    // Add the new game session to the leaderboard
    _leaderboard.add(gameSession);


  }

  // Convert leaderboard to JSON format for saving or displaying
  List<Map<String, dynamic>> toJson() {
    return _leaderboard.map((session) => session.toJson()).toList();
  }

  saveToFile(String s) {}
}