import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_application_2/game.dart';

class Leaderboardwidget extends StatefulWidget {
  const Leaderboardwidget({super.key});

  @override
  _LeaderBoardState createState() => _LeaderBoardState();
}

class _LeaderBoardState extends State<Leaderboardwidget> {
  List leaderboard = [];

  @override
  void initState() {
    super.initState();
    loadLeaderboard();
  }

  // Load leaderboard data from local asset file
  Future<void> loadLeaderboard() async {
    final String response = await rootBundle.loadString('assets/leaderboard.json');
    final List<dynamic> data = json.decode(response);
    setState(() {
      leaderboard = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard')),
      body:ListView.builder(
              itemCount: leaderboard.length,
              itemBuilder: (context, index) {
                final leaderboardItem = leaderboard[index];
                return GestureDetector(
                  onTap: () {
                    // Handle leaderboard item selection here
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('ID: ${leaderboardItem['id']}'),
                        content: Column(
                          children: [
                            Text('Time: ${leaderboardItem['time']} seconds'),
                            const SizedBox(height: 10),
                            Text('Date: ${leaderboardItem['date']}'),
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
                            child: const Text('Choose Character'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Card(
                    
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ID: ${leaderboardItem['id']}',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          Text('Time: ${leaderboardItem['time']} seconds'),
                          Text('Date: ${leaderboardItem['date']}'),
                        ],
                      ),
                    
                  ),
                );
              },
            ),
    );
  }
}
