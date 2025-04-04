import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:google_fonts/google_fonts.dart';

class LoadingGame extends StatefulWidget {
  const LoadingGame({super.key});

  @override
  State<LoadingGame> createState() => _LoadingGameState();
}

class _LoadingGameState extends State<LoadingGame> {
  bool isPlaying = false;
  bool isGameOver = false;
  int score = 0;
  double characterYPosition = 0;
  bool isJumping = false;
  List<double> obstacleXPositions = [];
  final double characterX = 50.0; // Fixed X position for the character
  final double jumpHeight = 120;  // Reduced from 100.0
  final double gravity = 3;      // Reduced from 9.8
  double yVelocity = 0;
  Timer? gameTimer;
  Timer? obstacleTimer;
  Timer? blinkTimer;
  bool showStartText = true;

  // Add new properties for sprites
  final double characterSize = 40.0;
  final double obstacleSize = 30.0;

  @override
  void initState() {
    super.initState();
    // Start blinking animation for "Start Playing" text
    blinkTimer = Timer.periodic(const Duration(milliseconds: 600), (timer) {
      if (mounted && !isPlaying) {
        setState(() {
          showStartText = !showStartText;
        });
      }
    });
  }

  void startGame() {
    if (isPlaying) return;
    
    setState(() {
      isPlaying = true;
      isGameOver = false;
      score = 0;
      characterYPosition = 0;
      obstacleXPositions = [];
    });

    // Game loop timer
    gameTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (isJumping) {
        setState(() {
          yVelocity += gravity * 0.016; // Time step of 16ms
          characterYPosition += yVelocity;
          
          // Ground collision
          if (characterYPosition >= 0) {
            characterYPosition = 0;
            isJumping = false;
            yVelocity = 0;
          }
        });
      }

      // Move obstacles
      setState(() {
        for (int i = 0; i < obstacleXPositions.length; i++) {
          obstacleXPositions[i] -= 5; // Obstacle speed
        }
        
        // Remove off-screen obstacles
        obstacleXPositions.removeWhere((x) => x < -20);

        // Check collision
        for (double obstacleX in obstacleXPositions) {
          if ((obstacleX - characterX).abs() < 20 && characterYPosition > -30) {
            gameOver();
            return;
          }
        }

        // Update score for passed obstacles
        if (obstacleXPositions.isNotEmpty && obstacleXPositions[0] < characterX) {
          score++;
          obstacleXPositions.removeAt(0);
        }
      });
    });

    // Spawn obstacles
    obstacleTimer = Timer.periodic(const Duration(milliseconds: 2000), (timer) {
      if (mounted && isPlaying) {
        setState(() {
          obstacleXPositions.add(MediaQuery.of(context).size.width);
        });
      }
    });
  }

  void jump() {
    if (!isJumping && isPlaying && !isGameOver) {
      setState(() {
        isJumping = true;
        yVelocity = -2.5; // Reduced from -12.0 for a gentler jump
      });
    }
  }

  void gameOver() {
    setState(() {
      isPlaying = false;
      isGameOver = true;
    });
    gameTimer?.cancel();
    obstacleTimer?.cancel();
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    obstacleTimer?.cancel();
    blinkTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Add this debug print
    print('Attempting to load assets from: assets/game/character.png and assets/game/obstacle.png');
    
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: GestureDetector(
        onTap: isGameOver || !isPlaying ? startGame : jump, // Changed this line
        onTapDown: (_) => isPlaying ? jump() : null, // Added this line for responsive jumping
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            // Score display
            if (isPlaying || isGameOver)
              Positioned(
                top: 10,
                right: 10,
                child: Text(
                  'Score: $score',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            // Debug tap area - remove after testing
            if (!isPlaying)
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: startGame,
                    child: Center(
                      child: Text(
                        isGameOver ? 'Game Over!' : (showStartText ? 'Start Playing' : ''),
                        style: GoogleFonts.pressStart2p(
                          fontSize: 20,
                          color: isGameOver ? Colors.red : Colors.blue,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // Character
            if (isPlaying || isGameOver)
              Positioned(
                left: characterX,
                bottom: 20 - characterYPosition,
                child: Image.asset(
                  'assets/game/character.png',
                  width: characterSize,
                  height: characterSize,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    print('Character asset error details: $error\nStack trace: $stackTrace');
                    return Container(
                      width: characterSize,
                      height: characterSize,
                      color: Colors.blue,
                      child: const Center(
                        child: Text('!', style: TextStyle(color: Colors.white)),
                      ),
                    );
                  },
                ),
              ),

            // Obstacles
            if (isPlaying || isGameOver)
              ...obstacleXPositions.map(
                (xPos) => Positioned(
                  left: xPos,
                  bottom: 20,
                  child: Image.asset(
                    'assets/game/obstacle.png',
                    width: obstacleSize,
                    height: obstacleSize,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      print('Obstacle asset error details: $error\nStack trace: $stackTrace');
                      return Container(
                        width: obstacleSize,
                        height: obstacleSize,
                        color: Colors.red,
                        child: const Center(
                          child: Text('!', style: TextStyle(color: Colors.white)),
                        ),
                      );
                    },
                  ),
                ),
              ),

            // Ground line
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Container(
                height: 2,
                color: Colors.grey[300],
              ),
            ),

            // Start or Game Over text
            if (!isPlaying)
              Center(
                child: Text(
                  isGameOver ? 'Game Over!' : (showStartText ? 'Start Playing' : ''),
                  style: GoogleFonts.pressStart2p(
                    fontSize: 20,
                    color: isGameOver ? Colors.red : Colors.blue,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
