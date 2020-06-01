import 'package:flutter/material.dart';
import 'canvas.dart';
import 'canvasWidgets.dart';
import 'dbInteraction.dart';
import 'dart:math';
import 'dart:convert';
import 'dart:async';

class InheritedData extends InheritedWidget {

  final DbInteraction settingsDb;
  final DbInteraction mapDb;
  final DbInteraction mapDataDb;
  final Function getSettings;
  final Function getMaps;
  final Function getMapData;
  final List<int> canvasDimensions;
  final List mapsInfo;
  final List mapDataInfo;
  final List settings;
  final List<Widget> maps;
  final List<Widget> mapData;
  final Color mainColor;
  final List<double> setCanvasViewCoordinates;
  final double setCanvasViewWidth;
  final int changeView;
  final Function setView;
  final int sidebarIndex;
  final Function setSidebarIndex;
  final List<double> screenDimensions;
  final Function setScreenDimensions;
  final double canvasZoom;
  final Function setCanvasZoom;
  final List<double> canvasCoordinates;
  final Function setCanvasCoordinates;
  final pinSize = 20;
  final List<double> maxNameplateSize = [150, 40];
  final double iconAnchorPoint = 0;

  InheritedData({Widget child, this.canvasDimensions, this.mapsInfo, this.mapDataInfo, this.maps, this.mapData, this.mainColor, 
  this.setCanvasViewCoordinates, this.setCanvasViewWidth, this.changeView, this.setView, this.mapDb, this.mapDataDb, this.getMaps, 
  this.getMapData, this.sidebarIndex, this.setSidebarIndex, this.screenDimensions, this.setScreenDimensions, this.canvasZoom, 
  this.setCanvasZoom, this.settingsDb, this.getSettings, this.settings, this.canvasCoordinates, this.setCanvasCoordinates}) : super(child: child);

  @override
  bool updateShouldNotify(InheritedData oldWidget) {
    return oldWidget.canvasDimensions[0] != canvasDimensions[0] || oldWidget.canvasDimensions[1] != canvasDimensions[1] ||
    oldWidget.mapsInfo.toString() != mapsInfo.toString() || oldWidget.mapDataInfo.toString() != mapDataInfo.toString() ||
    oldWidget.settings.toString() != settings.toString() || oldWidget.screenDimensions[0] != screenDimensions[0] ||
    oldWidget.screenDimensions[1] != screenDimensions[1] || oldWidget.canvasCoordinates[0] != canvasCoordinates[0] ||
    oldWidget.canvasCoordinates[1] != canvasCoordinates[1];
  }
}

void main() => runApp(MaterialApp(home: Home()));

class Home extends StatefulWidget {

  final DbInteraction mapDb = new DbInteraction(
    spreadsheetId: "1KXsICI8z6WPonIavtpgruh38WMKwPvweAXT3dCx1FEg",
    headers: ["mapName", "isTiled", "x", "y", "z", "minZoom", "maxZoom", "width", "height", "link", "metadata"]
  );
  final DbInteraction mapDataDb = DbInteraction(
    spreadsheetId: "1RNbF50QzE0NDY5FSIjH8sQTrEua7FmC_joMQjr9ijSo",
    headers: ["Name", "x", "y", "minZoom", "maxZoom", "title", "image", "content", "link", "showNameplate", "icon", "customIcon"]
  );
  final DbInteraction settingsDb = DbInteraction(
    spreadsheetId: "1Gp2jb89T295CpraBZwPEW0i7KNgg9y56z_y6y9FWrRI",
    headers: ["canvasWidth", "canvasHeight", "canvasUnits", "minZoom", "maxZoom", "appColor", "canvasButtonColor", "canvasBackgroundColor", "canvasColor"]
  );

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {

  List mapsInfo = [];
  List mapDataInfo = [];
  List<Widget> maps = <Widget>[];
  List<Widget> mapData = <Widget>[];
  List settings = [0, 1000, 1000, "m", -2, 8, "424b54", "424b54", "eaeaea", "ffffff"];

  static int getColorFromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF" + hexColor;
    }
    return int.parse(hexColor, radix: 16);
  }
  
  void getMaps(Function callback) {
    void getMapsCallback(_maps) {
      if(_maps["data"].toString() != mapsInfo.toString()) {
        setState(() {
          mapsInfo = _maps["data"];
          mapsInfo.sort((a, b) => (a[5].compareTo(b[5])));
          maps = mapsInfo.map((e) => Map(map: e,)).toList();
        });
      }
      callback();
    }
    widget.mapDb.submitForm(["get"], getMapsCallback);
  }
  void getMapData(Function callback) {
    void getMapData(_mapData) {
      if(_mapData["data"].toString() != mapDataInfo.toString()) {
        setState(() {
          mapDataInfo = _mapData["data"];
          mapData = mapDataInfo.map((e) => MapPin(pin: e,)).toList();
        });
      }
      callback();
    }
    widget.mapDataDb.submitForm(["get"], getMapData);
  }
  void getSettings(Function callback) {
    void getSettings(_settings) {
      if( _settings["data"][0].toString() != settings.toString()) {
        setState(() {
          settings = _settings["data"][0];
        });
      }
      callback();
    }
    widget.settingsDb.submitForm(["get"], getSettings);
  }

  bool rebuild = false;

  @override
  void initState() {
    getMaps((){});
    getMapData((){});
    getSettings((){setView([-settings[1] * 0.05, settings[2] * 1.05], settings[1] * 1.1);});
    Timer.periodic(new Duration(seconds: 5), (timer) {
      getMaps((){});
      getMapData((){});
      getSettings((){});
      setState((){rebuild = !rebuild;});
    });
    super.initState();
  }

  List<double> setCanvasViewCoordinates;
  double setCanvasViewWidth;
  int changeView = 0;
  void setView(List<double> coordinates, double width) {
    setState(() {
      setCanvasViewCoordinates = coordinates;
      setCanvasViewWidth = width;
      changeView = (changeView + 1) % 2;
    });
  }

  List<double> screenDimensions = [0, 0];
  void setScreenDimensions(List<double> _screenDimensions) {
    screenDimensions = _screenDimensions;
  }
  double canvasZoom = 1;
  void setCanvasZoom(_canvasZoom) {
    canvasZoom = _canvasZoom;
  }
  int sidebarIndex = 0;
  void setSidebarIndex(int index) {
    setState(() {
      sidebarIndex = index;
    }); 
  }
  List<double> canvasCoordinates = [0, 0];
  void setCanvasCoordinates(List<double> coordinates) {
    canvasCoordinates = coordinates;
  }

  @override
  Widget build(BuildContext context) {

    bool checkRebuild = rebuild;

    return InheritedData(
      getMaps: getMaps,
      getMapData: getMapData,
      mapDb: widget.mapDb,
      mapDataDb: widget.mapDataDb,
      canvasDimensions: <int>[settings[1], settings[2]],
      mainColor: Color(getColorFromHex(settings[6])),
      settingsDb: widget.settingsDb,
      getSettings: getSettings,
      settings: settings,
      maps: maps,
      mapsInfo: mapsInfo,
      mapData: mapData,
      mapDataInfo: mapDataInfo,
      setCanvasViewCoordinates: setCanvasViewCoordinates,
      setCanvasViewWidth: setCanvasViewWidth,
      changeView: changeView,
      setView: setView,
      sidebarIndex: sidebarIndex,
      setSidebarIndex: setSidebarIndex,
      screenDimensions: screenDimensions,
      setScreenDimensions: setScreenDimensions,
      canvasZoom: canvasZoom,
      setCanvasZoom: setCanvasZoom,
      canvasCoordinates: canvasCoordinates,
      setCanvasCoordinates: setCanvasCoordinates,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Color(getColorFromHex(settings[6])),
          title: Text("Map"),
          centerTitle: true,
        ),
        drawer: SideBar(),
        body: Canvas(
          zoomBoundaries: RangeValues(settings[4], settings[5]),
          canvasWidth: settings[1],
          canvasHeight: settings[2],
          backgroundColor: Color(getColorFromHex(settings[8])),
          canvasColor: Color(getColorFromHex(settings[9])),
          buttonColor: Color(getColorFromHex(settings[7])),
          child: Content(),
        ),
      ),
    );
  }
}

