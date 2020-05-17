import 'package:flutter/material.dart';
import 'package:align_positioned/align_positioned.dart';
import 'dart:math';

// Basic information on the canvas geometry is passed to any children of the canvas
class InheritedCanvas extends InheritedWidget {

  final double width;
  final double height;
  final int canvasWidth;
  final int canvasHeight;
  final double zoom;
  final List<double> coordinates;

  InheritedCanvas({Widget child, this.width, this.height, this.canvasWidth, this.canvasHeight, this.zoom, this.coordinates}) : super(child: child);

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) => true;
}

// A floating 2D canvas, that supports panning and zooming
class Canvas extends StatefulWidget {
  
  // The size of the canvas in pixels at zoom = 1 
  final int canvasWidth;
  final int canvasHeight;

  final Widget child;
  final Color backgroundColor;
  final Color canvasColor;
  final Color buttonColor;

  Canvas({this.canvasWidth, this.canvasHeight, this.child, this.backgroundColor = Colors.white, this.canvasColor = Colors.white, this.buttonColor = Colors.grey});

  @override
  _CanvasState createState() => _CanvasState(canvasWidth: canvasWidth, canvasHeight: canvasHeight, child: child, backgroundColor: backgroundColor, canvasColor: canvasColor, buttonColor: buttonColor);
}

class _CanvasState extends State<Canvas> {

  final int canvasWidth;
  final int canvasHeight;
  final Widget child;
  final Color backgroundColor;
  final Color canvasColor;
  final Color buttonColor;
  _CanvasState({this.canvasWidth, this.canvasHeight, this.child, this.backgroundColor, this.canvasColor, this.buttonColor});

  List<double> coordinates = [0.0, 0.0];
  double zoom = 1.0;
  var zoomBoundaries = RangeValues(0.1, 4);
  var selectedZoom = RangeValues(0.1, 2);

  @override
  Widget build(BuildContext context) {

    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          coordinates[0] += details.delta.dx;
          coordinates[1] += details.delta.dy;
        });
      },
      child: Container(
        color: backgroundColor,
        child: LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
          return Stack(children: <Widget>[
            AlignPositioned(
              alignment: Alignment.center,
              minChildHeight: canvasHeight * zoom,
              maxChildHeight: canvasHeight * zoom,
              minChildWidth: canvasWidth * zoom,
              maxChildWidth: canvasWidth * zoom,
              dx: coordinates[0],
              dy: coordinates[1],
              child: Container(
                child: InheritedCanvas(
                  child: child,
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  canvasWidth: canvasWidth,
                  canvasHeight: canvasHeight,
                  zoom: zoom,
                  coordinates: coordinates,
                ),
                decoration: BoxDecoration(
                  color: canvasColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 5,
                      blurRadius: 7,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Container(
                    width: 40,
                    height: 40,
                    padding: EdgeInsets.only(left: 5.0, bottom: 5.0),
                    child: FittedBox(
                      child: FloatingActionButton(
                        backgroundColor: buttonColor,
                        onPressed: () {
                          setState(() {
                            zoom = max(zoom - 0.1, zoomBoundaries.start);
                          });
                        },
                        child: Icon(Icons.remove),
                      ),
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    padding: EdgeInsets.only(left: 5.0, bottom: 5.0),
                    child: FittedBox(
                      child: FloatingActionButton(
                        backgroundColor: buttonColor,
                        onPressed: () {
                          setState(() {
                            zoom = min(zoom + 0.1, zoomBoundaries.end);
                          });
                        },
                        child: Icon(Icons.add),
                      ),
                    ),
                  ),
                  Container(
                    width: 300,
                    height: 40,
                    padding: EdgeInsets.only(bottom: 5.0),
                    child: Slider(
                      activeColor: buttonColor,
                      inactiveColor: buttonColor.withOpacity(0.5),
                      min: zoomBoundaries.start,
                      max: zoomBoundaries.end,
                      value: zoom,
                      onChanged: (double newValue) {
                        setState(() {
                          zoom = newValue;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ]);
        }),
      ),
    );
  }
}