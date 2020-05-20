import 'package:flutter/material.dart';
import 'package:flutter_test_project/canvas.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:math';
import 'dart:convert';


// Creates an n x m tiled map at a position on the Canvas widget 
class MapTiles extends StatefulWidget {

  final map;

  MapTiles({this.map});

  @override
  _MapTilesState createState() => _MapTilesState();
}

class _MapTilesState extends State<MapTiles> {

  @override
  Widget build(BuildContext context) {
    
    var metadata = json.decode(widget.map[8]);

    final canvas = context.dependOnInheritedWidgetOfExactType<InheritedCanvas>();

    num clip(num number, num lowerLimit, num upperLimit) {
      return min(upperLimit, max(lowerLimit, number));
    }
    
    double width = widget.map[5] * canvas.zoom;
    
    int realWidth = metadata["extent"][2];
    List<int> zoomBounds = [int.parse(metadata["minzoom"]), int.parse(metadata["maxzoom"])];

    // Zoom conversion
    double virtualPixelsPerPixel = realWidth / width;
    double n = log(virtualPixelsPerPixel) / log(2);
    double tileSize = metadata["tile_matrix"][0]["tile_size"][0] / pow(2.0, n - clip(n.floor(), 0, zoomBounds[1] - zoomBounds[0]));
    int zoom = clip(zoomBounds[1] - n.floor(), zoomBounds[0], zoomBounds[1]);
    List<int> size = [metadata["tile_matrix"][zoom]["matrix_size"][0], metadata["tile_matrix"][zoom]["matrix_size"][1]];
    List<double> position = [widget.map[3], canvas.canvasHeight - widget.map[4]];

    List<List<int>> tileRange = [[0, 0], [0, 0]];

    tileRange[0][0] = clip(
      (-(((canvas.width - canvas.canvasWidth * canvas.zoom)/2.0 + canvas.coordinates[0] + position[0] * canvas.zoom)/tileSize)).floor(),
      0,
      size[0]
    );
    tileRange[0][1] = clip(
      (-(((canvas.height - canvas.canvasHeight * canvas.zoom)/2.0 + canvas.coordinates[1] + position[1] * canvas.zoom)/tileSize)).floor(),
      0,
      size[1]
    );
    tileRange[1][0] = clip(
      (((canvas.width + canvas.canvasWidth * canvas.zoom)/2.0 - canvas.coordinates[0] - position[0] * canvas.zoom)/tileSize).ceil(),
      0,
      size[0] - tileRange[0][0]
    );
    tileRange[1][1] = clip(
      (((canvas.height + canvas.canvasHeight * canvas.zoom)/2.0 - canvas.coordinates[1] - position[1] * canvas.zoom)/tileSize).ceil(),
      0,
      size[1] - tileRange[0][1]
    );

    final List<double> croppedPosition = [
      position[0] * canvas.zoom + tileRange[0][0] * tileSize,
      position[1] * canvas.zoom + tileRange[0][1] * tileSize
    ];

    final List<double> croppedSize = [
      tileRange[1][0] * tileSize,
      tileRange[1][1] * tileSize
    ];
    
    return Stack(
      children: <Widget>[Positioned(
        left: croppedPosition[0],
        top: croppedPosition[1],
        width: croppedSize[0],
        height: croppedSize[1],
        child: Row(
          children: List<Widget>.generate(tileRange[1][0], (i) => Expanded(child: Column(
            children: List<Widget>.generate(tileRange[1][1], (j) => Expanded(child: Stack(children: <Widget>[
              Container(
                color: Colors.grey[(100 + i*100 + j*100) % 900],
              ),
              
              Image.network(
                "${widget.map[7]}$zoom/${tileRange[0][0] + i}/${tileRange[0][1] + j}.${metadata["format"]}",
                width: tileSize,
                height: tileSize,
                fit: BoxFit.fill,
              ),
            ],))),
          ))),
        ),
      ),],
    );
  }
}

class MapImage extends StatefulWidget {

  final map;

  MapImage({this.map});

  @override
  _MapImage createState() => _MapImage();
}

class _MapImage extends State<MapImage> {

  @override
  Widget build(BuildContext context) {

    final canvas = context.dependOnInheritedWidgetOfExactType<InheritedCanvas>();
    
    double width = widget.map[5] * canvas.zoom;
    double height = widget.map[6] * canvas.zoom;
    List<double> position = [widget.map[3], canvas.canvasHeight - widget.map[4]];
    
    if((canvas.width - canvas.canvasWidth * canvas.zoom)/2.0 + canvas.coordinates[0] + position[0] * canvas.zoom + width > 0 
    && (-canvas.width - canvas.canvasWidth * canvas.zoom)/2.0 + canvas.coordinates[0] + position[0] * canvas.zoom < 0 
    && (canvas.height - canvas.canvasHeight * canvas.zoom)/2.0 + canvas.coordinates[1] + position[1] * canvas.zoom + height > 0 
    && (-canvas.height - canvas.canvasHeight * canvas.zoom)/2.0 + canvas.coordinates[1] + position[1] * canvas.zoom < 0) {
      return Stack(
        children: <Widget>[Positioned(
          left: position[0] * canvas.zoom,
          top: position[1] * canvas.zoom,
          width: width,
          child: Stack(children: <Widget>[
            Container(
              color: Colors.grey[200],
            ),
            
            Image.network(
              widget.map[7],
              width: width,
              height: height,
              fit: BoxFit.fill,
            ),
          ],)
        )],
      );
    }else{
      return Container();
    }
  }
}

class Map extends StatelessWidget {

  final map;
  
  Map({this.map});

  @override
  Widget build(BuildContext context) {
    if(map[2]) {
      return MapTiles(map: map,);
    }else{
      return MapImage(map: map,);
    }
  }
}