class Content extends StatelessWidget {
  const Content({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    final inheritedData = context.dependOnInheritedWidgetOfExactType<InheritedData>();

    return Stack(
      children: <Widget>[
        Stack(children: inheritedData.maps,),
        Stack(children: inheritedData.mapData,),
      ],
    );
  }
}

class NavBarOption {
  final String title;
  final IconData icon;
  const NavBarOption(this.title, this.icon);
}

class SideBar extends StatelessWidget {

  @override
  Widget build(BuildContext context) {

    final inheritedData = context.dependOnInheritedWidgetOfExactType<InheritedData>();

    const List<NavBarOption> navBarOptions = <NavBarOption>[
      NavBarOption('Navigation', Icons.bookmark),
      NavBarOption('Add Map', Icons.map),
      NavBarOption('Add Pin', Icons.add_location),
      NavBarOption('Settings', Icons.settings),
    ];

    Widget pageSelector() {
      switch(inheritedData.sidebarIndex) {
        case 0:
          return MapNavigation();
        break;

        case 1:
          return AddMapSelector();
        break;

        case 2:
          return AddPin();
        break;

        case 3:
          return Settings(settings: inheritedData.settings,);
        break;

        default:
          return Container();
      }
    }

    return Container(
      width: min(300, MediaQuery.of(context).size.width),
      color: Colors.white,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: inheritedData.mainColor,
          title: Text("Tools"),
          centerTitle: true,
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: inheritedData.sidebarIndex,
          onTap: (index){
            inheritedData.setSidebarIndex(index);
          },
          items: navBarOptions.map((NavBarOption navBarOption) {
            return BottomNavigationBarItem(
              icon: Icon(navBarOption.icon),
              title: Text(navBarOption.title)
            );
          }).toList(),
        ),
        body: pageSelector(),
      ),
    );
  }
}

class MapNavigation extends StatefulWidget {

  @override
  _MapNavigationState createState() => _MapNavigationState();
}

class _MapNavigationState extends State<MapNavigation> {

  int editing = 0;
  List editItem;
  final search = TextEditingController();
  final double searchHeight = 60;

  @override
  Widget build(BuildContext context) {

    switch(editing) {
      case 0:
        final inheritedData = context.dependOnInheritedWidgetOfExactType<InheritedData>();

        List<Widget> drawerContents = [
          ListTile(
            leading: Icon(Icons.home),
            title: Text("Canvas"),
            onTap: () {
              inheritedData.setView(<double>[-inheritedData.canvasDimensions[0] * 0.05, inheritedData.canvasDimensions[1] * 1.05], inheritedData.canvasDimensions[0] * 1.1);
              Navigator.pop(context);
            },
          ),
          Divider(
            height: 10,
            thickness: 5,
          ),
          Container(
            height: searchHeight,
            margin: EdgeInsets.fromLTRB(5, 0, 5, 0),
            child: Column(children: <Widget>[
              Container(
                width: double.infinity,
                child: Text("Search"),
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  child: Container(
                    child: TextField(
                      maxLines: 1,
                      controller: search,
                      onChanged: (text){
                        setState(() {});
                      },
                  )),
                ),
              ),
            ])
          ),
          Divider(
            height: 10,
            thickness: 5,
          ),
        ];

        List mapsInfo = inheritedData.mapsInfo.map((e) => e).toList();
        mapsInfo.removeWhere((map) {
          double width = map[8] * inheritedData.canvasZoom;
          double height = (map[9] == "" ? 2 * map[8] : map[9]) * inheritedData.canvasZoom;
          List<double> position = [map[3], inheritedData.canvasDimensions[1] - map[4]];
          double normalisedZoom = log(inheritedData.canvasZoom) * log2e;

          return !map[1].toString().toLowerCase().contains(search.text.toLowerCase()) || !(normalisedZoom > map[6]) || !(normalisedZoom < map[7])
          || !((inheritedData.screenDimensions[0] - inheritedData.canvasDimensions[0] * inheritedData.canvasZoom)/2.0 + inheritedData.canvasCoordinates[0] + position[0] * inheritedData.canvasZoom + width > 0)
          || !((-inheritedData.screenDimensions[0] - inheritedData.canvasDimensions[0] * inheritedData.canvasZoom)/2.0 + inheritedData.canvasCoordinates[0] + position[0] * inheritedData.canvasZoom < 0)
          || !((inheritedData.screenDimensions[1] - inheritedData.canvasDimensions[1] * inheritedData.canvasZoom)/2.0 + inheritedData.canvasCoordinates[1] + position[1] * inheritedData.canvasZoom + height > 0)
          || !((-inheritedData.screenDimensions[1] - inheritedData.canvasDimensions[1] * inheritedData.canvasZoom)/2.0 + inheritedData.canvasCoordinates[1] + position[1] * inheritedData.canvasZoom < 0);
        });
        mapsInfo.sort((a, b) => a[1].toString().compareTo(b[1].toString()));

        drawerContents.addAll(mapsInfo.map((map) => ListTile(
          leading: Icon(Icons.map),
          title: Text(map[1]),
          subtitle: Text("x: ${map[3]},\ny: ${map[4]}"),
          enabled: true,
          onTap: () {
            inheritedData.setView(<double>[map[3], map[4]], map[8]);
            Navigator.pop(context);
          },
          trailing: IconButton(icon: Icon(Icons.edit), onPressed: (){
            setState(() {
              editing = 1;
              editItem = map;
            });
          }),
        )).toList());
        drawerContents.add(Divider(
          height: 10,
          thickness: 5,
        ));

        List mapDataInfo = inheritedData.mapDataInfo.map((e) => e).toList();
        mapDataInfo.removeWhere((pin) {

          List<double> position = [pin[2] * inheritedData.canvasZoom - inheritedData.maxNameplateSize[0] / 2, pin[3] * inheritedData.canvasZoom - inheritedData.pinSize * inheritedData.iconAnchorPoint];
          List<double> positionScreen = [(inheritedData.screenDimensions[0] - inheritedData.canvasDimensions[0] * inheritedData.canvasZoom) / 2 + inheritedData.canvasCoordinates[0] + position[0],
          (inheritedData.screenDimensions[1] - inheritedData.canvasDimensions[1] * inheritedData.canvasZoom) / 2 - inheritedData.canvasCoordinates[1] + position[1]];
          double normalisedZoom = log(inheritedData.canvasZoom) * log2e;

          return !pin[1].toString().toLowerCase().contains(search.text.toLowerCase()) || !(normalisedZoom > pin[4] && normalisedZoom < pin[5])
          || !(positionScreen[0] > -inheritedData.maxNameplateSize[0]) || !(positionScreen[0] < inheritedData.screenDimensions[0])
          || !(positionScreen[1] > -inheritedData.maxNameplateSize[1] + inheritedData.pinSize * (1 - inheritedData.iconAnchorPoint))
          || !(positionScreen[1] < inheritedData.screenDimensions[1] + inheritedData.pinSize * inheritedData.iconAnchorPoint);
        });
        mapDataInfo.sort((a, b) => a[1].toString().compareTo(b[1].toString()));

        drawerContents.addAll(mapDataInfo.map((pin) => ListTile(
          leading: Icon(Icons.pin_drop),
          title: Text(pin[1]),
          subtitle: Text("x: ${pin[2]},\ny: ${pin[3]}"),
          enabled: true,
          onTap: () {
            double zoomClippingMultiplier = min(1, 0.9 * (inheritedData.screenDimensions[0] / inheritedData.canvasDimensions[0]) / pow(2, pin[4]));
            inheritedData.setView(<double>[pin[2] - inheritedData.canvasDimensions[0] * zoomClippingMultiplier / 2, 
            pin[3] + inheritedData.screenDimensions[1] * zoomClippingMultiplier / 2 * (inheritedData.canvasDimensions[0] / inheritedData.screenDimensions[0])], 
            inheritedData.canvasDimensions[0] * zoomClippingMultiplier);
            Navigator.pop(context);
          },
          trailing: IconButton(icon: Icon(Icons.edit), onPressed: (){
            setState(() {
              editing = 2;
              editItem = pin;
            });
          }),
        )).toList());

        return ListView(
          children: drawerContents,
        );
      break;
      
      case 1:
        return EditMapSelector(map: editItem);
      break;

      case 2:
        return EditPin(pin: editItem);
      break;

      default:
        return Container();
    }
  }
}

