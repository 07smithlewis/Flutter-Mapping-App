import 'package:flutter/material.dart';
import 'package:mapping_app/canvas.dart';
import 'dart:math';
import 'dart:convert';


// Creates an n x m tiled map at a position on the Canvas widget 
class MapTiles extends StatefulWidget {

  final map;

  MapTiles({this.map});

  @override
  _MapTilesState createState() => _MapTilesState(metadata: json.decode(map[11]));
}

class _MapTilesState extends State<MapTiles> {

  final metadata;
  _MapTilesState({this.metadata});

  num clip(num number, num lowerLimit, num upperLimit) {
    return min(upperLimit, max(lowerLimit, number));
  }

  List<List<int>> tileRange = [[0, 0], [0, 0]];

  @override
  Widget build(BuildContext context) {

    final canvas = context.dependOnInheritedWidgetOfExactType<InheritedCanvas>();
    
    if(canvas.normalisedZoom > widget.map[6] && canvas.normalisedZoom < widget.map[7]) {
      
      double width = widget.map[8] * canvas.zoom;
      
      double realWidth = metadata["extent"][2];
      double realHeight = -metadata["extent"][1];
      List<int> zoomBounds = [int.parse(metadata["minzoom"]), int.parse(metadata["maxzoom"])];

      // Zoom conversion
      double virtualPixelsPerPixel = realWidth / width;
      double n = log(virtualPixelsPerPixel) * log2e;
      double tileSize = metadata["tile_matrix"][0]["tile_size"][0] / pow(2.0, n - clip(n.floor(), 0, zoomBounds[1] - zoomBounds[0]));
      int zoom = clip(zoomBounds[1] - n.floor(), zoomBounds[0], zoomBounds[1]);
      List<int> size = [metadata["tile_matrix"][zoom]["matrix_size"][0], metadata["tile_matrix"][zoom]["matrix_size"][1]];
      List<double> position = [widget.map[3], canvas.canvasHeight - widget.map[4]];

      tileRange[0][0] = clip(
        (-(((canvas.width - canvas.canvasWidth * canvas.zoom)/2.0 + canvas.coordinates[0] + position[0] * canvas.zoom + canvas.significantDistance)/tileSize)).floor(),
        0,
        size[0]
      );
      tileRange[0][1] = clip(
        (-(((canvas.height - canvas.canvasHeight * canvas.zoom)/2.0 + canvas.coordinates[1] + position[1] * canvas.zoom + canvas.significantDistance)/tileSize)).floor(),
        0,
        size[1]
      );
      tileRange[1][0] = clip(
        (((canvas.width + canvas.canvasWidth * canvas.zoom)/2.0 - canvas.coordinates[0] - position[0] * canvas.zoom + canvas.significantDistance)/tileSize).ceil(),
        0,
        size[0] - tileRange[0][0]
      );
      tileRange[1][1] = clip(
        (((canvas.height + canvas.canvasHeight * canvas.zoom)/2.0 - canvas.coordinates[1] - position[1] * canvas.zoom + canvas.significantDistance)/tileSize).ceil(),
        0,
        size[1] - tileRange[0][1]
      );

      final List<double> croppedSize = [
        tileRange[1][0] * tileSize,
        tileRange[1][1] * tileSize
      ];
      
      return Stack(
        children: <Widget>[Positioned(
          left: position[0] * canvas.zoom,
          top: position[1] * canvas.zoom,
          width: width,
          height: width * realHeight / realWidth,
          child: Stack(children: [Positioned(
            left: tileRange[0][0] * tileSize,
            top: tileRange[0][1] * tileSize,
            child: Container(
              width: croppedSize[0],
              height: croppedSize[1],
              child: Row(
                children: List<Widget>.generate(tileRange[1][0], (i) => Expanded(child: Column(
                  children: List<Widget>.generate(tileRange[1][1], (j) => Expanded(child: Stack(children: <Widget>[    
                    Image.network(
                      "${widget.map[10]}$zoom/${tileRange[0][1] + j}/${tileRange[0][0] + i}.${metadata["format"]}",
                      width: tileSize,
                      height: tileSize,
                      fit: BoxFit.fill,
                    ),
                  ],))),
                ))),
              ),
            ),
          )])
        ),],
      );
    }else{
      return Container();
    }
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
    
    double width = widget.map[8] * canvas.zoom;
    double height = widget.map[9] * canvas.zoom;
    List<double> position = [widget.map[3], canvas.canvasHeight - widget.map[4]];
    
    if(canvas.normalisedZoom > widget.map[6] && canvas.normalisedZoom < widget.map[7]
    && (canvas.width - canvas.canvasWidth * canvas.zoom)/2.0 + canvas.coordinates[0] + position[0] * canvas.zoom + width + canvas.significantDistance > 0 
    && (-canvas.width - canvas.canvasWidth * canvas.zoom)/2.0 + canvas.coordinates[0] + position[0] * canvas.zoom - canvas.significantDistance < 0 
    && (canvas.height - canvas.canvasHeight * canvas.zoom)/2.0 + canvas.coordinates[1] + position[1] * canvas.zoom + height + canvas.significantDistance > 0 
    && (-canvas.height - canvas.canvasHeight * canvas.zoom)/2.0 + canvas.coordinates[1] + position[1] * canvas.zoom - canvas.significantDistance < 0) {
      return Stack(
        children: <Widget>[Positioned(
          left: position[0] * canvas.zoom,
          top: position[1] * canvas.zoom,
          width: width,
          child: Stack(children: <Widget>[    
            Image.network(
              widget.map[10],
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

class MapPin extends StatefulWidget {

  final pin;
  final pinSize = 20;
  final List<double> maxNameplateSize = [150, 40];

  MapPin({this.pin});

  @override
  _MapPin createState() => _MapPin();
}

class _MapPin extends State<MapPin> {

  int hovering = 0;

  @override
  Widget build(BuildContext context) {

    final canvas = context.dependOnInheritedWidgetOfExactType<InheritedCanvas>();
    final double iconAnchorPoint = 0;

    List<double> position = [widget.pin[2] * canvas.zoom - widget.maxNameplateSize[0] / 2, widget.pin[3] * canvas.zoom - widget.pinSize * iconAnchorPoint];
    List<double> positionScreen = [(canvas.width - canvas.canvasWidth * canvas.zoom) / 2 + canvas.coordinates[0] + position[0],
    (canvas.height - canvas.canvasHeight * canvas.zoom) / 2 - canvas.coordinates[1] + position[1]];

    if(canvas.normalisedZoom > widget.pin[4] && canvas.normalisedZoom < widget.pin[5]
    && positionScreen[0] > -widget.maxNameplateSize[0] - canvas.significantDistance && positionScreen[0] < canvas.width + canvas.significantDistance
    && positionScreen[1] > -widget.maxNameplateSize[1] + widget.pinSize * (1 - iconAnchorPoint) - canvas.significantDistance 
    && positionScreen[1] < canvas.height + widget.pinSize * iconAnchorPoint + canvas.significantDistance) {
      return Stack(
        children: <Widget>[Positioned(
          left: position[0],
          bottom: position[1],
          child: Column(children: [
            Container(
              alignment: Alignment.bottomCenter,
              width: widget.maxNameplateSize[0],
              height: widget.maxNameplateSize[1],
              child: widget.pin[10] ? InkWell(
                onTap: (){
                  canvas.setWindowPinId(widget.pin[0]);
                },
                onHover: (bool _hovering){
                  if((_hovering ? 1 : 0) != hovering) {
                    setState(() {
                      hovering = _hovering ? 1 : 0;
                    });
                  }
                },
                child: Container(
                  
                  decoration: new BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.9 * hovering),
                        blurRadius: 15.0,
                      )
                    ],
                  ),
                  child: Text(
                    widget.pin[1],
                    textAlign: TextAlign.center,
                  )
                ),
              ) : Container()
            ),
            Container(
              width: widget.pinSize.toDouble(),
              height: widget.pinSize.toDouble(),
              decoration: new BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.9 * hovering),
                    blurRadius: 15.0,
                  )
                ],
              ),
              child: InkWell(
                onTap: (){
                  canvas.setWindowPinId(widget.pin[0]);
                },
                onHover: (bool _hovering){
                  if((_hovering ? 1 : 0) != hovering) {
                    setState(() {
                      hovering = _hovering ? 1 : 0;
                    });
                  }
                },
                child: Image.network("./Icons/${widget.pin[11]}.png", width: widget.pinSize.toDouble(), height: widget.pinSize.toDouble(),),
              )
            )
          ])
        )],
      );
    }else{
      return Container();
    }
  }
}