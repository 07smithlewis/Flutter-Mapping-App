import 'package:flutter/material.dart';
import 'package:align_positioned/align_positioned.dart';
import 'dart:math';
import 'dart:js' as js;
import 'main.dart';

// Basic information on the canvas geometry is passed to any children of the canvas
class InheritedCanvas extends InheritedWidget {

  final double width;
  final double height;
  final double canvasWidth;
  final double canvasHeight;
  final double zoom;
  final double normalisedZoom;
  final Color canvasColor;
  final Function setWindowPinId;
  final List<double> coordinates;
  final bool significantChange;
  final double significantDistance;

  InheritedCanvas({Widget child, this.width, this.height, this.canvasWidth, this.canvasHeight, this.zoom, this.canvasColor, 
  this.normalisedZoom, this.setWindowPinId, this.coordinates, this.significantChange, this.significantDistance}) : super(child: child);

  @override
  bool updateShouldNotify(InheritedCanvas oldWidget) {
    return (oldWidget.significantChange != significantChange || oldWidget.zoom != zoom || oldWidget.width != width || oldWidget.height != height || oldWidget.canvasWidth != canvasWidth || oldWidget.canvasHeight != canvasHeight);
  }
}

// Allows pins to change the state of the popup window
class PopupPinChange extends InheritedWidget {

  final int id;
  final Function changeId;

  PopupPinChange({Widget child, this.id, this.changeId}) : super(child: child);

  @override
  bool updateShouldNotify(PopupPinChange oldWidget) {
    return oldWidget.id != id;
  }
}

// A floating 2D canvas, that supports panning and zooming
class Canvas extends StatefulWidget {
  
  // The size of the canvas in pixels at zoom = 1 
  final double canvasWidth;
  final double canvasHeight;

  final Widget child;
  final Color backgroundColor;
  final Color canvasColor;
  final Color buttonColor;
  final RangeValues zoomBoundaries;

  Canvas({this.canvasWidth, this.canvasHeight, this.child, this.backgroundColor = Colors.white, this.canvasColor = Colors.white, 
  this.buttonColor = Colors.grey, this.zoomBoundaries = const RangeValues(-2, 4)});

  final double buttonSize = 30;
  final double significantDistance = 100;

  @override
  _CanvasState createState() => _CanvasState();
}

class _CanvasState extends State<Canvas> {

  @override
  void initState() {
    popupWindowContent = new PopupWindowContent(
      buttonColor: widget.buttonColor,
      canvasColor: widget.canvasColor,
      buttonSize: widget.buttonSize,
      onDrag: (details){setState(() {
        windowLocation = [windowLocation[0] + details.delta.dx, windowLocation[1] - details.delta.dy];
      });},
      close: (){setState((){windowOpen = false;});},
      resize: (details){setState(() {
        List<double> _windowSize = [
          max(windowSize[0] + details.delta.dx, windowMinSize[0]), 
          max(windowSize[1] + details.delta.dy, windowMinSize[1])
        ];
        windowLocation[1] += windowSize[1] - _windowSize[1];
        windowSize = _windowSize;
      });},
    );
    super.initState();
  }

  PopupWindowContent popupWindowContent;
  bool windowOpen = false;
  List<double> windowLocation = [0, 0];
  List<double> windowSize = [200, 300];
  List<double> windowMinSize = [200, 200];
  int windowPinId;
  void setWindowPinId(int _windowPinId) {
    setState(() {
      windowPinId = _windowPinId;
      windowOpen = true;
    });
  }

  List<double> coordinates = [0.0, 0.0];
  List<double> lastRenderCoordinates = [0.0, 0.0];
  bool significantChange = false;
  double zoom = 1.0;

  int changeView = 0;
  bool initialBuild = true;

  // Changes from screen position (Top left corner) in canvas coordinates to canvas offset from centred in pixels
  List<double> getCanvasOffset(List<double> screenDimensions) {
    return [
      (0.5 * widget.canvasWidth - coordinates[0]) * zoom - 0.5 * screenDimensions[0],
      (-0.5 * widget.canvasHeight + coordinates[1]) * zoom - 0.5 * screenDimensions[1]
    ];
  }

