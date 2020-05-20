import 'package:flutter/material.dart';
import 'canvas.dart';
import 'canvasWidgets.dart';
import 'dbInteraction.dart';
import 'dart:math';

class InheritedData extends InheritedWidget {

  final List mapsInfo;
  final List<Widget> maps;
  final Color mainColor;

  InheritedData({Widget child, this.mapsInfo, this.maps, this.mainColor}) : super(child: child);

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
    headers: ["Id", "x", "y", "data"]
  );

  Color mainColor = Colors.grey[500];

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {

  List mapsInfo = [];
  List<Widget> maps = <Widget>[];

  setMapData(_mapData){
    setState(() {
      mapsInfo = _mapData["data"];
      maps = mapsInfo.map((e) => Map(map: e,)).toList();
    });
  }

  @override
  void initState() {
    widget.mapDb.submitForm(["get"], setMapData);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    return InheritedData(
      mainColor: widget.mainColor,
      maps: maps,
      mapsInfo: mapsInfo,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: widget.mainColor,
          title: Text("Map"),
          centerTitle: true,
        ),
        drawer: SideBar(),
        body: Canvas(
            canvasWidth: 1000,
            canvasHeight: 900,
            buttonColor: widget.mainColor,
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

    return Stack(children: inheritedData.maps);
  }
}

class SideBar extends StatelessWidget {

  @override
  Widget build(BuildContext context) {

    final inheritedData = context.dependOnInheritedWidgetOfExactType<InheritedData>();

    List<Widget> drawerContents = [DrawerHeader(
      child: Text("Locations"),
      decoration: BoxDecoration(
        color: inheritedData.mainColor,
      ),
    ),];
    drawerContents.addAll(inheritedData.mapsInfo.map((e) => ListTile(
      leading: Icon(Icons.map),
      title: Text(e[1]),
      subtitle: Text("x: ${e[3]}, y: ${e[4]}"),
      enabled: true,
      onTap: () {
        
        Navigator.pop(context);
      },
    )).toList());

    return Container(
      width: min(200, MediaQuery.of(context).size.width),
      color: Colors.white,
      child: ListView(
        children: drawerContents,
      ),
    );
  }
}