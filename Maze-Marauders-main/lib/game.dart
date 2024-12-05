import 'dart:async';

import 'package:flutter/material.dart';
import 'dart:collection';
import 'package:collection/collection.dart';
import 'package:flutter_application_2/character.dart';
import 'package:flutter_application_2/leaderboard.dart';
import 'dart:math';

import 'package:flutter_application_2/settings.dart';
enum SwipeDirection { up, down, left, right }
void main() {

  runApp(MainApp());
}

const int gridRows = 40;
const int gridColumns = 30;
const double cellSize = 20.0;

class MainApp extends StatelessWidget {


  

   const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: GridScreen(),
          
        ),

      ),
    );
  }
}


class GridScreen extends StatefulWidget {

   const GridScreen({super.key });

  @override
  _GridScreenState createState() => _GridScreenState();

  
}



class _GridScreenState extends State<GridScreen> {



  @override
  void initState() {
  super.initState();

  playerX = 10; // Column (X)
  playerY = 38; // Row (Y)
  level = 1;

  playerLife = 50;
  drawAttacks();
  _createInitialWallsAndDoors();
      startGame();

  loadAttacks();

  revealRoom(playerX, playerY); //show the area around the player
}

  int playerX = 10;
  int playerY = 38;
  int level = 0;
  int playerLife = 50;
  Color selectedColor = Colors.transparent; // Color selected uily the user
late GameSession gameSession;
  bool waitingForSwipe = false;
  bool isInAttackMode = false;
  bool waitingFortap = false;
  bool isSelfAttack = false;
  bool isTargetedAttack = false;
  Attack? selectedAttack;

  var castTime = 0;
  // Initialize grid for cell colors
  List<List<Color>> gridColors = List.generate(
    gridRows,
    (row) => List.generate(gridColumns, (col) => Colors.transparent),
  );

  // Initialize grid for walls
  List<List<bool>> walls = List.generate(
    gridRows,
    (row) => List.generate(gridColumns, (col) => false),
  );

  // Initialize grid for doors (true = closed, false = open)
  List<List<bool>> doors = List.generate(
    gridRows,
    (row) => List.generate(gridColumns, (col) => false),
  );

  List<List<bool>> visibility = List.generate(
    gridRows,
    (row) => List.generate(gridColumns, (col) => false),
  );

  Map<Enemy, List<Point>> enemyTargetedAreas = {}; //indicators for enemies

  Map<Point<int>, int> playerIndicatorUsageCount = {}; //for overlapping

  List<Projectile> playerProjectiles = []; //players projectiles

  List<DamageOverTimeEffect> activeDotEffects = []; //all active dot effects

  List<Enemy> enemiesToRemove = [];

  var verticalWallData = <int, List<int>>{};
  var verticalDoorData = <int, List<int>>{};

  List<Attack> allAttacks = [
  // Fire Blade: A sword swipe attack
  Attack(
    name: 'Fire Blade',
    damage: 50,
    castTime: 1, // Instant or quick cast
    colour: 'red',
    swipe: true, // It's a sword swipe
  ),

  // Fireball: A projectile that travels in a direction
  Attack(
    name: 'Fireball',
    damage: 100,
    castTime: 2, // Takes 2 turns to cast
    colour: 'orange',
    projectile: true, // It moves as a projectile
  ),

  // Fire Wall: A targetted, directional attack
  Attack(
    name: 'Fire Wall',
    damage: 80,
    castTime: 3, // Takes 3 turns to prepare
    colour: 'orange',
    directional: true, // You can choose the direction for the wall
    targetted: true, // Targets a spot on the map
    duration: 2,
  ),
];

void loadAttacks(){
  
}
  List<Attack> availableAttacks = []; //the hand

  Map<Point, int> indicatorUsageCount = {}; // Tracks how many attacks use a particular grid cell

  List<Enemy> enemies = []; //list of enemies

  

  List<Offset> aStarPathfinding( //pathfinding for enemies so they dont get stuck on walls
    int startX,
    int startY,
    int targetX,
    int targetY,
    List<List<bool>> walls,
    List<Enemy> enemies,
  ) {
    // PriorityQueue based on fScore (lower values are higher priority)
    final openSet = PriorityQueue<List<int>>((a, b) => a[2].compareTo(b[2]));
    final cameFrom = <Offset, Offset>{};
    final gScore = HashMap<Offset, double>();
    final fScore = HashMap<Offset, double>();

    Offset start = Offset(startX.toDouble(), startY.toDouble());
    Offset target = Offset(targetX.toDouble(), targetY.toDouble());
    openSet.add([startX, startY, 0]); // Initial position and priority
    gScore[start] = 0.0;
    fScore[start] = heuristic(start, target);

    while (openSet.isNotEmpty) {
      final current = openSet.removeFirst();
      final currentOffset = Offset(current[0].toDouble(), current[1].toDouble());

      if (currentOffset == target) {
        return reconstructPath(cameFrom, currentOffset);
      }

      for (final neighbor in getNeighbors(current[0], current[1], walls, enemies)) {
        final tentativeGScore = gScore[currentOffset]! + 1; // Distance between neighbors is 1
        if (tentativeGScore < (gScore[neighbor] ?? double.infinity)) {
          cameFrom[neighbor] = currentOffset;
          gScore[neighbor] = tentativeGScore;
          fScore[neighbor] =
              tentativeGScore + heuristic(neighbor, target);
          openSet.add([
            neighbor.dx.toInt(),
            neighbor.dy.toInt(),
            fScore[neighbor]!.toInt(),
          ]);
        }
      }
    }
    return []; // Return empty if no path found
  }

  double heuristic(Offset a, Offset b) {
    return (a.dx - b.dx).abs() + (a.dy - b.dy).abs();
  }