  num clip(num number, num lowerLimit, num upperLimit) {
      return min(upperLimit, max(lowerLimit, number));
  }
  
  changeZoom(dZ, List<double> screenDimensions) {
    double _zoom = pow(2.0, clip(log(zoom) * log2e + dZ, widget.zoomBoundaries.start, widget.zoomBoundaries.end));
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

  List<double> mousePosition = [0, 0];

  bool radialOpen = false;
  List<double> radialPosition;
  List<double> radialPositionMap;
  final double radialButtonSize = 30;
  final double radialMenuRadius = 30;
  List<int> hovering = [0, 0];

  @override
  Widget build(BuildContext context) {

    final inheritedData = context.dependOnInheritedWidgetOfExactType<InheritedData>();

    List<Widget> stack = [
      Container(
        child: LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
          
          inheritedData.setCanvasCoordinates(getCanvasOffset([constraints.maxWidth, constraints.maxHeight]));

          inheritedData.setScreenDimensions([constraints.maxWidth, constraints.maxHeight]);
          inheritedData.setCanvasZoom(zoom);

          if(changeView != inheritedData.changeView) {
            changeView = inheritedData.changeView;
            zoom = pow(2.0, clip(log(constraints.maxWidth / inheritedData.setCanvasViewWidth) * log2e, widget.zoomBoundaries.start, widget.zoomBoundaries.end));
            coordinates = inheritedData.setCanvasViewCoordinates;
          }

          if(initialBuild) {
            zoom = constraints.maxWidth / widget.canvasWidth / 1.1;
            coordinates = [
              -(constraints.maxWidth / zoom - widget.canvasWidth) / 2, 
              (constraints.maxHeight / zoom + widget.canvasHeight) / 2
            ];
            initialBuild = false;
          }

          List<Widget> bottomButtonBar = [
            Container(
              width: widget.buttonSize + 5,
              height: widget.buttonSize + 5,
              padding: EdgeInsets.only(left: 5.0, bottom: 5.0),
              child: FittedBox(
                child: FloatingActionButton(
                  backgroundColor: widget.buttonColor,
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
              width: widget.buttonSize + 5,
              height: widget.buttonSize + 5,
              padding: EdgeInsets.only(left: 5.0, bottom: 5.0),
              child: FittedBox(
                child: FloatingActionButton(
                  backgroundColor: widget.buttonColor,
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
              height: widget.buttonSize + 5,
              padding: EdgeInsets.only(bottom: 5.0),
              child: Slider(
                activeColor: widget.buttonColor,
                inactiveColor: widget.buttonColor.withOpacity(0.5),
                min: widget.zoomBoundaries.start,
                max: widget.zoomBoundaries.end,
                value: log(zoom) * log2e,
                onChanged: (double newValue) {
                  setState(() {
                    setZoom(pow(2.0, newValue), [constraints.maxWidth, constraints.maxHeight]);
                  });
                },
              ),
            ),
          ];
          if(!windowOpen) {
            bottomButtonBar.add(
              Container(
                width: widget.buttonSize + 5,
                height: widget.buttonSize + 5,
                padding: EdgeInsets.only(left: 5.0, bottom: 5.0),
                child: FittedBox(
                  child: FloatingActionButton(
                    backgroundColor: widget.buttonColor,
                    onPressed: () {
                      setState(() {
                        windowOpen = true;
                      });
                    },
                    child: Icon(Icons.picture_in_picture),
                  ),
                ),
              )
            );
          }

          Widget inkWellButton(IconData icon, int hovering, Function setHover, Function onTap) {
            return Container(
              decoration: new BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4 + 0.2 * hovering),
                    blurRadius: 15.0,
                    spreadRadius: 5,
                  )
                ],
              ),
              child: InkWell(
                child: Icon(icon),
                onTap: (){onTap();},
                onHover: (bool _hovering){
                  setHover(_hovering ? 1 : 0);
                },
              ),
            );
          }

          return GestureDetector(
            onLongPressStart: (details){
              radialPosition = [details.localPosition.dx, details.localPosition.dy];
              radialPositionMap = [radialPosition[0] / zoom + coordinates[0], - radialPosition[1] / zoom + coordinates[1]];
              setState(() {
                if(radialPositionMap[0] > 0 && radialPositionMap[1] > 0 && radialPositionMap[0] < widget.canvasWidth && radialPositionMap[1] < widget.canvasHeight) {
                  radialOpen = true;
                }
                mousePosition = [
                  details.localPosition.dx / zoom + coordinates[0],
                  -details.localPosition.dy / zoom + coordinates[1]
                ];
              });
            },
            onTap: (){
              setState(() {
                radialOpen = false;
              });
            },
            onTapDown: (details){
              setState(() {
                mousePosition = [
                  details.localPosition.dx / zoom + coordinates[0],
                  -details.localPosition.dy / zoom + coordinates[1]
                ];
              });
            },
            onPanUpdate: (details) {
              setState(() {
                coordinates = [coordinates[0] - details.delta.dx / zoom, coordinates[1] + details.delta.dy / zoom];
                radialOpen = false;
              });
              double criticalDistance = 100;
              List<double> renderCoords = getCanvasOffset([constraints.maxWidth, constraints.maxHeight]);
              List<double> diff = [renderCoords[0] - lastRenderCoordinates[0], renderCoords[1] - lastRenderCoordinates[1]];
              diff = [diff[0] < 0 ? -diff[0] : diff[0], diff[1] < 0 ? -diff[1] : diff[1]];
              if(diff[0] > criticalDistance || diff[1] > criticalDistance) {
                lastRenderCoordinates = renderCoords;
                significantChange = !significantChange;
              }
            },
            child: Container(
              color: widget.backgroundColor,
              child: Stack(children: [
                AlignPositioned(
                  alignment: Alignment.center,
                  minChildHeight: widget.canvasHeight * zoom,
                  maxChildHeight: widget.canvasHeight * zoom,
                  minChildWidth: widget.canvasWidth * zoom,
                  maxChildWidth: widget.canvasWidth * zoom,
                  dx: getCanvasOffset([constraints.maxWidth, constraints.maxHeight])[0],
                  dy: getCanvasOffset([constraints.maxWidth, constraints.maxHeight])[1],
                  child: Container(
                    child: InheritedCanvas(
                      child: widget.child,
                      coordinates: getCanvasOffset([constraints.maxWidth, constraints.maxHeight]),
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                      canvasWidth: widget.canvasWidth,
                      canvasHeight: widget.canvasHeight,
                      zoom: zoom,
                      normalisedZoom: log(zoom) * log2e,
                      canvasColor: widget.canvasColor,
                      setWindowPinId: setWindowPinId,
                      significantChange: significantChange,
                      significantDistance: widget.significantDistance,
                    ),
                    decoration: BoxDecoration(
                      color: widget.canvasColor,
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
                    children: bottomButtonBar,
                  ),
                ),
                Positioned(
                  bottom: 5,
                  right: 5,
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
                        child: Column(children: [
                          Text("Zoom = ${(100 * log(zoom) * log2e).toInt() / 100}"),
                          Text("x: ${(mousePosition[0] * 100).toInt()/100}${inheritedData.settings[3]}  y: ${(mousePosition[1] * 100).toInt()/100}${inheritedData.settings[3]}"),
                        ]),
                      ),
                    ),
                  ),
                ),
                radialOpen ? Positioned(
                  left: radialPosition[0] - radialButtonSize / 2,
                  top: radialPosition[1] - radialMenuRadius - radialButtonSize / 2,
                  width: radialButtonSize,
                  height: radialButtonSize,
                  child: inkWellButton(Icons.add_location, hovering[0], (_hovering){setState((){hovering[0] = _hovering;});}, (){
                    inheritedData.mapDataDb.submitForm(["append", "New Pin", radialPositionMap[0], radialPositionMap[1], -100, 100, "", "", "", "", false], (e){});
                  })
                ):Container()
              ]),
            ),
          );
        }),
      ),
    ];
    if(windowOpen) {
      stack.add(
        Positioned(
          left: windowLocation[0],
          bottom: windowLocation[1],
          width: windowSize[0],
          height: windowSize[1],
          child: PopupPinChange(
            id: windowPinId,
            changeId: setWindowPinId,
            child: popupWindowContent
          )
        )
      );
    }

    return Stack(children: stack);
  }
}

