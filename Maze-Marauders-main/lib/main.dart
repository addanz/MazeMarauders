import 'package:flutter/material.dart';
import 'package:flutter_application_2/leaderboard.dart';
import 'package:flutter_application_2/leaderboardWidget.dart';
import 'settings.dart';
import 'info.dart'; 

void main() {
  runApp(const MazeMaraudersApp());
}

class MazeMaraudersApp extends StatelessWidget {
  const MazeMaraudersApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MazeMaraudersScreen(),
    );
  }
}

class MazeMaraudersScreen extends StatelessWidget {
  const MazeMaraudersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/background.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Title
                const Text(
                  "Maze Marauders",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Sans-Serif Smallcaps',
                    fontSize: 45,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                // Game Description
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    "This is a maze of mysteries! Navigate using your unique controls and abilities. Open doors, send attacks, defend yourself, and much more. Your goal is to reach the end of the maze. Good luck!",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18), 
                  ),
                ),
                const SizedBox(height: 20),
                // "Hit Start to Play"
                const Text(
                  "Hit Start to Play",
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold), 
                ),
                const SizedBox(height: 20),
                // Maze Image
                Image.asset(
                  "assets/images/maze.webp",
                  width: 500,
                  height: 500,
                  fit: BoxFit.contain,
                ),
                const Spacer(),
                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Info Button with Icon
                    Column(
                      children: [
                        IconButton(
                          onPressed: () {
                            // Navigate to Info screen
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const InfoScreen()),
                            );
                          },
                          icon: const Icon(Icons.info),
                          iconSize: 48, 
                          color: Colors.black,
                        ),
                        const Text(
                          "Info",
                          style: TextStyle(fontSize: 12, color: Colors.black), 
                        ),
                      ],
                    ),
                    // Start Button
                    ElevatedButton(
                      onPressed: () {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) =>  SettingsScreen()),
  );
},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 49, 48, 48),
                        foregroundColor: const Color.fromARGB(255, 235, 11, 11),
                        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20), 
                      ),
                      child: const Text(
                        "Start",
                        style: TextStyle(fontSize: 20), 
                      ),
                    ),
                    // Settings Button with Icon
                    Column(
                      children: [
                        IconButton(
                          onPressed: () {
                            // Navigate to Settings screen
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) =>  SettingsScreen()),
                            );
                          },
                          icon: const Icon(Icons.settings),
                          iconSize: 48, 
                          color: Colors.black,
                        ),
                        const Text(
                          "Settings",
                          style: TextStyle(fontSize: 12, color: Colors.black), 
                        ),
                        IconButton(
                          onPressed: () {
                            // Navigate to Settings screen
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) =>  const Leaderboardwidget()),
                            );
                          },
                                                    icon: const Icon(Icons.balcony),

                          iconSize: 48, 
                          color: Colors.black,
                        ),
                        const Text(
                          "LeaderBoard",
                          style: TextStyle(fontSize: 12, color: Colors.black), 
                        ),
                        
                       
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