bool isNumeric(String s) {
  if (s == null) {
    return false;
  }
  return double.tryParse(s) != null;
}

List<Widget> errorMessage(String message, double height) {
  return <Widget>[
    Container(height: height, width: double.infinity,),
    Container(
      width: double.infinity,
      child: Text(message),
    ),
  ];
}

List<Widget> button(String text, IconData icon, bool loading) {
  List<Widget> widgetList = <Widget>[];
  widgetList.addAll(<Widget>[
    Icon(icon),
    Text(text),
  ]);
  if(loading) {
    widgetList.addAll(<Widget>[
      Container(width: 5,),
      SizedBox(
        child: CircularProgressIndicator(),
        width: 20,
        height: 20,
      ),
    ]);
  }
  return widgetList;
}

class AddPin extends StatefulWidget {

  @override
  _AddPinState createState() => _AddPinState();
}

class _AddPinState extends State<AddPin> {

  final List<TextEditingController> myController = List<TextEditingController>.generate(6, (index) => TextEditingController());

  @override
  void dispose() {
    myController.map((controller) {
      controller.dispose();
    });
    super.dispose();
  }

  bool loading = false;
  bool buttonActive = true;
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

  int iconSelected = 0;
  bool customIcon = false;

  @override
  Widget build(BuildContext context) {

    final inheritedData = context.dependOnInheritedWidgetOfExactType<InheritedData>();

    final double entryHeight = 60;
    final double spaceHeight = 20;

    final List<Widget> listItems = <Widget>[
      Divider(height: spaceHeight, thickness: 5,),
      ListInput(title: "Name", numberOfFields: 1, fieldNames: [""], height: entryHeight, textEditingControllers: myController.sublist(2, 3),),
      Divider(height: spaceHeight, thickness: 5,),
      ListInput(title: "Position", numberOfFields: 2, fieldNames: ["x:", "y:"], height: entryHeight, textEditingControllers: myController.sublist(0, 2),),
    ];

    if(err[0]) {listItems.addAll(errorMessage(errMessage[0], spaceHeight));}
    if(err[1]) {listItems.addAll(errorMessage(errMessage[1], spaceHeight));}
    if(err[2]) {listItems.addAll(errorMessage(errMessage[2], spaceHeight));}

    listItems.addAll(<Widget>[
      Divider(height: spaceHeight, thickness: 5,),
      ListInputHint(title: "Zoom Clipping", numberOfFields: 2, fieldNames: ["Min zoom:", "Max zoom:"], height: entryHeight, textEditingControllers: myController.sublist(3, 5), hintText: ["-inf", "inf"],),
    ]);

    if(err[3]) {listItems.addAll(errorMessage(errMessage[3], spaceHeight));}
    if(err[4]) {listItems.addAll(errorMessage(errMessage[4], spaceHeight));}

    List<Widget> icons = List.generate(20, (index) => Container(
      margin: EdgeInsets.all(2), width: 44, height: 44, child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(index == iconSelected ? 0.2 : 0),
          borderRadius: BorderRadius.circular(5)
        ),
        width: double.infinity, height: double.infinity, 
        child: FlatButton(
          shape: new RoundedRectangleBorder(borderRadius: new BorderRadius.circular(5)),
          onPressed: (){setState(() {iconSelected = index;});},
          child: Center(child: Image.network("./Icons/${index + 1}.png"))
        ),
      )
    ));
    listItems.addAll(<Widget>[
      Divider(height: spaceHeight, thickness: 5,),
      Container(
        margin: EdgeInsets.fromLTRB(5, 0, 5, 0),
        child: Row(children: [
          Text("Custom Icon"),
          Switch(
            value: customIcon,
            onChanged: (value) {
              setState(() {
                customIcon = value;
                myController[5].text = "";
              });
            },
          ),
        ],),
      ),
      customIcon ? ListInput(title: "Icon", numberOfFields: 1, fieldNames: ["Link"], height: entryHeight, textEditingControllers: myController.sublist(5, 6),) :
      Wrap(children: icons)
    ]);

    listItems.addAll(<Widget>[
      Divider(height: spaceHeight, thickness: 5,),
      Container(
        margin: EdgeInsets.all(10),
        child: RaisedButton(
          onPressed: (){
            if(buttonActive) {
              setState(() {
                buttonActive = false;
              });

              if(isNumeric(myController[0].text) && isNumeric(myController[1].text)) {
                setState(() {err[1] = false;});
                if(0 < double.parse(myController[0].text) && double.parse(myController[0].text) < inheritedData.canvasDimensions[0] 
                && 0 < double.parse(myController[1].text) && double.parse(myController[1].text) < inheritedData.canvasDimensions[1]) {
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

              List<String> pinLocations = inheritedData.mapDataInfo.map((pin) => "${pin[2]} ${pin[3]}").toList();
              String pinLocation = "${myController[0].text} ${myController[1].text}";
              if(!pinLocations.contains(pinLocation)) {
                setState(() {err[0] = false;});
              }else{setState(() {err[0] = true;});}

              if(!err.any((element) => element)) {
                loading = true;
                inheritedData.mapDataDb.submitForm([
                    "append", 
                    myController[2].text,
                    myController[0].text, myController[1].text,
                    zoomClipping[0], zoomClipping[1],
                    myController[2].text, "", "", "", false,
                    iconSelected + 1, myController[5].text
                  ], (response){Navigator.pop(context);});
              }else{
                setState(() {
                  buttonActive = true;
                });
              }
            }
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: button("Add Pin", Icons.add_location, loading),
          ),
        ),
      )
    ]);

    return Container(
      width: double.infinity,
      height: double.infinity,
      child: ListView(
        children: listItems,
      ),
    );
  }
}