class PopupWindowContent extends StatefulWidget {

  final Color buttonColor;
  final Color canvasColor;
  final double buttonSize;
  final Function onDrag;
  final Function close;
  final Function resize;

  PopupWindowContent({this.buttonColor, this.canvasColor, this.buttonSize, this.onDrag, this.close, this.resize});

  @override
  _PopupWindowContentState createState() => _PopupWindowContentState();
}

class _PopupWindowContentState extends State<PopupWindowContent> {

  final List<TextEditingController> myController = List<TextEditingController>.generate(9, (index) => TextEditingController());
  
  @override
  void dispose() {
    myController.map((controller) {
      controller.dispose();
    });
    super.dispose();
  }

  bool nameplateSwitch;
  int pinId;
  List pin;

  void setPin(int _pinId) {
    final inheritedData = context.dependOnInheritedWidgetOfExactType<InheritedData>();
    pinId = _pinId;
    pin = inheritedData.mapDataInfo[inheritedData.mapDataInfo.indexWhere((element) => (element[0] == pinId))];
    for(int i = 0; i < myController.length; i++) {
      myController[i].text = pin[i + 1].toString();
    }
    nameplateSwitch = pin[10];
  }

  bool edit = false;
  bool buttonActive = true;
  List<bool> loading = [false, false];
  List<bool> err = [false, false, false, false, false];
  List<String> errMessage = ["A pin already exists at that position", "Position values must be numeric", "Position is out of range", 
  "Zoom values must be numeric", "Maximum zoom must be larger than minimum zoom"];