  List<Offset> getNeighbors(int x, int y, List<List<bool>> walls, List<Enemy> enemies) {
    final directions = [
      const Offset(-1, 0), // Left
      const Offset(1, 0), // Right
      const Offset(0, -1), // Down
      const Offset(0, 1), // Up
    ];
    final neighbors = <Offset>[];

    for (final direction in directions) {
      final newX = x + direction.dx.toInt();
      final newY = y + direction.dy.toInt();

      // Check if the neighbor is within bounds and not blocked by a wall or enemy
      if (newX >= 0 &&
          newY >= 0 &&
          newX < gridColumns &&
          newY < gridRows &&
          !isBlocked(newX, newY, ignorePlayer: true, ignoreEnemies: false)) {
        neighbors.add(Offset(newX.toDouble(), newY.toDouble()));
      }
    }
    return neighbors;
  }

  List<Offset> reconstructPath(Map<Offset, Offset> cameFrom, Offset current) {
    final path = <Offset>[current];
    while (cameFrom.containsKey(current)) {
      current = cameFrom[current]!;
      path.add(current);
    }
    path.removeLast(); // Remove start point
    path.reversed.toList(); // Reverse for path from start to target
    return path.reversed.toList();
  }

  
  void _createInitialWallsAndDoors() {
  // Define wall patterns
    void createVerticalWall(int col, List<int> rows) {
      for (int row in rows) {
        walls[row][col] = true;
      }
    }
  
    void createVerticalDoor(int col, List<int> rows) {
      for (int row in rows) {
        doors[row][col] = true;
      }
    }

    // Define fixed vertical walls
    for (int i = 0; i < gridRows; i++) {
      walls[i][0] = true;
      walls[i][29] = true;
    }

    // Define fixed horizontal walls
    for (int i = 0; i < gridColumns; i++) {
      walls[0][i] = true;
      walls[39][i] = true;
    }

    
    if (level == 1) {
      verticalWallData = {
        1: [7, 12, 17, 24, 30, 35],
        2: [7, 12, 17, 24, 30, 35],
        3: [7, 12, 17, 24, 30, 35],
        4: [7, 12, 13, 14, 16, 17, 30, 35],
        5: [1, 2, 3, 4, 12, 17, 24],
        6: [4, 7, 12, 17, 18, 19, 20, 22, 23, 24, 25, 26, 28, 29, 30, 31, 32, 33, 35],
        7: [4, 5, 6, 7, 9, 10, 11, 12, 17, 24, 29, 35],
        8: [17, 24, 29, 31, 32, 33, 34, 35],
        9: [4, 5, 6, 7, 8, 9, 10, 12, 29, 31, 35, 37, 38],
        10: [4, 10, 12, 17, 24, 29, 31, 35, 37],
        11: [1, 2, 3, 4, 10, 12, 17, 24, 29, 31, 32, 34, 35, 37],
        12: [4, 10, 12, 13, 14, 15, 16, 17, 24, 29, 37],
        13: [4, 12, 17, 24, 29, 31, 32, 33, 34, 35, 36, 37],
        14: [4, 5, 6, 7, 8, 9, 10, 11, 12, 17, 24, 26, 27, 28, 29, 31, 37],
        15: [6, 12, 24, 33, 34, 35, 37],
        16: [6, 12, 17, 24, 26, 27, 28, 29, 30, 31, 32, 33, 35, 37],
        17: [17, 24, 26, 30, 35, 37],
        18: [6, 12, 17, 18, 19, 20, 22, 23, 24, 26, 30, 35, 37],
        19: [1, 2, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 16, 17, 22, 26, 30, 35, 37],
        20: [9, 12, 17, 22, 24, 25, 26, 30, 35, 37],
        21: [9, 12, 16, 17, 30, 35, 37],
        22: [9, 16, 19, 20, 21, 23, 24, 35, 37],
        23: [9, 12, 16, 18, 19, 24, 30, 35, 37],
        24: [5, 6, 7, 8, 9, 10, 11, 12, 18, 24, 30, 35, 37],
        25: [5, 9, 12, 16, 18, 24, 25, 26, 30, 35, 37],
        26: [9, 12, 16, 18, 26, 30, 35, 37],
        27: [5, 9, 16, 18, 26, 27, 28, 29, 30, 31, 32, 34, 35, 37],
        28: [5, 9, 12, 16, 18, 26]
      };

      verticalDoorData = {
        4: [15, 24],
        5: [7,30,35],
        6: [21,27,34],
        7: [8],
        8: [4],
        9: [17,24,36],
        11: [33],
        13: [10],
        14: [25],
        15: [17,31],
        17: [6,12],
        18: [21],
        19: [3,14],
        20: [23],
        22: [12,22,30],
        24: [16],
        26: [5],
        27: [12,33],
      };

      //adds walls
      verticalWallData.forEach(createVerticalWall);
      verticalDoorData.forEach((col, rows) {
        createVerticalDoor(col, rows);
      });
      enemies.clear();
      enemies.addAll([
        Enemy(
          x: 24, y: 31, type: "melee", attackCooldown: 2, life: 25, damage: 15, projectiles: []),
        Enemy(
          x: 20, y: 10, type: "ranged", attackCooldown: 3, life: 15, damage: 10, projectiles: []),
        Enemy(
          x: 5, y: 5, type: "mage", attackCooldown: 4, life: 10, damage: 20, projectiles: [], attackDelay: 1),
      ]);
    }
    // Rebuild the UI
    setState(() {});
  }

  Offset? dragStart; // To store the start position of the drag

  void movePlayer(String direction) {
    setState(() {
      int newX = playerX;
      int newY = playerY;

      switch (direction) {
        case 'up':
          newY--;
          break;
        case 'down':
          newY++;
          break;
        case 'left':
          newX--;
          break;
        case 'right':
          newX++;
          break;
      }

      // Prevent moving into blocked cells
      if (isBlocked(newX, newY)) {
        return;
      }

      // Allow moving through doors and reveal rooms
      if (doors[newY][newX]) {
        doors[newY][newX] = false; // Open the door
        revealRoom(newX, newY);
        updateEnemyVisibility(); //checks for enemies now revealed setting them to revealed
      }

      // Update player position
      playerX = newX;
      playerY = newY;

      // Trigger movement stuff
      moveProjectilesPlayer();
      applyDamageOverTimeEffects();
      enemyTurn();
    });
  }