class EditPin extends StatefulWidget {

  final List pin;

  EditPin({this.pin});

  @override
  _EditPinState createState() => _EditPinState();
}

class _EditPinState extends State<EditPin> {

  final List<TextEditingController> myController = List<TextEditingController>.generate(10, (index) => TextEditingController());
  
  @override
  void dispose() {
    myController.map((controller) {
      controller.dispose();
    });
    super.dispose();
  }

  @override
  void initState() {
    for(int i = 0; i < myController.length; i++) {
      myController[i].text = widget.pin[i + 1].toString();
    }
    super.initState();
  }

  List<bool> loading = [false, false];
  bool buttonActive = true;
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

    final double entryHeight = 60;
    final double spaceHeight = 20;

    final List<Widget> listItems = <Widget>[
      Divider(height: spaceHeight, thickness: 5,),
      ListInput(title: "Name", numberOfFields: 1, fieldNames: [""], height: entryHeight, textEditingControllers: myController.sublist(0, 1),),
      Divider(height: spaceHeight, thickness: 5,),
      ListInput(title: "Position", numberOfFields: 2, fieldNames: ["x:", "y:"], height: entryHeight, textEditingControllers: myController.sublist(1, 3),),
    ];

    if(err[0]) {listItems.addAll(errorMessage(errMessage[0], spaceHeight));}
    if(err[1]) {listItems.addAll(errorMessage(errMessage[1], spaceHeight));}
    if(err[2]) {listItems.addAll(errorMessage(errMessage[2], spaceHeight));}

    listItems.addAll(<Widget>[
      Divider(height: spaceHeight, thickness: 5,),
      ListInputHint(title: "Zoom Clipping", numberOfFields: 2, fieldNames: ["Min zoom:", "Max zoom:"], height: entryHeight, textEditingControllers: myController.sublist(3, 5), hintText: ["-inf", "inf"],),
    ]);

    if(err[3]) {listItems.addAll(errorMessage(errMessage[3], spaceHeight));}
    if(err[4]) {listItems.addAll(errorMessage(errMessage[4], spaceHeight));}

    listItems.addAll(<Widget>[
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
                if(pin != widget.pin) {
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
                    "replace", widget.pin[0],
                    myController[0].text,
                    myController[1].text, myController[2].text,
                    zoomClipping[0], zoomClipping[1],
                    myController[5].text, myController[6].text, myController[7].text, myController[8].text, myController[9].text,
                  ], (response){Navigator.pop(context);});
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
                "delete", widget.pin[0],
              ], (response){Navigator.pop(context);});
            }
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: button("Delete", Icons.delete, loading[1]),
          ),
        ),
      )
    ]);

    return Container(
      width: double.infinity,
      height: double.infinity,
      child: ListView(
        children: listItems,
      ),
    );
  }
}

class AddMapSelector extends StatefulWidget {

  @override
  _AddMapSelectorState createState() => _AddMapSelectorState();
}

class _AddMapSelectorState extends State<AddMapSelector> {

  int index = 0;

  @override
  Widget build(BuildContext context) {

    const List<NavBarOption> navBarOptions = <NavBarOption>[
      NavBarOption('Image Map', Icons.map),
      NavBarOption('Tiled Map', Icons.map),
    ];

    Widget pageSelector() {
      switch(index) {
        case 0:
          return AddMap();
        break;

        case 1:
          return AddTiledMap();
        break;

        default:
          return Container();
      }
    }

    return Container(
      width: double.infinity,
      color: Colors.white,
      child: Scaffold(
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: index,
          onTap: (_index){
            setState(() {
              index = _index;
            });
          },
          items: navBarOptions.map((NavBarOption navBarOption) {
            return BottomNavigationBarItem(
              icon: Icon(navBarOption.icon),
              title: Text(navBarOption.title)
            );
          }).toList(),
        ),
        body: pageSelector(),
      ),
    );
  }
}

class AddMap extends StatefulWidget {

  @override
  _AddMapState createState() => _AddMapState();
}

class _AddMapState extends State<AddMap> {

  final List<TextEditingController> myController = List<TextEditingController>.generate(9, (index) => TextEditingController());

  @override
  void dispose() {
    myController.map((controller) {
      controller.dispose();
    });
    super.dispose();
  }