  List<double> zoomClipping = [-100, 100];
  void setZoomClipping (String lowerBound, String upperBound) {
    if(isNumeric(lowerBound)) {
      zoomClipping[0] = double.parse(lowerBound);
    }
    if(isNumeric(upperBound)) {
      zoomClipping[1] = double.parse(upperBound);
    }
  }

  @override
  Widget build(BuildContext context) {

    final inheritedData = context.dependOnInheritedWidgetOfExactType<InheritedData>();
    final popupPinChange = context.dependOnInheritedWidgetOfExactType<PopupPinChange>();
    
    if(popupPinChange.id != pinId) {
      pinId = popupPinChange.id;
      if(pinId != null && inheritedData.mapDataInfo.indexWhere((e) => (e[0] == pinId)) == -1) {pinId = null;}
      if(pinId != null) {setPin(pinId);}
    }

    List<Widget> windowWidgetList = [];

    if(pinId != null) {

      if(!edit) {
        if(pin[7] != ""){
          windowWidgetList.addAll([
            Image.network(
              pin[7],
              fit: BoxFit.fitWidth,
            ),
            Divider(height: 5, thickness: 5, color: widget.buttonColor,),
          ]);
        }
        windowWidgetList.addAll([
          Divider(height: 5, color: widget.canvasColor,),
          Row(children: [
            Expanded(child: Container(child: Text(pin[6]))),
            Container(
              width: widget.buttonSize,
              height: widget.buttonSize,
              child: FittedBox(
                child: IconButton(icon: Icon(Icons.edit), onPressed: (){setState(() {edit = true;});})
              ),
            ),
          ]),
          Divider(height: 15, color: widget.canvasColor,),
          Text(pin[8])
        ]);
      
      }else{

        double entryHeight = 60;
        double spaceHeight = 20;
        
        windowWidgetList.addAll([
          ListInput(title: "Image", numberOfFields: 1, fieldNames: ["Link: "], height: entryHeight, textEditingControllers: myController.sublist(6, 7),),
          Divider(height: spaceHeight, thickness: 5,),
          ListInput(title: "Title", numberOfFields: 1, fieldNames: [""], height: entryHeight, textEditingControllers: myController.sublist(5, 6),),
          Divider(height: spaceHeight, thickness: 5,),
          ListInput(title: "Content", numberOfFields: 1, fieldNames: [""], height: entryHeight, textEditingControllers: myController.sublist(7, 8),),
          Divider(height: spaceHeight, thickness: 5,),
          ListInput(title: "External Link", numberOfFields: 1, fieldNames: ["Link"], height: entryHeight, textEditingControllers: myController.sublist(8, 9),),
          Divider(height: spaceHeight, thickness: 5,),
          ListInput(title: "Name", numberOfFields: 1, fieldNames: [""], height: entryHeight, textEditingControllers: myController.sublist(0, 1),),
          Container(
            height: entryHeight,
            margin: EdgeInsets.fromLTRB(5, 0, 5, 0),
            child: Row(children: [
              Text("ShowNameplate"),
              Switch(
                value: nameplateSwitch,
                onChanged: (value) {
                  setState(() {
                    nameplateSwitch = value;
                  });
                },
              ),
            ],),
          ),
          Divider(height: spaceHeight, thickness: 5,),
          ListInput(title: "Position", numberOfFields: 2, fieldNames: ["x:", "y:"], height: entryHeight, textEditingControllers: myController.sublist(1, 3),),
        ]);

        if(err[0]) {windowWidgetList.addAll(errorMessage(errMessage[0], spaceHeight));}
        if(err[1]) {windowWidgetList.addAll(errorMessage(errMessage[1], spaceHeight));}
        if(err[2]) {windowWidgetList.addAll(errorMessage(errMessage[2], spaceHeight));}

        windowWidgetList.addAll([
          Divider(height: spaceHeight, thickness: 5,),
          ListInputHint(title: "Zoom Clipping", numberOfFields: 2, fieldNames: ["Min zoom:", "Max zoom:"], height: entryHeight, textEditingControllers: myController.sublist(3, 5), hintText: ["-inf", "inf"],),
        ]);

        if(err[3]) {windowWidgetList.addAll(errorMessage(errMessage[3], spaceHeight));}
        if(err[4]) {windowWidgetList.addAll(errorMessage(errMessage[4], spaceHeight));}

        windowWidgetList.addAll(<Widget>[
        Divider(height: spaceHeight, thickness: 5,),
        Container(
          margin: EdgeInsets.all(10),
          child: RaisedButton(
            onPressed: (){
              if(buttonActive) {
                setState(() {
                  buttonActive = false;
                });

                if(isNumeric(myController[1].text) && isNumeric(myController[2].text)) {
                  setState(() {err[1] = false;});
                  if(0 < double.parse(myController[1].text) && double.parse(myController[1].text) < inheritedData.canvasDimensions[0] 
                  && 0 < double.parse(myController[2].text) && double.parse(myController[2].text) < inheritedData.canvasDimensions[1]) {
                    setState(() {err[2] = false;});
                  }else{setState(() {err[2] = true;});}
                }else{setState(() {
                  err[1] = true;
                  err[2] = false;
                });}

                if((isNumeric(myController[3].text) || myController[3].text == "") && (isNumeric(myController[4].text) || myController[4].text == "")) {
                  setZoomClipping(myController[3].text, myController[4].text);
                  setState(() {err[3] = false;});
                  if(zoomClipping[0] < zoomClipping[1]) {
                    setState(() {err[4] = false;});
                  }else{setState(() {err[4] = true;});}
                }else{setState(() {
                  err[3] = true;
                  err[4] = false;
                });}

                List<String> pinLocations = inheritedData.mapDataInfo.map((pin) {
                  if(pin[0] != pinId) {
                    return "${pin[2]} ${pin[3]}";
                  }else{
                    return "";
                  }
                }).toList();
                String pinLocation = "${myController[1].text} ${myController[2].text}";
                if(!pinLocations.contains(pinLocation)) {
                  setState(() {err[0] = false;});
                }else{setState(() {err[0] = true;});}

                if(!err.any((element) => element)) {
                  loading[0] = true;
                  inheritedData.mapDataDb.submitForm([
                      "replace", pinId,
                      myController[0].text, myController[1].text, myController[2].text,
                      zoomClipping[0], zoomClipping[1],
                      myController[5].text, myController[6].text, myController[7].text, myController[8].text, 
                      nameplateSwitch,
                    ], (response){
                      setState(() {
                        loading[0] = false;
                        buttonActive = true;
                      });
                    }); 
                }else{
                  setState(() {
                    buttonActive = true;
                  });
                }
              }
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: button("Save", Icons.save, loading[0]),
            ),
          ),
        ),
        Container(
          margin: EdgeInsets.all(10),
          child: RaisedButton(
            onPressed: (){
              if(buttonActive) {
                setState(() {
                  buttonActive = false;
                });

                loading[1] = true;
                inheritedData.mapDataDb.submitForm([
                  "delete", pinId,
                ], (response){
                  inheritedData.getMapData((){
                    loading[1] = false;
                    buttonActive = true;
                  });
                });
              }
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: button("Delete", Icons.delete, loading[1]),
            ),
          ),
        )]);
      }

    }

    Widget topLeftButton;
    if(edit) {
      topLeftButton = FloatingActionButton(
        backgroundColor: widget.buttonColor,
        onPressed: () {
          setState(() {
            edit = false;
          });
        },
        child: Icon(Icons.arrow_back),
      );
    }else{
      topLeftButton = FloatingActionButton(
        backgroundColor: widget.buttonColor,
        onPressed: () {
          if(pinId != null) {
            if(pin[9] != "") {
              js.context.callMethod("open", [pin[9]]);
            }
          }
        },
        child: Icon(Icons.link),
      );
    }
    
    return Container(
      decoration: BoxDecoration(
        color: widget.buttonColor,
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(10),
          topLeft: Radius.circular(10),
        )
      ),
      child: Stack(children: [
        Container(
          margin: EdgeInsets.all(5),
          child: Column(children: [
            GestureDetector(
              onPanUpdate: (details){widget.onDrag(details);},
              child: Container(
                color: widget.buttonColor,
                child: Row(children: [
                  Container(
                    width: widget.buttonSize + 5,
                    height: widget.buttonSize + 5,
                    margin: EdgeInsets.only(bottom: 5, right: 5),
                    child: FittedBox(
                      child: topLeftButton
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: widget.buttonSize + 5,
                      child: Center(child: Text(pinId != null ? pin[1] : "", style: TextStyle(color: Colors.white, fontSize: 15),))
                    ),
                  ),
                  Container(
                    width: widget.buttonSize + 5,
                    height: widget.buttonSize + 5,
                    margin: EdgeInsets.only(bottom: 5, left: 5),
                    child: FittedBox(
                      child: FloatingActionButton(
                        backgroundColor: widget.buttonColor,
                        onPressed: () {widget.close();},
                        child: Icon(Icons.close),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
            Expanded(
              child: Container(
                color: widget.canvasColor,
                child: ListView(
                  children: windowWidgetList
                ),
              ),
            ),
          ],),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          width: 30,
          height: 30,
          child: GestureDetector(
            onPanUpdate: (details){widget.resize(details);},
            child: Container(
              decoration: BoxDecoration(
                color: widget.buttonColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(5),
                )
              ),
              child: Container(
                margin: EdgeInsets.all(5),
                child: Icon(Icons.drag_handle)
              ),
            ),
          ),
        )
      ]),
    );
  }
}

class ListInput extends StatelessWidget {

  final String title;
  final int numberOfFields;
  final List<String> fieldNames;
  final List<TextEditingController> textEditingControllers;
  final double height;
  final bool limitLines;

  ListInput({this.title = "Title", this.numberOfFields = 0, this.fieldNames = const <String>[], this.height = 40, this.textEditingControllers = const <TextEditingController>[], this.limitLines = true});

  final double textBoxHeightFraction = 1;

  Widget textFieldConstructor(controller) {

    if(limitLines) {
      return TextField(
        maxLines: 1,
        controller: controller,
      );
    }else{
      return TextField(
        keyboardType: TextInputType.multiline,
        maxLines: null,
        controller: controller,
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    List<Widget> inputFields = [];
    for(var i = 0; i < numberOfFields; i++) {
      inputFields.addAll(<Widget>[
        Text(fieldNames[i]),
        Container(width: 5,),
        Expanded(
          child: Container(
            height: height * textBoxHeightFraction,
            child: textFieldConstructor(textEditingControllers[i])
          ),
        ),
        Container(width: 5,),
      ]);
    }
    inputFields.removeLast();

    return Container(
      height: height,
      margin: EdgeInsets.fromLTRB(5, 0, 5, 0),
      child: Column(children: <Widget>[
        Container(
          width: double.infinity,
          child: Text(title),
        ),
        Expanded(
          child: Container(
            width: double.infinity,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: inputFields,
            ),
          ),
        )
      ],),
    );
  }
}