import 'package:flutter/material.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/background.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // Centering the column
              children: [
                // Title with Info icon
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center, // Centering the title
                    children: [
                      Icon(
                        Icons.info,
                        size: 55,
                        color: Colors.black,
                      ),
                      SizedBox(width: 10),
                      Text(
                        "Information",
                        style: TextStyle(
                          fontSize: 55,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                // Information text
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    "This game is a maze of mysteries. Navigate through it using your unique abilities. Solve puzzles, avoid obstacles, and reach the end of the maze. Use the controls to interact with the environment and face challenges along the way. The journey won't be easy, but with determination, you can succeed!",
                    style: TextStyle(fontSize: 18, color: Colors.black),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 40), // Increased space after the information
                // Back Button
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Go back to home screen
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 49, 48, 48),
                    foregroundColor: const Color.fromARGB(255, 235, 11, 11),
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                  ),
                  child: const Text(
                    "Back",
                    style: TextStyle(fontSize: 20),
                  ),
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
