import 'package:flutter/material.dart';
import 'canvas.dart';
import 'canvasWidgets.dart';
import 'dbInteraction.dart';
import 'dart:math';

class InheritedData extends InheritedWidget {

  final DbInteraction mapDb;
  final DbInteraction mapDataDb;
  final Function getMaps;
  final Function getMapData;
  final List<int> canvasDimensions;
  final List mapsInfo;
  final List mapDataInfo;
  final List<Widget> maps;
  final List<Widget> mapData;
  final Color mainColor;
  final List<double> setCanvasViewCoordinates;
  final double setCanvasViewWidth;
  final int changeView;
  final Function setView;
  final double appbarHeight;
  final int sidebarIndex;
  final Function setSidebarIndex;
  final List<double> screenDimensions;
  final Function setScreenDimensions;
  final double canvasZoom;
  final Function setCanvasZoom;

  InheritedData({Widget child, this.canvasDimensions, this.mapsInfo, this.mapDataInfo, this.maps, this.mapData, this.mainColor, 
  this.setCanvasViewCoordinates, this.setCanvasViewWidth, this.changeView, this.setView, this.appbarHeight, this.mapDb, 
  this.mapDataDb, this.getMaps, this.getMapData, this.sidebarIndex, this.setSidebarIndex, this.screenDimensions, 
  this.setScreenDimensions, this.canvasZoom, this.setCanvasZoom}) : super(child: child);

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) => true;
}

void main() => runApp(MaterialApp(home: Home()));

class Home extends StatefulWidget {

  final DbInteraction mapDb = new DbInteraction(
    spreadsheetId: "1KXsICI8z6WPonIavtpgruh38WMKwPvweAXT3dCx1FEg",
    headers: ["Id", "mapName", "isTiled", "x", "y", "width", "height", "link", "metadata"]
  );
  final DbInteraction mapDataDb = DbInteraction(
    spreadsheetId: "1RNbF50QzE0NDY5FSIjH8sQTrEua7FmC_joMQjr9ijSo",
    headers: ["Id", "Name", "x", "y", "data"]
  );

