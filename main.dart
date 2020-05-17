import 'package:flutter/material.dart';
import 'canvas.dart';
import 'canvasWidgets.dart';
import 'dbInteraction.dart';

void main() => runApp(MaterialApp(home: Home()));

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Colors.grey[500],
        title: Text("Map"),
        centerTitle: true,
      ),
      body: Canvas(
        canvasWidth: 400,
        canvasHeight: 300,
        child: Grid(
          tileSize: 50,
          position: [100, 50],
          size: [4, 4],
        ),
      ),
    );
  }
}

