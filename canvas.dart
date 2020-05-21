import 'package:flutter/material.dart';
import 'package:align_positioned/align_positioned.dart';
import 'dart:math';
import 'main.dart';

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
  var zoomBoundaries = RangeValues(-2, 4);

  List<double> mousePosition = [0, 0];

  int changeView = 0;
  bool initialBuild = true;

  List<double> getCanvasOffset(List<double> screenDimensions) {
    return [
      (0.5 * canvasWidth - coordinates[0]) * zoom - 0.5 * screenDimensions[0],
      (-0.5 * canvasHeight + coordinates[1]) * zoom - 0.5 * screenDimensions[1]
    ];
  }

  num clip(num number, num lowerLimit, num upperLimit) {
      return min(upperLimit, max(lowerLimit, number));
  }
  
  changeZoom(dZ, List<double> screenDimensions) {
    double _zoom = pow(2.0, clip(log(zoom) / log(2.0) + dZ, zoomBoundaries.start, zoomBoundaries.end));
    coordinates = [
      coordinates[0] + screenDimensions[0] * (1.0 / zoom - 1.0 / _zoom) / 2,
      coordinates[1] - screenDimensions[1] * (1.0 / zoom - 1.0 / _zoom) / 2
    ];
    zoom = _zoom;
  }
  setZoom(_zoom, List<double> screenDimensions) {
    coordinates = [
      coordinates[0] + screenDimensions[0] * (1.0 / zoom - 1.0 / _zoom) / 2,
      coordinates[1] - screenDimensions[1] * (1.0 / zoom - 1.0 / _zoom) / 2
    ];
    zoom = _zoom;
  }

  @override
  Widget build(BuildContext context) {

    final inheritedData = context.dependOnInheritedWidgetOfExactType<InheritedData>();

    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          coordinates = [coordinates[0] - details.delta.dx / zoom, coordinates[1] + details.delta.dy / zoom];
        });
      },
      child: Container(
        color: backgroundColor,
        child: LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {

          inheritedData.setScreenDimensions([constraints.maxWidth, constraints.maxHeight]);
          inheritedData.setCanvasZoom(zoom);

          if(changeView != inheritedData.changeView) {
            changeView = inheritedData.changeView;
            zoom = constraints.maxWidth / inheritedData.setCanvasViewWidth;
            coordinates = inheritedData.setCanvasViewCoordinates;
          }

          if(initialBuild) {
            zoom = constraints.maxWidth / canvasWidth * 0.95;
            coordinates = [
              -(constraints.maxWidth / zoom - canvasWidth) / 2, 
              (constraints.maxHeight / zoom + canvasHeight) / 2
            ];
            initialBuild = false;
          }

          return Stack(children: <Widget>[
            AlignPositioned(
              alignment: Alignment.center,
              minChildHeight: canvasHeight * zoom,
              maxChildHeight: canvasHeight * zoom,
              minChildWidth: canvasWidth * zoom,
              maxChildWidth: canvasWidth * zoom,
              dx: getCanvasOffset([constraints.maxWidth, constraints.maxHeight])[0],
              dy: getCanvasOffset([constraints.maxWidth, constraints.maxHeight])[1],
              child: MouseRegion(
                onHover: (details) {
                  setState(() {
                    mousePosition = [
                      details.position.dx / zoom + coordinates[0],
                      (-details.position.dy + inheritedData.appbarHeight) / zoom + coordinates[1]
                    ];
                  });
                },
                child: Container(
                  child: InheritedCanvas(
                    child: child,
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    canvasWidth: canvasWidth,
                    canvasHeight: canvasHeight,
                    zoom: zoom,
                    coordinates: getCanvasOffset([constraints.maxWidth, constraints.maxHeight]),
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
                            changeZoom(-0.1, [constraints.maxWidth, constraints.maxHeight]);
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
                            changeZoom(0.1, [constraints.maxWidth, constraints.maxHeight]);
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
                      value: log(zoom) / log(2.0),
                      onChanged: (double newValue) {
                        setState(() {
                          setZoom(pow(2.0, newValue), [constraints.maxWidth, constraints.maxHeight]);
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 5,
              right: 5,
              height: 40,
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.8),
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(5))
                  ),
                  child: Container(
                    margin: EdgeInsets.all(5),
                    child: Text("x: ${(mousePosition[0] * 100).toInt()/100}  y: ${(mousePosition[1] * 100).toInt()/100}"),
                  ),
                ),
              ),
            )
          ]);
        }),
      ),
    );
  }
}