  bool loading = false;
  bool buttonActive = true;
  List<bool> err = [false, false, false, false, false, false, false];
  List<String> errMessage = ["Position values must be numeric", "Size values must be numeric", "Position is out of range", "Size values must be positive",
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

    final double entryHeight = 60;
    final double spaceHeight = 20;

    List<Widget> listItems = <Widget>[
      Divider(height: spaceHeight, thickness: 5,),
      ListInput(title: "Name", numberOfFields: 1, fieldNames: [""], height: entryHeight, textEditingControllers: myController.sublist(5, 6),),
      Divider(height: spaceHeight, thickness: 5,),
      ListInput(title: "Position", numberOfFields: 3, fieldNames: ["x:", "y:", "z:"], height: entryHeight, textEditingControllers: myController.sublist(0, 3),),
    ];

    if(err[0]) {listItems.addAll(errorMessage(errMessage[0], spaceHeight));}
    if(err[2]) {listItems.addAll(errorMessage(errMessage[2], spaceHeight));}

    listItems.addAll(<Widget>[
      Divider(height: spaceHeight, thickness: 5,),
      ListInputHint(title: "Zoom Clipping", numberOfFields: 2, fieldNames: ["Min zoom:", "Max zoom:"], height: entryHeight, textEditingControllers: myController.sublist(7, 9), hintText: ["-inf", "inf"],),
    ]);

    if(err[4]) {listItems.addAll(errorMessage(errMessage[4], spaceHeight));}
    if(err[5]) {listItems.addAll(errorMessage(errMessage[5], spaceHeight));}

    listItems.addAll([
      Divider(height: spaceHeight, thickness: 5,),
      ListInput(title: "Size",  numberOfFields: 2, fieldNames: ["Width:", "Height:"], height: entryHeight, textEditingControllers: myController.sublist(3, 5),),
    ]);

    if(err[1]) {listItems.addAll(errorMessage(errMessage[1], spaceHeight));}
    if(err[3]) {listItems.addAll(errorMessage(errMessage[3], spaceHeight));}

    listItems.addAll([
      Divider(height: spaceHeight, thickness: 5,),
      ListInput(title: "Image", numberOfFields: 1, fieldNames: ["Link"], height: entryHeight, textEditingControllers: myController.sublist(6, 7),),
      Divider(height: spaceHeight, thickness: 5,),
      Container(
        margin: EdgeInsets.all(10),
        child: RaisedButton(
          onPressed: (){
            if(buttonActive) {
              setState(() {
                buttonActive = false;
              });
              
              if(isNumeric(myController[0].text) && isNumeric(myController[1].text) && isNumeric(myController[2].text)) {
                setState(() {err[0] = false;});
                if(0 < double.parse(myController[0].text) && double.parse(myController[0].text) < inheritedData.canvasDimensions[0] 
                && 0 < double.parse(myController[1].text) && double.parse(myController[1].text) < inheritedData.canvasDimensions[1]) {
                  setState(() {err[2] = false;});
                }else{setState(() {err[2] = true;});}
              }else{setState(() {
                err[0] = true;
                err[2] = false;
              });}
              if(isNumeric(myController[3].text) && isNumeric(myController[4].text)) {
                setState(() {err[1] = false;});
                if(0 < double.parse(myController[3].text) && 0 < double.parse(myController[4].text)) {
                  setState(() {err[3] = false;});
                }else{setState(() {err[3] = true;});}
              }else{setState(() {
                err[1] = true;
                err[3] = false;
              });}
              if((isNumeric(myController[7].text) || myController[7].text == "") && (isNumeric(myController[8].text) || myController[8].text == "")) {
                setZoomClipping(myController[7].text, myController[8].text);
                setState(() {err[4] = false;});
                if(zoomClipping[0] < zoomClipping[1]) {
                  setState(() {err[5] = false;});
                }else{setState(() {err[5] = true;});}
              }else{setState(() {
                err[4] = true;
                err[5] = false;
              });}

              if(!err.any((element) => element)) {
                loading = true;
                inheritedData.mapDb.submitForm([
                  "append", 
                  myController[5].text,
                  false,
                  myController[0].text, myController[1].text, myController[2].text,
                  zoomClipping[0], zoomClipping[1],
                  myController[3].text, myController[4].text,
                  myController[6].text,
                  "",
                ], (response){Navigator.pop(context);});
              }else{
                setState(() {
                  buttonActive = true;
                });
              }
            }
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: button("Add Map", Icons.map, loading),
          ),
        ),
      )
    ]);

    return Container(
      width: double.infinity,
      height: double.infinity,
      child: ListView(
        children: listItems
      ),
    );
  }
}

class AddTiledMap extends StatefulWidget {

  @override
  _AddTiledMapState createState() => _AddTiledMapState();
}

class _AddTiledMapState extends State<AddTiledMap> {

  final List<TextEditingController> myController = List<TextEditingController>.generate(9, (index) => TextEditingController());

  @override
  void dispose() {
    myController.map((controller) {
      controller.dispose();
    });
    super.dispose();
  }

  bool loading = false;
  bool buttonActive = true;
  List<bool> err = [false, false, false, false, false, false, false];
  List<String> errMessage = ["Position values must be numeric", "Width value must be numeric", "Position is out of range", "Width must be positive",
  "Metadata is not in valid json format", "Zoom values must be numeric", "Maximum zoom must be larger than minimum zoom"];

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

    final double entryHeight = 60;
    final double spaceHeight = 20;

    List<Widget> listItems = <Widget>[
      Divider(height: spaceHeight, thickness: 5,),
      ListInput(title: "Name", numberOfFields: 1, fieldNames: [""], height: entryHeight, textEditingControllers: myController.sublist(4, 5),),
      Divider(height: spaceHeight, thickness: 5,),
      ListInput(title: "Position", numberOfFields: 3, fieldNames: ["x:", "y:", "z:"], height: entryHeight, textEditingControllers: myController.sublist(0, 3),),
    ];

    if(err[0]) {listItems.addAll(errorMessage(errMessage[0], spaceHeight));}
    if(err[2]) {listItems.addAll(errorMessage(errMessage[2], spaceHeight));}

    listItems.addAll(<Widget>[
      Divider(height: spaceHeight, thickness: 5,),
      ListInputHint(title: "Zoom Clipping", numberOfFields: 2, fieldNames: ["Min zoom:", "Max zoom:"], height: entryHeight, textEditingControllers: myController.sublist(7, 9), hintText: ["-inf", "inf"],),
    ]);

    if(err[5]) {listItems.addAll(errorMessage(errMessage[5], spaceHeight));}
    if(err[6]) {listItems.addAll(errorMessage(errMessage[6], spaceHeight));}

    listItems.addAll([
      Divider(height: spaceHeight, thickness: 5,),
      ListInput(title: "Width",  numberOfFields: 1, fieldNames: [""], height: entryHeight, textEditingControllers: myController.sublist(3, 4),),
    ]);

    if(err[1]) {listItems.addAll(errorMessage(errMessage[1], spaceHeight));}
    if(err[3]) {listItems.addAll(errorMessage(errMessage[3], spaceHeight));}

    listItems.addAll([
      Divider(height: spaceHeight, thickness: 5,),
      ListInput(title: "Image", numberOfFields: 1, fieldNames: ["Link"], height: entryHeight, textEditingControllers: myController.sublist(5, 6),),
      Divider(height: spaceHeight, thickness: 5,),
      ListInput(title: "Metadata", numberOfFields: 1, fieldNames: [""], height: entryHeight, textEditingControllers: myController.sublist(6, 7), limitLines: false,),
    ]);

    if(err[4]) {listItems.addAll(errorMessage(errMessage[4], spaceHeight));}

