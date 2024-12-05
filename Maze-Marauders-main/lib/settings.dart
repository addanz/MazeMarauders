import 'package:flutter/material.dart';
import 'package:flutter_application_2/character.dart';
import 'package:flutter_application_2/main.dart';
import 'game.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'chooseCharacter.dart';

class SettingsScreen extends StatefulWidget {

   SettingsScreen({super.key});
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}
  final AudioPlayer _audioPlayer = AudioPlayer();


@override 
void initState(){
_audioPlayer.setAsset('assets/gameMusic.wav');
}
class _SettingsScreenState extends State<SettingsScreen> {
  // Variables to track switch states
  bool isSoundOn = true;
  bool isMusicOn = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack (
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
              mainAxisAlignment: MainAxisAlignment.center, 
              children: [
            
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center, 
                    children: [
                      Icon(
                        Icons.settings,
                        size: 55,
                        color: Colors.black,
                      ),
                      SizedBox(width: 10),
                      Text(
                        "Settings",
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
               ListTile(
  title: const Text(
    "Music",
    style: TextStyle(
      fontSize: 45,
      color: Colors.black,
    ),
  ),
  trailing: Switch(
    value: isMusicOn,
    onChanged: (value) {
      setState(() {
        isMusicOn = value;
        if (isMusicOn) {
          _audioPlayer.play(); // Start playing music
        } else {
          _audioPlayer.pause(); // Pause music
        }
      });
    },
    activeColor: Colors.white,
    inactiveThumbColor: Colors.black,
    inactiveTrackColor: Colors.black.withOpacity(0.3),
  ),
),
               
                const SizedBox(height: 40), 
                // Back Button
                ElevatedButton(
                  onPressed: () {
 Navigator.push(
    context,
    MaterialPageRoute(builder: (context) =>  MazeMaraudersApp()),
  );                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 49, 48, 48),
                    foregroundColor: const Color.fromARGB(255, 235, 11, 11),
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                  ),
                  child: const Text(
                    "Home",
                    style: TextStyle(fontSize: 20),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) =>  MainApp()),
  );
},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 49, 48, 48),
                    foregroundColor: const Color.fromARGB(255, 235, 11, 11),
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                  ),
                  child: const Text(
                    "Continue",
                    style: TextStyle(fontSize: 20),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const ChooseCharacter()),
  );
},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 49, 48, 48),
                    foregroundColor: const Color.fromARGB(255, 235, 11, 11),
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                  ),
                  child: const Text(
                    "Select Your character",
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
