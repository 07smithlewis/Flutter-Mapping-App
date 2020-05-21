function doGet(request) {
  var sheet = SpreadsheetApp.openById(request.parameter.spreadsheetId);
  var result = {"status": "SUCCESS"};
  var columnNames = sheet.getDataRange().offset(0, 0, 1).getValues()[0]

  try {

    var interactionType = request.parameter.interaction;

    switch(interactionType) {
        // Parameters: {"Id": Id, "Column_2": Data, "Column_3": Data, ...}
      case "append":
        if(sheet.getDataRange().offset(1, 0).getValues().map(row => row[0].toString()).indexOf(request.parameter.Id) == -1) {
          sheet.appendRow(columnNames.map(name => eval('request.parameter.' + name)));
        }else{
          result = {"status": "FAILED", "message": "Id "+ request.parameter.Id + " is already in use"};
        }
        break;

        // Parameters: {"deleteId": id}
      case "delete":
        var deleteIndex = sheet.getDataRange().offset(1, 0).getValues().map(row => row[0].toString()).indexOf(request.parameter.deleteId);
        if(deleteIndex != -1) {
          sheet.deleteRow(deleteIndex+2);
        }else{
          result = {"status": "FAILED", "message": "Id ${request.parameter.Id} does not exist"};
        }
        break;

        // Parameters: {"setId": Id, "columnName": Data_name, "value": Data_value}
      case "set":
        var index = [sheet.getDataRange().offset(1, 0).getValues().map(row => row[0].toString()).indexOf(request.parameter.setId),
                     sheet.getDataRange().offset(0, 0, 1).getValues()[0].indexOf(request.parameter.columnName)];
        if(request.parameter.columnName == "Id"){
          if(sheet.getDataRange().getValues().map(row => row[0].toString()).indexOf(request.parameter.value) != -1) {
            result = {"status": "FAILED", "message": "Id ${request.parameter.Id} already in use"};
            break;
          }
        }
        if(index[0] == -1) {
          result = {"status": "FAILED", "message": "Id does not exist"};
          break;
        }
        if(index[1] == -1) {
          result = {"status": "FAILED", "message": "columnName does not exist"};
          break;
        }
        sheet.getDataRange().offset(index[0]+1, index[1], 1, 1).setValue(request.parameter.value);
        break;

        // Parameters: {}
      case "get":
        result = {"status": "SUCCESS", "data": sheet.getDataRange().getValues().slice(1)};
        break;
    }
  } catch(exc) {
    //result = {"status": "FAILED", "message": exc};
  }

  return ContentService
  .createTextOutput(JSON.stringify(result))
  .setMimeType(ContentService.MimeType.JSON);
}