  bool isBlocked(int x, int y, {bool ignorePlayer = false, bool ignoreEnemies = false}) {
    // Out of bounds check
    if (x < 0 || y < 0 || x >= gridColumns || y >= gridRows) {
      return true;
    }

    // Check for walls
    if (walls[y][x]) {
      return true;
    }

    // Check for doors
    if (doors[y][x]) {
      return false; // Allow passing through doors
    }

    // Check for player (block player's position unless explicitly ignoring the player)
    if (x == playerX && y == playerY && !ignorePlayer) {
      return true; 
    }

    // Check for enemies (unless explicitly ignored)
    if (!ignoreEnemies && enemies.any((enemy) => enemy.x == x && enemy.y == y)) {
      return true; // Block if an enemy occupies the space
    }

    return false;
  }

  void revealRoom(int startX, int startY) {
  // Flood-fill algorithm to reveal the room, but do not reveal the entire map
  final visited = List.generate(
    gridRows,
    (row) => List.generate(gridColumns, (col) => false),
  );

  void floodFill(int x, int y) {
    if (x < 0 || y < 0 || x >= gridColumns || y >= gridRows) return; // Out of bounds
    if (visited[y][x]) return; // Already processed

    visited[y][x] = true; // Mark this cell as visited

    if (walls[y][x]) {
      visibility[y][x] = true; // Reveal walls but stop flood-fill
      return;
    }

    if (doors[y][x]) {
      visibility[y][x] = true; // Reveal doors but stop flood-fill
      return;
    }

    // Mark the current cell as visible
    visibility[y][x] = true;

    // Continue flood-fill to neighbors
    floodFill(x + 1, y); // Right
    floodFill(x - 1, y); // Left
    floodFill(x, y + 1); // Down
    floodFill(x, y - 1); // Up
  }

    floodFill(startX, startY);

    setState(() {}); //resets the ui
  }

  void updateEnemyVisibility() {
    for (var enemy in enemies) { //goes through all enemies
      enemy.isVisible = visibility[enemy.y][enemy.x]; //updates to visible
    }
  }



void startGame(){
 String now = DateTime.now().toString(); // Get current date and time
  GameSession session = GameSession(id: 1, time: 0, date: now);
  

}
void endGame(GameSession session){

  submitGameSession(session);
}
Future<void> submitGameSession(GameSession session) async {
  String now = DateTime.now().toString();
 
 GameSession newSession = GameSession(id: session.id, time: session.time, date: now);

 Leaderboard leaderboard = Leaderboard();
 leaderboard.addGameToLeaderboard(newSession);

  // Save updated leaderboard data back to the JSON file
  await leaderboard.saveToFile('leaderboard.json');

 
  

}

  
  


  void enemyTurn() {
    if (enemies.isNotEmpty == true)
    {
      for (var enemy in enemies) {
        if (!enemy.isVisible) continue; // Skip invisible enemies

        moveProjectiles(enemy); //move projectiles for each enemy
        if (enemy.attackCooldown > 0) {
          enemy.attackCooldown -= 1; //lowers the attack cd
        }
        switch (enemy.type) { //logic depending on type of enemy
          case "melee":
            performMeleeAction(enemy); // melee logic
            break;
          case "ranged":
            performRangedAction(enemy); // ranged logic
            break;
          case "mage":
            performMageAction(enemy); // mage logic
            break;
        }
      }
    }
    else {
      //victory code
      
endGame( gameSession);


      if (level == 1)
      {
        level = 2;
        //more wednesday stuff
        //startup code
      }
    }
  }




  void performMeleeAction(Enemy enemy) {
    if ((enemy.x - playerX).abs() <= 1 && (enemy.y - playerY).abs() <= 1 && enemy.attackCooldown == 0) { //checks that the player is in range and the attack cd is
      highlightTargetedSquaresMelee(); //highlights squares for a second to have a sort of swipe motion
      playerLife -= enemy.damage;
      if (playerLife <= 0) 
        {
          print("game restart");
          //send player to main screen
          resetLevel();
        }
      print("Melee enemy attacks!");
      enemy.attackCooldown = 2; // Reset cooldown

    } else {
      if ((playerX == enemy.x && (playerY == enemy.y + 1 || playerY == enemy.y - 1)) ||
          (playerY == enemy.y && (playerX == enemy.x + 1 || playerX == enemy.x - 1)) ||
          ((playerX == enemy.x + 1 || playerX == enemy.x - 1) && (playerY == enemy.y + 1 || playerY == enemy.y - 1))) {
        // Enemy is adjacent to the player; skip moving
      } else {
        moveTowardPlayer(enemy);//make a move
      }
    }
  }

  void performRangedAction(Enemy enemy) {
    // Ensure the player and enemy are either in the same row (y-axis) or in the same column (x-axis)
    if ((playerX == enemy.x || playerY == enemy.y) && enemy.attackCooldown == 0) {
      // Calculate direction towards the player
      int dx = (playerX - enemy.x).sign.toInt();
      int dy = (playerY - enemy.y).sign.toInt();

      // Offset the projectile's spawn location one step in the direction of the player
      int spawnX = enemy.x + dx;
      int spawnY = enemy.y + dy;

      // Check if the spawn location is blocked (walls, enemies, or player)
      bool isSpawnBlocked = isBlocked(spawnX, spawnY, ignorePlayer: true, ignoreEnemies: false);

      if (!isSpawnBlocked) {
        // Create a new projectile attached to this enemy, moving towards the player
        Projectile projectile = Projectile( x: spawnX, y: spawnY, dx: dx, dy: dy, damage: 10, type: 'enemy');
        enemy.projectiles.add(projectile);

        print("Ranged enemy fires a projectile towards player!");

        // Reset attack cooldown
        enemy.attackCooldown = 3;
      } else {
        print("Projectile spawn location is blocked!");
      }
    } else {
      if  ((playerX == enemy.x && (playerY == enemy.y + 1 || playerY == enemy.y - 1)) ||
          (playerY == enemy.y && (playerX == enemy.x + 1 || playerX == enemy.x - 1)) ||
          ((playerX == enemy.x + 1 || playerX == enemy.x - 1) && (playerY == enemy.y + 1 || playerY == enemy.y - 1))) {
        // Enemy is adjacent to player; skip moving
      } else {
        // Move towards the player
        moveTowardPlayer(enemy);
      }
    }
  }