    listItems.addAll([
      Divider(height: spaceHeight, thickness: 5,),
      Container(
        margin: EdgeInsets.all(10),
        child: RaisedButton(
          onPressed: (){
            if(buttonActive) {
              setState(() {
                buttonActive = false;
              });
              
              if(isNumeric(myController[0].text) && isNumeric(myController[1].text) && isNumeric(myController[2].text)) {
                setState(() {err[0] = false;});
                if(0 < double.parse(myController[0].text) && double.parse(myController[0].text) < inheritedData.canvasDimensions[0] 
                && 0 < double.parse(myController[1].text) && double.parse(myController[1].text) < inheritedData.canvasDimensions[1]) {
                  setState(() {err[2] = false;});
                }else{setState(() {err[2] = true;});}
              }else{setState(() {
                err[0] = true;
                err[2] = false;
              });}
              if(isNumeric(myController[3].text)) {
                setState(() {err[1] = false;});
                if(0 < double.parse(myController[3].text)) {
                  setState(() {err[3] = false;});
                }else{setState(() {err[3] = true;});}
              }else{setState(() {
                err[1] = true;
                err[3] = false;
              });}
              if((isNumeric(myController[7].text) || myController[7].text == "") && (isNumeric(myController[8].text) || myController[8].text == "")) {
                setZoomClipping(myController[7].text, myController[8].text);
                setState(() {err[5] = false;});
                if(zoomClipping[0] < zoomClipping[1]) {
                  setState(() {err[6] = false;});
                }else{setState(() {err[6] = true;});}
              }else{setState(() {
                err[5] = true;
                err[6] = false;
              });}

              setState(() {err[5] = false;});
              try{json.decode(myController[6].text);}
              on FormatException{setState(() {err[4] = true;});}

              if(!err.any((element) => element)) {
                loading = true;
                inheritedData.mapDb.submitForm([
                  "append", 
                  myController[4].text,
                  true,
                  myController[0].text, myController[1].text, myController[2].text,
                  zoomClipping[0], zoomClipping[1],
                  myController[3].text, "",
                  myController[5].text,
                  myController[6].text,
                ], (response){Navigator.pop(context);});
              }else{
                setState(() {
                  buttonActive = true;
                });
              }
            }
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: button("Add Map", Icons.map, loading),
          ),
        ),
      )
    ]);

    return Container(
      width: double.infinity,
      height: double.infinity,
      child: ListView(
        children: listItems
      ),
    );
  }
}

class EditMapSelector extends StatelessWidget {

  final List map;

  EditMapSelector({this.map});

  @override
  Widget build(BuildContext context) {
    if(map[2]) {
      return EditTiledMap(map: map);
    }else{
      return EditMap(map: map);
    }
  }
}

class EditMap extends StatefulWidget {

  final List map;

  EditMap({this.map});

  @override
  _EditMapState createState() => _EditMapState();
}

class _EditMapState extends State<EditMap> {

  final List<TextEditingController> myController = List<TextEditingController>.generate(9, (index) => TextEditingController());

  @override
  void dispose() {
    myController.map((controller) {
      controller.dispose();
    });
    super.dispose();
  }

  @override
  void initState() {
    List<int> conversion = [3, 4, 5, 8, 9, 1, 10, 6, 7];
    for(int i = 0; i < myController.length; i++) {
      myController[i].text = widget.map[conversion[i]].toString();
    }
    super.initState();
  }

  List<bool> loading = [false, false];
  bool buttonActive = true;
  List<bool> err = [false, false, false, false, false, false, false];
  List<String> errMessage = ["Position values must be numeric", "Size values must be numeric", "Position is out of range", "Size values must be positive",
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

    final double entryHeight = 60;
    final double spaceHeight = 20;

    List<Widget> listItems = <Widget>[
      Divider(height: spaceHeight, thickness: 5,),
      ListInput(title: "Name", numberOfFields: 1, fieldNames: [""], height: entryHeight, textEditingControllers: myController.sublist(5, 6),),
      Divider(height: spaceHeight, thickness: 5,),
      ListInput(title: "Position", numberOfFields: 3, fieldNames: ["x:", "y:", "z:"], height: entryHeight, textEditingControllers: myController.sublist(0, 3),),
    ];

    if(err[0]) {listItems.addAll(errorMessage(errMessage[0], spaceHeight));}
    if(err[2]) {listItems.addAll(errorMessage(errMessage[2], spaceHeight));}

    listItems.addAll(<Widget>[
      Divider(height: spaceHeight, thickness: 5,),
      ListInputHint(title: "Zoom Clipping", numberOfFields: 2, fieldNames: ["Min zoom:", "Max zoom:"], height: entryHeight, textEditingControllers: myController.sublist(7, 9), hintText: ["-inf", "inf"],),
    ]);

    if(err[4]) {listItems.addAll(errorMessage(errMessage[4], spaceHeight));}
    if(err[5]) {listItems.addAll(errorMessage(errMessage[5], spaceHeight));}

    listItems.addAll([
      Divider(height: spaceHeight, thickness: 5,),
      ListInput(title: "Size",  numberOfFields: 2, fieldNames: ["Width:", "Height:"], height: entryHeight, textEditingControllers: myController.sublist(3, 5),),
    ]);

    if(err[1]) {listItems.addAll(errorMessage(errMessage[1], spaceHeight));}
    if(err[3]) {listItems.addAll(errorMessage(errMessage[3], spaceHeight));}

    listItems.addAll([
      Divider(height: spaceHeight, thickness: 5,),
      ListInput(title: "Image", numberOfFields: 1, fieldNames: ["Link"], height: entryHeight, textEditingControllers: myController.sublist(6, 7),),
      Divider(height: spaceHeight, thickness: 5,),
      Container(
        margin: EdgeInsets.all(10),
        child: RaisedButton(
          onPressed: (){
            if(buttonActive) {
              setState(() {
                buttonActive = false;
              });
              
              if(isNumeric(myController[0].text) && isNumeric(myController[1].text) && isNumeric(myController[2].text)) {
                setState(() {err[0] = false;});
                if(0 < double.parse(myController[0].text) && double.parse(myController[0].text) < inheritedData.canvasDimensions[0] 
                && 0 < double.parse(myController[1].text) && double.parse(myController[1].text) < inheritedData.canvasDimensions[1]) {
                  setState(() {err[2] = false;});
                }else{setState(() {err[2] = true;});}
              }else{setState(() {
                err[0] = true;
                err[2] = false;
              });}
              if(isNumeric(myController[3].text) && isNumeric(myController[4].text)) {
                setState(() {err[1] = false;});
                if(0 < double.parse(myController[3].text) && 0 < double.parse(myController[4].text)) {
                  setState(() {err[3] = false;});
                }else{setState(() {err[3] = true;});}
              }else{setState(() {
                err[1] = true;
                err[3] = false;
              });}
              if((isNumeric(myController[7].text) || myController[7].text == "") && (isNumeric(myController[8].text) || myController[8].text == "")) {
                setZoomClipping(myController[7].text, myController[8].text);
                setState(() {err[4] = false;});
                if(zoomClipping[0] < zoomClipping[1]) {
                  setState(() {err[5] = false;});
                }else{setState(() {err[5] = true;});}
              }else{setState(() {
                err[4] = true;
                err[5] = false;
              });}

              if(!err.any((element) => element)) {
                loading[0] = true;
                inheritedData.mapDb.submitForm([
                  "replace", widget.map[0], 
                  myController[5].text,
                  false,
                  myController[0].text, myController[1].text, myController[2].text,
                  zoomClipping[0], zoomClipping[1],
                  myController[3].text, myController[4].text,
                  myController[6].text,
                  "",
                ], (response){Navigator.pop(context);});
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
              inheritedData.mapDb.submitForm([
                "delete", widget.map[0],
              ], (response){Navigator.pop(context);});
            }
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: button("Delete", Icons.delete, loading[1]),
          ),
        ),
      )
    ]);

    return Container(
      width: double.infinity,
      height: double.infinity,
      child: ListView(
        children: listItems
      ),
    );
  }
}

class EditTiledMap extends StatefulWidget {

