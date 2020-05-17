import 'package:flutter/material.dart';
import 'package:flutter_test_project/canvas.dart';
import 'dart:math';


// Creates an n x m grid at a position on the Canvas widget 
class Grid extends StatelessWidget {
  
  // Width/Height of individual grid tiles
  final int tileSize;

  // [x, y] position of the bottom left corner of the grid on the canvas
  final List<int> position;

  // Size of the grid in tiles
  final List<int> size;

  Grid({this.tileSize, this.position, this.size});

  @override
  Widget build(BuildContext context) {

    final canvas = context.dependOnInheritedWidgetOfExactType<InheritedCanvas>();

    num clip(num number, num lowerLimit, num upperLimit) {
      return min(upperLimit, max(lowerLimit, number));
    }

    final double zoomedTileSize = tileSize * canvas.zoom;
    List<List<int>> tileRange = [[0, 0], [0, 0]];

    tileRange[0][0] = clip(
      (-(((canvas.width - canvas.canvasWidth)/2.0 + canvas.coordinates[0] + position[0] * canvas.zoom)/zoomedTileSize)).floor(),
      0,
      size[0]
    );
    tileRange[0][1] = clip(
      (-(((canvas.height - canvas.canvasHeight)/2.0 - canvas.coordinates[1] + position[1] * canvas.zoom)/zoomedTileSize)).floor(),
      0,
      size[1]
    );
    tileRange[1][0] = clip(
      (((canvas.width + canvas.canvasWidth)/2.0 - canvas.coordinates[0] - position[0] * canvas.zoom)/zoomedTileSize).ceil(),
      0,
      size[0] - tileRange[0][0]
    );
    tileRange[1][1] = clip(
      (((canvas.height + canvas.canvasHeight)/2.0 + canvas.coordinates[1] - position[1] * canvas.zoom)/zoomedTileSize).ceil(),
      0,
      size[1] - tileRange[0][1]
    );

    final List<int> croppedPosition = [
      position[0] + tileRange[0][0] * tileSize,
      position[1] + tileRange[0][1] * tileSize
    ];

    final List<int> croppedSize = [
      tileRange[1][0] * tileSize,
      tileRange[1][1] * tileSize
    ];

    return Stack(
      children: <Widget>[Positioned(
        left: croppedPosition[0] * canvas.zoom,
        bottom: croppedPosition[1] * canvas.zoom,
        width: croppedSize[0] * canvas.zoom,
        height: croppedSize[1] * canvas.zoom,
        child: Row(
          children: List<Widget>.generate(tileRange[1][0], (i) => Expanded(child: Column(
            children: List<Widget>.generate(tileRange[1][1], (j) => Expanded(child: Stack(children: <Widget>[
              Container(
                color: Colors.grey[(100 + i*100 + j*100) % 900],
              ),
              Center(child: Text("${i + j * tileRange[1][0]}"),)
            ],))),
          ))),
        ),
      ),],
    );
  }
}