  void moveProjectiles(Enemy enemy) {
    List<Projectile> projectilesToRemove = [];

    // Clear previous indicators for all projectiles first
    for (var projectile in enemy.projectiles) {
      if (projectile.isActive) {
        Point<int> point = Point(projectile.x, projectile.y);

        // Decrement usage count for the cell
        if (indicatorUsageCount.containsKey(point)) {
          indicatorUsageCount[point] = indicatorUsageCount[point]! - 1;

          // Clear the cell's color if no longer used
          if (indicatorUsageCount[point] == 0) {
            setState(() {
              gridColors[point.y][point.x] = Colors.transparent;
            });
            indicatorUsageCount.remove(point);
          }
        }
      }
    }

    // Update and move each projectile
    for (var projectile in enemy.projectiles) {
      if (!projectile.isActive) {
        projectilesToRemove.add(projectile);
        continue;
      }

      // Move the projectile
      projectile.move();

      // Check if the projectile goes out of bounds
      if (projectile.x < 0 || projectile.x >= gridColumns || projectile.y < 0 || projectile.y >= gridRows) {
        projectile.isActive = false; // Deactivate it if out of bounds
      }

      // Check if the projectile hits the player
      if (projectile.checkCollision(playerX, playerY)) {
        playerLife -= projectile.damage; // Damage the player
        projectile.isActive = false; // Deactivate the projectile
        print("Player hit by projectile! Player life: $playerLife");
        if (playerLife <= 0) 
        {
          //send player to main screen
          resetLevel();
        }
      }

      // Check if the projectile hits a wall
      if (isBlocked(projectile.x, projectile.y, ignoreEnemies: true)) {
        projectile.isActive = false; // Deactivate the projectile if it hits a wall
      }

      // If the projectile is still active, update its position
      if (projectile.isActive) {
        Point<int> point = Point(projectile.x, projectile.y);

        // Increment usage count for the cell
        indicatorUsageCount[point] = (indicatorUsageCount[point] ?? 0) + 1;

        setState(() {
          gridColors[point.y][point.x] = Colors.red.withOpacity(0.7);
        });
      }
    }

    // Remove inactive projectiles from the list
    enemy.projectiles.removeWhere((projectile) => !projectile.isActive);
  }

