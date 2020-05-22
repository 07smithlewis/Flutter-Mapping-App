import 'dart:convert' as convert;
import 'package:http/http.dart' as http;

class DbInteraction {

  final String url = "https://script.google.com/macros/s/AKfycbz_HQofDFza9w2V_obgCabKSqSnnrPdwI3bM2QYtT7icta8iQsh/exec";
  final String spreadsheetId;
  final List<String> headers;

  DbInteraction({this.spreadsheetId, this.headers});

  String urlParams(List p) {
    switch(p[0]) {

      case "append": {
        if(p.length - 1 == headers.length){
          String paramString = "?spreadsheetId=$spreadsheetId&interaction=${p[0]}";
          for(var i = 0; i < headers.length; i++){
            paramString += "&" + headers[i] + "=${p[i + 1]}";
          }
          return paramString;
        }else{
          print("Invalid number of arguments");
          return "";
        }
      }
      break;

      case "delete": {
        return "?spreadsheetId=$spreadsheetId&interaction=${p[0]}&deleteId=${p[1]}";
      }
      break;

      case "set": {
        return "?spreadsheetId=$spreadsheetId&interaction=${p[0]}&setId=${p[1]}&columnName=${p[2]}&value=${p[3]}";
      }
      break;

      case "replace": {
        if(p.length - 2 == headers.length){
          String paramString = "?spreadsheetId=$spreadsheetId&interaction=${p[0]}&replaceId=${p[1]}";
          for(var i = 0; i < headers.length; i++){
            paramString += "&" + headers[i] + "=${p[i + 2]}";
          }
          return paramString;
        }else{
          print("Invalid number of arguments");
          return "";
        }
      }
      break;

      case "get": {
        return "?spreadsheetId=$spreadsheetId&interaction=${p[0]}";
      }
      break;

      default: { 
        print("Invalid Operation");
        return "";
      }
    }
  }

  void submitForm(List interactionParameters, Function callback) async {
    try {
      await http.get(
        url + this.urlParams(interactionParameters)
      ).then((response){
        callback(convert.jsonDecode(response.body));
        print(response.body);
      });
    } catch (e) {
      print(e);
    }
  }
}

