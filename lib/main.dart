import 'dart:math';
import 'package:flutter/material.dart';
import 'database_helper.dart';

void main() {
  runApp(AquariumApp());
}

class AquariumApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Virtual Aquarium',
      home: AquariumScreen(),
    );
  }
}

class AquariumScreen extends StatefulWidget {
  @override
  _AquariumScreenState createState() => _AquariumScreenState();
}

class _AquariumScreenState extends State<AquariumScreen> with SingleTickerProviderStateMixin {
  List<Fish> fishList = [];
  Color selectedColor = Colors.blue;
  double selectedSpeed = 1.0;
  late DatabaseHelper dbHelper;

  @override
  void initState() {
    super.initState();
    dbHelper = DatabaseHelper();
    _loadSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Virtual Aquarium')),
      body: Column(
        children: [
          Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 59, 188, 248),
              border: Border.all(color: const Color.fromARGB(255, 1, 93, 253)),
            ),
            child: FishAnimationWidget(fishList: fishList, speed: selectedSpeed),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ElevatedButton(onPressed: _addFish, child: const Text('Add Fish')),
              ElevatedButton(onPressed: _saveSettings, child: const Text('Save Settings')),
            ],
          ),
          Slider(
            value: selectedSpeed,
            min: 0.1,
            max: 3.0,
            onChanged: (value) {
              setState(() {
                selectedSpeed = value;
                // Update all fish speeds
                for (var fish in fishList) {
                  fish.speed = selectedSpeed; // Update speed for each fish
                }
              });
            },
            divisions: 29,
            label: 'Speed: ${selectedSpeed.toStringAsFixed(1)}',
          ),
          ColorPicker(onColorSelected: (color) {
            setState(() {
              selectedColor = color;
            });
          }),
        ],
      ),
    );
  }

  void _addFish() {
    if (fishList.length < 10) {
      setState(() {
        fishList.add(Fish(color: selectedColor.value, speed: selectedSpeed));
      });
    }
  }

  void _saveSettings() async {
    await dbHelper.saveSettings(fishList.length, selectedSpeed, selectedColor.value);
  }

  void _loadSettings() async {
    var settings = await dbHelper.loadSettings();
    if (settings != null) {
      setState(() {
        selectedSpeed = settings['speed'];
        // Load color and fish count similarly
      });
    }
  }
}

class FishAnimationWidget extends StatelessWidget {
  final List<Fish> fishList;
  final double speed;

  const FishAnimationWidget({required this.fishList, required this.speed});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: fishList.map((fish) {
        return AnimatedFish(color: Color(fish.color), speed: fish.speed);
      }).toList(),
    );
  }
}

class AnimatedFish extends StatefulWidget {
  final Color color;
  final double speed;

  const AnimatedFish({required this.color, required this.speed});

  @override
  _AnimatedFishState createState() => _AnimatedFishState();
}

class _AnimatedFishState extends State<AnimatedFish> with TickerProviderStateMixin {
  late AnimationController _controller;
  late double _xPosition;
  late double _yPosition;
  double _dx = 1;
  double _dy = 1;
  final double _fishSize = 20;

  @override
  void initState() {
    super.initState();
    _xPosition = Random().nextDouble() * 280; // 300 - fishSize
    _yPosition = Random().nextDouble() * 280; // 300 - fishSize
    _createAnimationController();
  }

  void _createAnimationController() {
    double effectiveSpeed = widget.speed > 0 ? widget.speed : 0.1; 
    int animationDuration = (1000 ~/ effectiveSpeed).toInt();
    animationDuration = animationDuration < 1 ? 1 : animationDuration; 

    _controller = AnimationController(vsync: this, duration: Duration(milliseconds: animationDuration))
      ..repeat();

    _controller.addListener(() {
      setState(() {
        _xPosition += _dx * effectiveSpeed;
        _yPosition += _dy * effectiveSpeed;

        // Change direction if hitting the walls
        if (_xPosition >= 280 || _xPosition <= 0) {
          _dx = -_dx;
        }
        if (_yPosition >= 280 || _yPosition <= 0) {
          _dy = -_dy;
        }
      });
    });
  }

  @override
  void didUpdateWidget(AnimatedFish oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.speed != widget.speed) {
      _controller.stop();
      _controller.dispose();
      _createAnimationController(); // Recreate the controller with new speed
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _xPosition,
      top: _yPosition,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color,
        ),
        width: _fishSize,
        height: _fishSize,
      ),
    );
  }
}

class Fish {
  int color; // Change to int to store color value
  double speed;

  Fish({required this.color, required this.speed});
}

// Color Picker Widget
class ColorPicker extends StatelessWidget {
  final Function(Color) onColorSelected;

  ColorPicker({required this.onColorSelected});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: Colors.primaries.map((color) {
        return GestureDetector(
          onTap: () => onColorSelected(color),
          child: Container(
            width: 30,
            height: 30,
            color: color,
            margin: EdgeInsets.all(4),
          ),
        );
      }).toList(),
    );
  }
}