  //untested we will test properly on wednesday
  void resetLevel() {
    // Clear vertical walls
    verticalWallData.clear();

    // Clear vertical doors
    verticalDoorData.clear();

    // Clear enemies
    //enemies.clear();

    visibility.clear();

    // Reset grid colors (if applicable)
    for (var row in gridColors) {
      for (int i = 0; i < row.length; i++) {
        row[i] = Colors.transparent;
      }
    }

    
    playerX = 10; // Reset player position
    playerY = 38;
    indicatorUsageCount.clear(); // Clear any highlighting indicators

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) =>  MainApp()),
    );
  }

  void performMageAction(Enemy enemy) {
    if (enemy.attackDelay > 0) {
      // Continue preparation
      enemy.attackDelay--;

      if (enemy.attackDelay == 0) {
        // attacks the squares
        print("Mage enemy attacks!");
        
        if (enemyTargetedAreas.containsKey(enemy)) {
          for (Point point in enemyTargetedAreas[enemy]!) {
            if (point.x == playerX && point.y == playerY) {
              playerLife -= enemy.damage;

              if (playerLife <= 0) 
                {
                  //send player to main screen
                  resetLevel();
                }

              print("Player hit by mage attack! Player life: $playerLife");
            }
          }
        }

        // Clear indicators after the attack is executed
        clearTargetedSquares(enemy);

        // Reset cooldown for the next attack
        enemy.attackCooldown = 4;
      }
    } else if (enemy.attackCooldown == 0) {
      // Start preparing for the attack
      print("Mage enemy begins preparing an attack!");

      // Highlight the 3x3 area for the attack preparation
      highlightTargetedSquares(enemy);

      // Set attack delay
      enemy.attackDelay = 2;
    }
  }

  void highlightTargetedSquares(Enemy enemy) {
    enemyTargetedAreas[enemy] = [];

    for (int dx = -1; dx <= 1; dx++) {
      for (int dy = -1; dy <= 1; dy++) {
        int targetX = playerX + dx;
        int targetY = playerY + dy;

        if (isWithinBounds(targetX, targetY)) {
          Point point = Point(targetX, targetY);

          // Keep track of squares targeted by this enemy
          enemyTargetedAreas[enemy]!.add(point);

          // Increment usage count
          indicatorUsageCount[point] = (indicatorUsageCount[point] ?? 0) + 1;

          setState(() { //updates the squares to have the hit indicator
            gridColors[targetY][targetX] = Colors.red.withOpacity(0.7);
          });
        }
      }
    }
  }

  void clearTargetedSquares(Enemy enemy) {
    if (enemyTargetedAreas.containsKey(enemy)) {
      for (Point point in enemyTargetedAreas[enemy]!) {
        if (indicatorUsageCount.containsKey(point)) {
          indicatorUsageCount[point] = indicatorUsageCount[point]! - 1;

          // Clear the indicator if no longer used
          if (indicatorUsageCount[point] == 0) {
            setState(() {
              gridColors[point.y.toInt()][point.x.toInt()] = Colors.transparent;
            });
            indicatorUsageCount.remove(point);
          }
        }
      }

      // Remove the mapping for this enemy
      enemyTargetedAreas.remove(enemy);
    }
  }

  void highlightTargetedSquaresMelee() {
    for (int dx = -1; dx <= 1; dx++) {
      for (int dy = -1; dy <= 1; dy++) {
        int targetX = playerX + dx;
        int targetY = playerY + dy;

        if (isWithinBounds(targetX, targetY)) {
          Point point = Point(targetX, targetY);

          // Increment usage count
          indicatorUsageCount[point] = (indicatorUsageCount[point] ?? 0) + 1;

          // Highlight the square in red
          setState(() {
            gridColors[targetY][targetX] = Colors.red.withOpacity(0.7);
          });

          // Schedule clearing the indicator after a delay
          Future.delayed(const Duration(milliseconds: 500), () {
            clearIndicator(point);
          });
        }
      }
    }
  }
  //usage is very similar to above but doesnt need the enemy to pull it off. useful for melee enemies as their attacks cant be stopped
  void clearIndicator(Point point) {
    // Decrement usage count
    if (indicatorUsageCount.containsKey(point)) {
      indicatorUsageCount[point] = indicatorUsageCount[point]! - 1;

      // Clear the indicator if no longer used
      if (indicatorUsageCount[point] == 0) {
        setState(() {
          gridColors[point.y.toInt()][point.x.toInt()] = Colors.transparent;
        });

        // Remove the point from the usage count
        indicatorUsageCount.remove(point);
      }
    }
  }
  //bounds of the map failsafe
  bool isWithinBounds(int x, int y) {
    return x >= 0 && x < gridColumns && y >= 0 && y < gridRows;
  }
  //moves enemies towards player using a* pathfinding
  void moveTowardPlayer(Enemy enemy) {
    final path = aStarPathfinding(
      enemy.x,
      enemy.y,
      playerX,
      playerY,
      walls,
      enemies,
    );

    if (path.isNotEmpty) {
      final nextStep = path.first;
      enemy.x = nextStep.dx.toInt();
      enemy.y = nextStep.dy.toInt();
    }
  }
  //start of the drag so we know direction
  void handlePanStart(DragStartDetails details) {
    dragStart = details.localPosition;
  }
  //end of the drag so we know direction
  void handlePanEnd(DragEndDetails details) {
    if (dragStart == null) return;

    final dx = details.velocity.pixelsPerSecond.dx;
    final dy = details.velocity.pixelsPerSecond.dy;
    //checks if this is for an attack or movement
    if (isInAttackMode) {
      // Handle swipes for attacks
      if (dx.abs() > dy.abs()) {
        // Horizontal drag
        if (dx > 0) {
          handleSwipe(SwipeDirection.right);
        } else {
          handleSwipe(SwipeDirection.left);
        }
      } else {
        // Vertical drag
        if (dy > 0) {
          handleSwipe(SwipeDirection.down);
        } else {
          handleSwipe(SwipeDirection.up);
        }
      }
    } else {
      // Handle swipes for movement
      if (dx.abs() > dy.abs()) {
        // Horizontal drag
        if (dx > 0) {
          movePlayer('right');
        } else {
          movePlayer('left');
        }
      } else {
        // Vertical drag
        if (dy > 0) {
          movePlayer('down');
        } else {
          movePlayer('up');
        }
      }
    }

    dragStart = null; // Reset drag start for the next gesture
  }
  //yes this isnt ideal for attacks but i needed something quick to get the proof of concept to work
  void handleSwipe(SwipeDirection direction) {
    if (selectedAttack?.name == "Fire Blade") {
      List<Point<int>> affectedCells = [];

      // Determine the starting point for the 3x3 area based on the direction
      switch (direction) {
        case SwipeDirection.up:
          for (int dx = -1; dx <= 1; dx++) {
            for (int dy = -1; dy <= 1; dy++) {
              affectedCells.add(Point(playerX + dx, playerY - 1 + dy));
            }
          }
          break;
        case SwipeDirection.down:
          for (int dx = -1; dx <= 1; dx++) {
            for (int dy = -1; dy <= 1; dy++) {
              affectedCells.add(Point(playerX + dx, playerY + 1 + dy));
            }
          }
          break;
        case SwipeDirection.left:
          for (int dx = -1; dx <= 1; dx++) {
            for (int dy = -1; dy <= 1; dy++) {
              affectedCells.add(Point(playerX - 1 + dx, playerY + dy));
            }
          }
          break;
        case SwipeDirection.right:
          for (int dx = -1; dx <= 1; dx++) {
            for (int dy = -1; dy <= 1; dy++) {
              affectedCells.add(Point(playerX + 1 + dx, playerY + dy));
            }
          }
          break;
      }

      for (var enemy in enemies) {
        for (var cell in affectedCells) {
          if (enemy.x == cell.x && enemy.y == cell.y) {
            enemy.life -= selectedAttack!.damage;
            print("Enemy at (${enemy.x}, ${enemy.y}) hit! Remaining life: ${enemy.life}");

            // Mark enemy for removal if its life reaches zero
            if (enemy.life <= 0) {
              print("Enemy at (${enemy.x}, ${enemy.y}) defeated!");
              enemiesToRemove.add(enemy);
              break; // Exit the loop as the enemy is marked for removal
            }
          }
        }
      }

      // Remove enemies after the iteration will crash if not done this way
      for (var enemy in enemiesToRemove) {
        enemies.remove(enemy);
      }
      enemiesToRemove.clear();


      // Highlight the affected area for the player
      highlightPlayerAttackArea(affectedCells);

      // Clear highlights after a short delay
      Future.delayed(const Duration(milliseconds: 500), () {
        clearPlayerAttackArea(affectedCells);
        setState(() {
          isInAttackMode = false; // Exit attack mode
          waitingForSwipe = false; // No longer waiting for swipe
          selectedAttack = null; // Clear selected attack
        });
      });

      print("Firesword targets the 3x3 area in the $direction direction!");
    }
    if (selectedAttack?.name == "Fireball") {
      // Starting position of the fireball
      int dx = 0, dy = 0;
      int spawnX = playerX, spawnY = playerY; // Player's current position

      // Determine the direction of the fireball based on swipe
      switch (direction) {
        case SwipeDirection.up:
          dy = -1;
          break;
        case SwipeDirection.down:
          dy = 1;
          break;
        case SwipeDirection.left:
          dx = -1;
          break;
        case SwipeDirection.right:
          dx = 1;
          break;
      }

      // Create the fireball projectile
      Projectile fireball = Projectile(
        x: spawnX + dx,
        y: spawnY + dy,
        dx: dx,
        dy: dy,
        damage: selectedAttack!.damage,  // Adjust damage as needed
        type: 'player',  // This projectile is fired by the player
      );

      highlightPlayerAttackArea([Point(fireball.x, fireball.y)]);

      // Add the fireball to the list of player projectiles
      playerProjectiles.add(fireball);

      print("Fireball created at (${fireball.x}, ${fireball.y}) moving $direction direction!");

      // Exit attack mode after the fireball is created
      setState(() {
        isInAttackMode = false;
        waitingForSwipe = false;
        selectedAttack = null;
      });
    }
  }

  void drawAttacks() {
    allAttacks.shuffle();  // Shuffle the deck
    availableAttacks = allAttacks.take(3).toList();  // Draw 3
  }

  void selectAttack(Attack attack) {
    print('Selected Attack: ${attack.name} with damage: ${attack.damage}');
    selectedAttack = attack; // Store the selected attack
    isInAttackMode = true; //so the game knows this movement is for an attack
    castTime = selectedAttack!.castTime;
    while (castTime > 1)
    {
      
      enemyTurn();
      castTime -= 1;
    }
    if (attack.projectile || attack.swipe) { //these 2 function off the same movement so grouped
      print("Swipe to select direction for ${attack.name}");
      setState(() {
        waitingForSwipe = true;
      });
    } else if (attack.self) { //self doesnt care where tapped just needs a tap
      setState(() {
        waitingFortap = true;
        isSelfAttack = true;
      });
      print("Tap anywhere to use ${attack.name} on self.");
    } else if (attack.targetted) { //needs the area that was tapped
      setState(() {
        waitingFortap = true;
        isTargetedAttack = true;
      });
      print("Tap on a grid square to use ${attack.name}.");
    }
    drawAttacks();
    enemyTurn();
  }
  //tap down
  void handleTapDown(TapDownDetails details) {
    if (isInAttackMode) {
      // Handle self-targeted attacks
      if (isSelfAttack) {
        print("Using ${selectedAttack!.name} on self!");

        performSelfAttack(selectedAttack!);
        // Exit attack mode after using self-targeted attack
        setState(() {
          isInAttackMode = false;
          selectedAttack = null;
          isSelfAttack = false; // Reset the flag
        });
      } 
      // Handle targetted attacks
      else if (isTargetedAttack) {
        final gridPosition = getGridPositionFromTap(details.localPosition);
        if (gridPosition != null) {
          performTargettedAttack(selectedAttack!, gridPosition);

          // Exit attack mode after using targetted attack
          setState(() {
            isInAttackMode = false;
            selectedAttack = null;
            isTargetedAttack = false; // Reset the flag
          });
        }
      }
    }
  }
  //we dont have anything this is just proof of concept
  void performSelfAttack(Attack attack) {
    // Apply the effects of the attack to the player
    playerLife += attack.damage; // Example: healing
    print("${attack.name} applied to self. Player life: $playerLife.");
  }

  void performTargettedAttack(Attack attack, Point<int> position) {
  if (attack.name == "Fire Wall") {
    // Create a 3x3 area centered on the selected position
    List<Point<int>> affectedCells = [];

    for (int dx = -1; dx <= 1; dx++) {
      for (int dy = -1; dy <= 1; dy++) {
        int newX = position.x + dx;
        int newY = position.y + dy;
        
        // Ensure the coordinates are within bounds of the grid
        if (newX >= 0 && newX < gridColumns && newY >= 0 && newY < gridRows) {
          affectedCells.add(Point(newX, newY));
        }
      }
    }

    // Add the DoT effect to each affected cell
    activeDotEffects.add(DamageOverTimeEffect(
      attack: attack,
      position: position,  // The position where the attack was cast
      affectedCells: affectedCells,
      turnsRemaining: attack.duration!,  // The duration of the effect (e.g., 2 turns)
    ));

    // Highlight the affected cells on the grid
    highlightPlayerAttackArea(affectedCells);

    print("${attack.name} activated at ${position.x}, ${position.y}. Affected cells: $affectedCells");
  }
}

  void applyDamageOverTimeEffects() {
    // List to keep track of expired DoT effects
    List<DamageOverTimeEffect> expiredDotEffects = [];

    for (var dotEffect in activeDotEffects) {
      if (dotEffect.turnsRemaining <= 0) {
        // If the effect has no turns left, mark it for removal
        expiredDotEffects.add(dotEffect);

        // Remove the affected cells' indicators after the DoT effect expires
        for (var cell in dotEffect.affectedCells) {
          // Check if there are still other active effects using this cell
          if (playerIndicatorUsageCount.containsKey(cell)) {
            // Only clear the indicator if no other effects are using this cell
            playerIndicatorUsageCount[cell] = playerIndicatorUsageCount[cell]! - 1;

            // Clear the visual indicator only if this is the last effect
            if (playerIndicatorUsageCount[cell] == 0) {
              setState(() {
                gridColors[cell.y][cell.x] = Colors.transparent; // Clear the visual indicator
              });
              playerIndicatorUsageCount.remove(cell);
            }
          }
        }

        continue; // Skip applying damage if the effect is expired
      }
      enemiesToRemove.clear();
      // Apply damage to enemies in the affected cells
      for (var cell in dotEffect.affectedCells) {
        for (var enemy in enemies) {
          if (enemy.x == cell.x && enemy.y == cell.y) {
            // Apply damage over time if an enemy is in the affected cell
            enemy.life -= dotEffect.attack.damage;
            print("Enemy at (${enemy.x}, ${enemy.y}) hit! Remaining life: ${enemy.life}");

            // Mark enemy for removal if its life reaches zero
            if (enemy.life <= 0) {
              print("Enemy at (${enemy.x}, ${enemy.y}) defeated!");
              enemiesToRemove.add(enemy);
              break; // Exit the loop as the enemy is marked for removal
            }
          }
        }
      }

      for (var enemy in enemiesToRemove) {
        enemies.remove(enemy);
      }

      // Decrement turnsRemaining for the DoT effect
      dotEffect.turnsRemaining--;
    }

    // Remove expired DoT effects from the active list
    activeDotEffects.removeWhere((effect) => expiredDotEffects.contains(effect));
  }

  Point<int>? getGridPositionFromTap(Offset localPosition) {
    final gridX = (localPosition.dx / cellSize).floor();
    final gridY = (localPosition.dy / cellSize).floor();

    // Fix for the Y-axis being 1 cell too low sometimes
    if (localPosition.dy % cellSize == 0) {
      // If it's perfectly aligned on the grid boundary, adjust the Y position
      return Point(gridX, gridY);
    } else if (localPosition.dy < gridY * cellSize) {
      // Adjust Y position up if the tap is just above the calculated cell
      return Point(gridX, gridY - 1);
    } else {
      // Otherwise return the calculated position
      return Point(gridX, gridY);
    }
  }

  void highlightPlayerAttackArea(List<Point<int>> cells) {
    for (var cell in cells) {
      if (cell.x >= 0 && cell.x < gridColumns && cell.y >= 0 && cell.y < gridRows) {
        Point<int> point = Point(cell.x, cell.y);

        // Increment usage count for the cell
        playerIndicatorUsageCount[point] = (playerIndicatorUsageCount[point] ?? 0) + 1;

        // Update grid color for highlighting the attack area
        setState(() {
          gridColors[cell.y][cell.x] = Colors.green.withOpacity(0.7);
        });
      }
    }
  }

  void clearPlayerAttackArea(List<Point<int>> cells) {
    for (var cell in cells) {
      if (cell.x >= 0 && cell.x < gridColumns && cell.y >= 0 && cell.y < gridRows) {
        Point<int> point = Point(cell.x, cell.y);

        // Decrement usage count for the cell
        if (playerIndicatorUsageCount.containsKey(point)) {
          playerIndicatorUsageCount[point] = playerIndicatorUsageCount[point]! - 1;

          // Only clear the indicator if no other attack is using the cell
          if (playerIndicatorUsageCount[point] == 0) {
            setState(() {
              gridColors[cell.y][cell.x] = Colors.transparent; // Clear the indicator for the cell
            });
            playerIndicatorUsageCount.remove(point); // Remove the cell from the usage count
          }
        }
      }
    }
  }

  void clearAllPlayerAttackHighlights() {
    List<Point<int>> points = playerIndicatorUsageCount.keys.toList();
    for (var point in points) {
      clearPlayerAttackArea([point]);
    }
  }

  void moveProjectilesPlayer() {
    List<Projectile> projectilesToRemove = [];

    // Clear previous indicators for all projectiles first
    setState(() {
      for (var projectile in playerProjectiles) {
        if (projectile.isActive) {
          gridColors[projectile.y][projectile.x] = Colors.transparent; // Clear previous positions
        }
      }
    });
    

    // Update and move each projectile
    for (var projectile in playerProjectiles) {
      if (!projectile.isActive) {
        projectilesToRemove.add(projectile);
        continue;
      }

      // Move the projectile
      projectile.move();

      // Check if the projectile goes out of bounds
      if (projectile.x < 0 || projectile.x >= gridColumns || projectile.y < 0 || projectile.y >= gridRows) {
        projectile.isActive = false; // Deactivate if out of bounds
      }

      // Check if the projectile hits a wall
      if (isBlocked(projectile.x, projectile.y, ignoreEnemies: true)) {
        projectile.isActive = false; // Deactivate if it hits a wall
      }
      // now check for enemies
      else if (isBlocked(projectile.x, projectile.y, ignoreEnemies: false)) {
        var enemy = enemies.firstWhere((e) => e.x == projectile.x && e.y == projectile.y);

        // Apply damage to the enemy
        enemy.life -= projectile.damage;
        print("Enemy hit by fireball! Enemy's remaining health: ${enemy.life}");
        // Mark enemy for removal if its life reaches zero
        if (enemy.life <= 0) {
          print("Enemy at (${enemy.x}, ${enemy.y}) defeated!");
          enemiesToRemove.add(enemy);
          break; // Exit the loop as the enemy is marked for removal
        }

        for (var enemy in enemiesToRemove) {
          enemies.remove(enemy);
        }

        projectile.isActive = false; // Deactivate after hitting an enemy
      }

      // If the projectile is still active, update its position on the grid
      if (projectile.isActive) {
        setState(() {
          gridColors[projectile.y][projectile.x] = Colors.green.withOpacity(0.7); // Color for fireball
        });
      }
    }

    // Remove inactive projectiles
    playerProjectiles.removeWhere((projectile) => !projectile.isActive);
  }

  Widget buildGrid() {
    return GestureDetector(
      onPanStart: handlePanStart,
      onPanEnd: handlePanEnd,
      onTapDown: handleTapDown,
      child: Center(
        child: SizedBox(
          width: cellSize * gridColumns,
          height: cellSize * gridRows,
          child: CustomPaint(
            painter: GridPainter(playerX, playerY, gridColors, walls, doors, visibility, enemies), //paints the cells
          ),
        ),
      ),
    );
  }
  
  Widget buildCard(Attack attack) {
    // Convert the color name to a Flutter Color
    Color cardColor = getColorFromString(attack.colour);

    return GestureDetector(
      onTap: () => selectAttack(attack),
      child: Card(
        color: cardColor, // Apply the dynamic color
        child: SizedBox(
          width: 100,
          height: 150,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  attack.name,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  "${attack.damage} Damage",
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 8),
                // add how the cards work later
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper function to convert color name to Color
  Color getColorFromString(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'red':
        return Colors.red;
      case 'orange':
        return Colors.orange;
      case 'yellow':
        return Colors.yellow;
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'purple':
        return Colors.purple;
      // Add more colors if needed
      default:
        return Colors.grey; // Default to grey if no match
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dungeon Marauders")),
      body: Column(
        children: [
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
                        "Settings",
                        style: TextStyle(fontSize: 20), 
                      ),
                    ),

       
          Expanded(
            flex: 6, //4 makes it look smooth 5 makes it look blocky
            child: buildGrid(), // Your grid here
          ),
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.grey,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: availableAttacks.map((attack) => buildCard(attack)).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  final int playerX;
  final int playerY;
  final List<List<Color>> gridColors;
  final List<List<bool>> walls;
  final List<List<bool>> doors;
  final List<List<bool>> visibility;
  final List<Enemy> enemies; 


  GridPainter(this.playerX, this.playerY, this.gridColors, this.walls, this.doors, this.visibility, this.enemies );

  @override
  void paint(Canvas canvas, Size size) {
    final cellPaint = Paint();

    for (int row = 0; row < gridRows; row++) {
      for (int col = 0; col < gridColumns; col++) {
        if (!visibility[row][col]) {
          // Draw dark gray for hidden cells
          cellPaint.color = Colors.grey[800]!;
          final rect = Rect.fromLTWH(
            col * cellSize,
            row * cellSize,
            cellSize,
            cellSize,
          );
          canvas.drawRect(rect, cellPaint);
          continue; // Skip further processing for hidden cells
        }

        if (walls[row][col]) {
          cellPaint.color = Colors.black;
        } else if (doors[row][col]) {
          cellPaint.color = Colors.brown;
        } else if (gridColors[row][col] != Colors.transparent) {
          cellPaint.color = gridColors[row][col];
        } else {
          cellPaint.color = Colors.white;
        }

        final rect = Rect.fromLTWH(
          col * cellSize,
          row * cellSize,
          cellSize,
          cellSize,
        );

        canvas.drawRect(rect, cellPaint);

        // Draw enemies if they are visible
        for (var enemy in enemies) {
          if (visibility[enemy.y][enemy.x]) {
            final enemyPaint = Paint()
              ..color = enemy.type == "melee"
                  ? Colors.red
                  : enemy.type == "ranged"
                      ? Colors.orange
                      : Colors.blue;

            final enemyRect = Rect.fromLTWH(
              enemy.x * cellSize,
              enemy.y * cellSize,
              cellSize,
              cellSize,
            );
            canvas.drawRect(enemyRect, enemyPaint);
          }
        }
      }
    }




    // Draw player
    final playerPaint = Paint()..color = Colors.purple;
    final playerRect = Rect.fromLTWH(
      playerX * cellSize,
      playerY * cellSize,
      cellSize,
      cellSize,
    );
    canvas.drawRect(playerRect, playerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
Color getColorFromString(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'red':
        return Colors.red;
      case 'orange':
        return Colors.orange;
      case 'yellow':
        return Colors.yellow;
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'purple':
        return Colors.purple;
      // Add more colors if needed
      default:
        return Colors.grey; // Default to grey if no match
    }
  }

class Enemy {
  int x, y;
  String type; // "melee", "ranged", "mage"
  int attackCooldown; // Tracks turns until the enemy can attack
  int attackDelay; // Specific to "mage", for delayed damage
  bool isVisible = false; // Updated based on player visibility
  int life;
  int damage;
  List<Projectile> projectiles; // List of projectiles fired by the enemy

  // Updated constructor
  Enemy({
    required this.x,
    required this.y,
    required this.type,
    required this.attackCooldown,
    required this.life,
    required this.damage,
    this.projectiles = const [],
    this.attackDelay = 0,
    this.isVisible = false,
  });
}

class Projectile {
  int x;
  int y;
  int damage;
  bool isActive;
  int dx;
  int dy;
  String type; // "player" or "enemy"

  // Constructor for the projectile
  Projectile({
    required this.x,
    required this.y,
    required this.dx,
    required this.dy,
    required this.damage,
    required this.type, // "player" or "enemy"
  }) : isActive = true;

  // Method to move the projectile
  void move() {
    x += dx;
    y += dy;
    print("projectile moved to ($x, $y)");
  }

  // Check for collision with the player (for enemy projectiles)
  bool checkCollision(int playerX, int playerY) {
    if (type == 'enemy' && x == playerX && y == playerY) {
      return true;
    }
    return false;
  }

  // Method to check if the projectile hits an enemy (for player projectiles)
  bool checkEnemyHit(List<Enemy> enemies) {
    if (type == 'player') {
      for (var enemy in enemies) {
        if (enemy.x == x && enemy.y == y) {
          return true; // The fireball hits an enemy
        }
      }
    }
    return false;
  }
}

class Attack {
  String name;
  int damage;
  int castTime; // how long for the spell to start doing its effect
  bool directional; // if you can choose a direction for the spell to go
  bool projectile; // projectile movement
  bool self; // targets self (buffs)
  bool swipe; // sword abilities
  bool targetted; // select a spot on the map
  String colour;
  int? duration; // How many turns the effect will last

  Attack({
    required this.name,
    required this.damage,
    required this.castTime,
    required this.colour,
    this.directional = false,
    this.projectile = false,
    this.self = false,
    this.swipe = false,
    this.targetted = false,
    this.duration,        // Optional duration for DoT
  });
}


class DamageOverTimeEffect {
  Attack attack; // The attack that applies the DoT
  Point<int> position; // Position where the DoT is applied
  List<Point<int>> affectedCells; // The 3x3 area for the firewall or other area effects
  int turnsRemaining; // How many turns the DoT will last

  DamageOverTimeEffect({
    required this.attack,
    required this.position,
    required this.affectedCells,
    required this.turnsRemaining,
  });
}