  Color mainColor = Colors.grey[500];

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {

  double appbarHeight = 50.0;

  List mapsInfo = [];
  List mapDataInfo = [];
  List<Widget> maps = <Widget>[];
  List<Widget> mapData = <Widget>[];

  
  void getMaps() {
    void getMapsCallback(_maps) {
      setState(() {
        mapsInfo = _maps["data"];
        maps = mapsInfo.map((e) => Map(map: e,)).toList();
        print(maps);
      });
    }
    widget.mapDb.submitForm(["get"], getMapsCallback);
  }
  void getMapData() {
    void getMapData(_mapData) {
      setState(() {
        mapDataInfo = _mapData["data"];
        mapData = mapDataInfo.map((e) => MapPin(pin: e,)).toList();
      });
    }
    widget.mapDataDb.submitForm(["get"], getMapData);
  }

  @override
  void initState() {
    getMaps();
    getMapData();
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

  List<int> canvasDimensions = [1000, 800];
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

  @override
  Widget build(BuildContext context) {

    return InheritedData(
      getMaps: getMaps,
      getMapData: getMapData,
      mapDb: widget.mapDb,
      mapDataDb: widget.mapDataDb,
      canvasDimensions: canvasDimensions,
      mainColor: widget.mainColor,
      maps: maps,
      mapsInfo: mapsInfo,
      mapData: mapData,
      mapDataInfo: mapDataInfo,
      setCanvasViewCoordinates: setCanvasViewCoordinates,
      setCanvasViewWidth: setCanvasViewWidth,
      changeView: changeView,
      setView: setView,
      appbarHeight: appbarHeight,
      sidebarIndex: sidebarIndex,
      setSidebarIndex: setSidebarIndex,
      screenDimensions: screenDimensions,
      setScreenDimensions: setScreenDimensions,
      canvasZoom: canvasZoom,
      setCanvasZoom: setCanvasZoom,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(appbarHeight),
          child: AppBar(
            backgroundColor: widget.mainColor,
            title: Text("Map"),
            centerTitle: true,
          ),
        ),
        drawer: SideBar(),
        body: Canvas(
          canvasWidth: canvasDimensions[0],
          canvasHeight: canvasDimensions[1],
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
    final canvas = context.dependOnInheritedWidgetOfExactType<InheritedCanvas>();

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
    ];

    Widget pageSelector() {
      switch(inheritedData.sidebarIndex) {
        case 0:
          return MapNavigation();
        break;

        case 1:
          return AddMap();
        break;

        case 2:
          return AddPin();
        break;

        default:
          return Container();
      }
    }

    return Container(
      width: min(250, MediaQuery.of(context).size.width),
      color: Colors.white,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(inheritedData.appbarHeight),
          child: AppBar(
            backgroundColor: inheritedData.mainColor,
            title: Text("Tools"),
            centerTitle: true,
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
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

class MapNavigation extends StatelessWidget {

  @override
  Widget build(BuildContext context) {

    final inheritedData = context.dependOnInheritedWidgetOfExactType<InheritedData>();

    List<Widget> drawerContents = [ListTile(
      leading: Icon(Icons.home),
      title: Text("Canvas"),
      onTap: () {
        inheritedData.setView(<double>[0, inheritedData.canvasDimensions[1].toDouble()], inheritedData.canvasDimensions[0]);
        Navigator.pop(context);
      },
    )];
    drawerContents.add(Divider(
      height: 10,
      thickness: 5,
    ));
    drawerContents.addAll(inheritedData.mapsInfo.map((e) => ListTile(
      leading: Icon(Icons.map),
      title: Text(e[1]),
      subtitle: Text("x: ${e[3]}, y: ${e[4]}"),
      enabled: true,
      onTap: () {
        inheritedData.setView(<double>[e[3], e[4]], e[5]);
        Navigator.pop(context);
      },
    )).toList());
    drawerContents.add(Divider(
      height: 10,
      thickness: 5,
    ));
    drawerContents.addAll(inheritedData.mapDataInfo.map((e) => ListTile(
      leading: Icon(Icons.pin_drop),
      title: Text(e[1]),
      subtitle: Text("x: ${e[2]}, y: ${e[3]}"),
      enabled: true,
      onTap: () {
        inheritedData.setView(<double>[e[2] - inheritedData.canvasDimensions[0] / 2, 
        e[3] + inheritedData.screenDimensions[1] / 2 * (inheritedData.canvasDimensions[0] / inheritedData.screenDimensions[0])], 
        inheritedData.canvasDimensions[0]);
        Navigator.pop(context);
      },
    )).toList());

    return ListView(
      children: drawerContents,
    );
  }
}

class AddPin extends StatefulWidget {

  @override
  _AddPinState createState() => _AddPinState();
}

class _AddPinState extends State<AddPin> {

  final List<TextEditingController> myController = List<TextEditingController>.generate(3, (index) => TextEditingController());

  @override
  void dispose() {
    myController.map((controller) {
      controller.dispose();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final inheritedData = context.dependOnInheritedWidgetOfExactType<InheritedData>();

    final double entryHeight = 60;
    final double spaceHeight = 20;

    return Container(
      width: double.infinity,
      height: double.infinity,
      child: ListView(
        children: <Widget>[
          Divider(height: spaceHeight, thickness: 5,),
          ListInput(title: "Position", numberOfFields: 2, fieldNames: ["x:", "y:"], height: entryHeight, textEditingControllers: myController.sublist(0, 2),),
          Divider(height: spaceHeight, thickness: 5,),
          ListInput(title: "Name", numberOfFields: 1, fieldNames: [""], height: entryHeight, textEditingControllers: myController.sublist(2),),
          Divider(height: spaceHeight, thickness: 5,),
          Container(
            margin: EdgeInsets.all(10),
            child: RaisedButton(
              onPressed: (){
                inheritedData.mapDataDb.submitForm([
                  "append", 
                  (double.parse(myController[0].text)*100).toInt().toString() + (double.parse(myController[1].text)*100).toInt().toString(),
                  myController[2].text,
                  myController[0].text, myController[1].text,
                  "",
                ], (response){
                  inheritedData.getMapData();
                });
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(Icons.add_location),
                  Text("Add Pin")
                ],),
            ),
          )
        ],
      ),
    );
  }
}

class AddMap extends StatefulWidget {

  @override
  _AddMapState createState() => _AddMapState();
}

class _AddMapState extends State<AddMap> {

  final List<TextEditingController> myController = List<TextEditingController>.generate(6, (index) => TextEditingController());

  @override
  void dispose() {
    myController.map((controller) {
      controller.dispose();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final inheritedData = context.dependOnInheritedWidgetOfExactType<InheritedData>();

    final double entryHeight = 60;
    final double spaceHeight = 20;

    return Container(
      width: double.infinity,
      height: double.infinity,
      child: ListView(
        children: <Widget>[
          Divider(height: spaceHeight, thickness: 5,),
          ListInput(title: "Position", numberOfFields: 2, fieldNames: ["x:", "y:"], height: entryHeight, textEditingControllers: myController.sublist(0, 2),),
          Divider(height: spaceHeight, thickness: 5,),
          ListInput(title: "Size",  numberOfFields: 2, fieldNames: ["Width:", "Height:"], height: entryHeight, textEditingControllers: myController.sublist(2, 4),),
          Divider(height: spaceHeight, thickness: 5,),
          ListInput(title: "Name", numberOfFields: 1, fieldNames: [""], height: entryHeight, textEditingControllers: myController.sublist(4, 5),),
          Divider(height: spaceHeight, thickness: 5,),
          ListInput(title: "Image", numberOfFields: 1, fieldNames: ["Link"], height: entryHeight, textEditingControllers: myController.sublist(5, 6),),
          Divider(height: spaceHeight, thickness: 5,),
          Container(
            margin: EdgeInsets.all(10),
            child: RaisedButton(
              onPressed: (){
                inheritedData.mapDb.submitForm([
                  "append", 
                  (double.parse(myController[0].text)*100).toInt().toString() + (double.parse(myController[1].text)*100).toInt().toString(),
                  myController[4].text,
                  false,
                  myController[0].text, myController[1].text,
                  myController[2].text, myController[3].text,
                  myController[5].text,
                  "",
                ], (response){
                  inheritedData.getMaps();
                });
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(Icons.map),
                  Text("Add Map")
                ],),
            ),
          )
        ],
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

  ListInput({this.title = "Title", this.numberOfFields = 0, this.fieldNames = const <String>[], this.height = 40, this.textEditingControllers = const <TextEditingController>[],});

  final double textBoxHeightFraction = 1;

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
            child: TextField(
              maxLines: 1,
              controller: textEditingControllers[i],
            ),
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