  final List map;

  EditTiledMap({this.map});

  @override
  _EditTiledMapState createState() => _EditTiledMapState();
}

class _EditTiledMapState extends State<EditTiledMap> {

  final List<TextEditingController> myController = List<TextEditingController>.generate(9, (index) => TextEditingController());

  @override
  void dispose() {
    myController.map((controller) {
      controller.dispose();
    });
    super.dispose();
  }

  @override
  void initState() {
    List<int> conversion = [3, 4, 5, 8, 1, 10, 11, 6, 7];
    for(int i = 0; i < myController.length; i++) {
      myController[i].text = widget.map[conversion[i]].toString();
    }
    super.initState();
  }

  List<bool> loading = [false, false];
  bool buttonActive = true;
  List<bool> err = [false, false, false, false, false, false, false];
  List<String> errMessage = ["Position values must be numeric", "Width value must be numeric", "Position is out of range", "Width must be positive",
  "Metadata is not in valid json format", "Zoom values must be numeric", "Maximum zoom must be larger than minimum zoom"];

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

    final double entryHeight = 60;
    final double spaceHeight = 20;

    List<Widget> listItems = <Widget>[
      Divider(height: spaceHeight, thickness: 5,),
      ListInput(title: "Name", numberOfFields: 1, fieldNames: [""], height: entryHeight, textEditingControllers: myController.sublist(4, 5),),
      Divider(height: spaceHeight, thickness: 5,),
      ListInput(title: "Position", numberOfFields: 3, fieldNames: ["x:", "y:", "z:"], height: entryHeight, textEditingControllers: myController.sublist(0, 3),),
    ];

    if(err[0]) {listItems.addAll(errorMessage(errMessage[0], spaceHeight));}
    if(err[2]) {listItems.addAll(errorMessage(errMessage[2], spaceHeight));}

    listItems.addAll(<Widget>[
      Divider(height: spaceHeight, thickness: 5,),
      ListInputHint(title: "Zoom Clipping", numberOfFields: 2, fieldNames: ["Min zoom:", "Max zoom:"], height: entryHeight, textEditingControllers: myController.sublist(7, 9), hintText: ["-inf", "inf"],),
    ]);

    if(err[5]) {listItems.addAll(errorMessage(errMessage[5], spaceHeight));}
    if(err[6]) {listItems.addAll(errorMessage(errMessage[6], spaceHeight));}

    listItems.addAll([
      Divider(height: spaceHeight, thickness: 5,),
      ListInput(title: "Width",  numberOfFields: 1, fieldNames: [""], height: entryHeight, textEditingControllers: myController.sublist(3, 4),),
    ]);

    if(err[1]) {listItems.addAll(errorMessage(errMessage[1], spaceHeight));}
    if(err[3]) {listItems.addAll(errorMessage(errMessage[3], spaceHeight));}

    listItems.addAll([
      Divider(height: spaceHeight, thickness: 5,),
      ListInput(title: "Image", numberOfFields: 1, fieldNames: ["Link"], height: entryHeight, textEditingControllers: myController.sublist(5, 6),),
      Divider(height: spaceHeight, thickness: 5,),
      ListInput(title: "Metadata", numberOfFields: 1, fieldNames: [""], height: entryHeight, textEditingControllers: myController.sublist(6, 7), limitLines: false,),
    ]);

    if(err[4]) {listItems.addAll(errorMessage(errMessage[4], spaceHeight));}

    listItems.addAll([
      Divider(height: spaceHeight, thickness: 5,),
      Container(
        margin: EdgeInsets.all(10),
        child: RaisedButton(
          onPressed: (){
            if(buttonActive) {
              setState(() {
                buttonActive = false;
              });
              
              if(isNumeric(myController[0].text) && isNumeric(myController[1].text) && isNumeric(myController[2].text)) {
                setState(() {err[0] = false;});
                if(0 < double.parse(myController[0].text) && double.parse(myController[0].text) < inheritedData.canvasDimensions[0] 
                && 0 < double.parse(myController[1].text) && double.parse(myController[1].text) < inheritedData.canvasDimensions[1]) {
                  setState(() {err[2] = false;});
                }else{setState(() {err[2] = true;});}
              }else{setState(() {
                err[0] = true;
                err[2] = false;
              });}
              if(isNumeric(myController[3].text)) {
                setState(() {err[1] = false;});
                if(0 < double.parse(myController[3].text)) {
                  setState(() {err[3] = false;});
                }else{setState(() {err[3] = true;});}
              }else{setState(() {
                err[1] = true;
                err[3] = false;
              });}
              if((isNumeric(myController[7].text) || myController[7].text == "") && (isNumeric(myController[8].text) || myController[8].text == "")) {
                setZoomClipping(myController[7].text, myController[8].text);
                setState(() {err[5] = false;});
                if(zoomClipping[0] < zoomClipping[1]) {
                  setState(() {err[6] = false;});
                }else{setState(() {err[6] = true;});}
              }else{setState(() {
                err[5] = true;
                err[6] = false;
              });}

              setState(() {err[5] = false;});
              try{json.decode(myController[6].text);}
              on FormatException{setState(() {err[4] = true;});}

              if(!err.any((element) => element)) {
                loading[0] = true;
                inheritedData.mapDb.submitForm([
                  "replace", widget.map[0],
                  myController[4].text,
                  true,
                  myController[0].text, myController[1].text, myController[2].text,
                  zoomClipping[0], zoomClipping[1],
                  myController[3].text, "",
                  myController[5].text,
                  myController[6].text,
                ], (response){Navigator.pop(context);});
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
              inheritedData.mapDb.submitForm([
                "delete", widget.map[0],
              ], (response){Navigator.pop(context);});
            }
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: button("Delete", Icons.delete, loading[1]),
          ),
        ),
      )
    ]);

    return Container(
      width: double.infinity,
      height: double.infinity,
      child: ListView(
        children: listItems
      ),
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
        Container(width: 5, height: 1,),
        Expanded(
          child: Container(
            child: textFieldConstructor(textEditingControllers[i])
          ),
        ),
        Container(width: 5,),
      ]);
    }
    inputFields.removeLast();

