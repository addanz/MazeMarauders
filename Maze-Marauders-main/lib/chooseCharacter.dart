import 'package:flutter/material.dart';
import 'package:flutter_application_2/game.dart';
import 'character.dart'; 
import 'package:flutter/services.dart';
class ChooseCharacter extends StatefulWidget {
  const ChooseCharacter({super.key});

  @override
  _ChooseCharacterState createState() => _ChooseCharacterState();
}



class _ChooseCharacterState extends State<ChooseCharacter> {
  List<Character> characters = [];
  late Future <Character> character;

  @override
  void initState() {
    super.initState();
    loadCharacters().then((loadedCharacters) {
      setState(() {
        characters = loadedCharacters;
      });
    });
  }
@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Characters')),
      body: ListView.builder(
              itemCount: characters.length,
              itemBuilder: (context, index) {
                final character = characters[index];
                return GestureDetector(
                  onTap: () {
                    // Handle character selection here
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(character.name),
                        content: Column(
                          children: [
                            Text('Role: ${character.role}'),
                            const SizedBox(height: 10),
                         
                          ],
                        ),
                        actions: [
                          TextButton(
                              onPressed: () {
 
                                
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => MainApp()),
  );
},
child: const Text('choose Character'), 
                          ),
                        ],
                      ),
                    );
                  },
                  child: Card(
                   
                  
                      child: Column(
                        children: [
                          Text(
                            character.name,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          Text(character.role),
                        ],
                      ),
                    
                  ),
                );
              },
            ),
    );
  }}