    Widget content = Column(
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        Container(
          width: double.infinity,
          child: Text(title),
        ),
        limitLines ? Container(
          width: double.infinity,
          child: Container(
            alignment: Alignment.bottomCenter,
            child: Row(
              children: inputFields,
            ),
          ),
        ) : Expanded(
          child: Container(
            width: double.infinity,
            child: Container(
              alignment: Alignment.bottomCenter,
              child: Row(
                children: inputFields,
              ),
            ),
          ),
        )
      ],
    );

    return limitLines ? Container(
      margin: EdgeInsets.fromLTRB(5, 0, 5, 0),
      child: content,
    ) : Container(
      height: height * 4,
      margin: EdgeInsets.fromLTRB(5, 0, 5, 0),
      child: content,
    );
  }
}

class ListInputHint extends StatelessWidget {

  final String title;
  final int numberOfFields;
  final List<String> fieldNames;
  final List<TextEditingController> textEditingControllers;
  final double height;
  final bool limitLines;
  final List<String> hintText;

  ListInputHint({this.title = "Title", this.numberOfFields = 0, this.fieldNames = const <String>[], this.height = 40, this.textEditingControllers = const <TextEditingController>[], this.limitLines = true, this.hintText});

  final double textBoxHeightFraction = 1;

  Widget textFieldConstructor(controller, hintText) {

    if(limitLines) {
      return TextField(
        decoration: InputDecoration(hintText: hintText),
        maxLines: 1,
        controller: controller,
      );
    }else{
      return TextField(
        decoration: InputDecoration(hintText: hintText),
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
            child: textFieldConstructor(textEditingControllers[i], hintText[i])
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

class Settings extends StatefulWidget {

  final List settings;

  Settings({this.settings});

  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {

  final List<TextEditingController> myController = List<TextEditingController>.generate(9, (index) => TextEditingController());

  @override
  void dispose() {
    myController.map((controller) {
      controller.dispose();
    });
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    for(var i = 0; i < myController.length; i++) {
      myController[i].text = widget.settings[i + 1].toString();
    }
  }

  bool loading = false;
  bool buttonActive = true;
  List<bool> err = [false, false, false, false];
  List<String> errMessage = ["Canvas dimensions must be numeric", "Canvas dimensions must be positive", "Zoom limits must be numeric", "Maximum zoom must be larger than minimum zoom"];

  @override
  Widget build(BuildContext context) {

    final inheritedData = context.dependOnInheritedWidgetOfExactType<InheritedData>();

    final double entryHeight = 60;
    final double spaceHeight = 20;

    final List<Widget> listItems = <Widget>[
      Divider(height: spaceHeight, thickness: 5,),
      ListInput(title: "Canvas Dimensions", numberOfFields: 2, fieldNames: ["Width", "Height"], height: entryHeight, textEditingControllers: myController.sublist(0, 2),),
    ];

    if(err[0]) {listItems.addAll(errorMessage(errMessage[0], spaceHeight));}
    if(err[1]) {listItems.addAll(errorMessage(errMessage[1], spaceHeight));}

    listItems.addAll(<Widget>[
      Divider(height: spaceHeight, thickness: 5,),
      ListInput(title: "Canvas Units", numberOfFields: 1, fieldNames: [""], height: entryHeight, textEditingControllers: myController.sublist(2, 3),),
      Divider(height: spaceHeight, thickness: 5,),
      ListInput(title: "Zoom Limits", numberOfFields: 2, fieldNames: ["Lower", "Upper"], height: entryHeight, textEditingControllers: myController.sublist(3, 5),),
    ]);

    if(err[2]) {listItems.addAll(errorMessage(errMessage[2], spaceHeight));}
    if(err[3]) {listItems.addAll(errorMessage(errMessage[3], spaceHeight));}

    listItems.addAll(<Widget>[
      Divider(height: spaceHeight, thickness: 5,),
      ListInput(title: "App Colour", numberOfFields: 1, fieldNames: ["Hex Colour"], height: entryHeight, textEditingControllers: myController.sublist(5, 6),),
      Divider(height: spaceHeight, thickness: 5,),
      ListInput(title: "Button Colour", numberOfFields: 1, fieldNames: ["Hex Colour"], height: entryHeight, textEditingControllers: myController.sublist(6, 7),),
      Divider(height: spaceHeight, thickness: 5,),
      ListInput(title: "Background Colour", numberOfFields: 1, fieldNames: ["Hex Colour"], height: entryHeight, textEditingControllers: myController.sublist(7, 8),),
      Divider(height: spaceHeight, thickness: 5,),
      ListInput(title: "Canvas Colour", numberOfFields: 1, fieldNames: ["Hex Colour"], height: entryHeight, textEditingControllers: myController.sublist(8, 9),),
    ]);

    listItems.addAll(<Widget>[
      Divider(height: spaceHeight, thickness: 5,),
      Container(
        margin: EdgeInsets.all(10),
        child: RaisedButton(
          onPressed: (){
            if(buttonActive) {
              setState(() {
                buttonActive = false;
              });

              if(isNumeric(myController[0].text) && isNumeric(myController[1].text)) {
                setState(() {err[0] = false;});
                if(double.parse(myController[0].text) > 0 && double.parse(myController[1].text) > 0) {
                  setState(() {err[1] = false;});
                }else{setState(() {err[1] = true;});}
              }else{setState(() {
                err[0] = true;
                err[1] = false;
              });}
              if(isNumeric(myController[3].text) && isNumeric(myController[4].text)) {
                setState(() {err[2] = false;});
                if(double.parse(myController[4].text) > double.parse(myController[3].text)) {
                  setState(() {err[3] = false;});
                }else{setState(() {err[3] = true;});}
              }else{setState(() {
                err[2] = true;
                err[3] = false;
              });}

              if(!err.any((element) => element)) {
                loading = true;
                inheritedData.settingsDb.submitForm([
                    "replace", "0",
                    myController[0].text, myController[1].text, myController[2].text, myController[3].text, myController[4].text,
                    myController[5].text, myController[6].text, myController[7].text, myController[8].text,
                  ], (response){Navigator.pop(context);});
              }else{
                setState(() {
                  buttonActive = true;
                });
              }
            }
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: button("Save", Icons.save, loading),
          ),
        ),
      )
    ]);

    return Container(
      width: double.infinity,
      height: double.infinity,
      child: ListView(
        children: listItems,
      ),
    );
  }
}