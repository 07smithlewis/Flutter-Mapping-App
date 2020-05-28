function doGet(request) {
  var sheet = SpreadsheetApp.openById(request.parameter.spreadsheetId);
  var result = {"status": "SUCCESS"};
  var data = sheet.getDataRange().getValues();
  
  try {
    
    var interactionType = request.parameter.interaction;
    
    switch(interactionType) {
        // Parameters: {"Id": Id, "Column_2": Data, "Column_3": Data, ...}
      case "append":
        var index = 0;
        while(data.slice(1).map(row => row[0]).indexOf(index) != -1) {
          index++;
        }
        var newRow = data[0].slice(1).map(name => eval('request.parameter.' + name));
        newRow.unshift(index);
        sheet.appendRow(newRow);
        break;
        
        // Parameters: {"deleteId": id}
      case "delete":
        var deleteIndex = data.slice(1).map(row => row[0].toString()).indexOf(request.parameter.deleteId);
        if(deleteIndex != -1) {
          sheet.deleteRow(deleteIndex+2);
        }else{
          result = {"status": "FAILED", "message": "Id ${request.parameter.Id} does not exist"};
        }
        break;
        
        // Parameters: {"setId": Id, "columnName": Data_name, "value": Data_value}
      case "set":
        var index = [data.slice(1).map(row => row[0].toString()).indexOf(request.parameter.setId),
                     data[0].indexOf(request.parameter.columnName)];
        if(request.parameter.columnName == "Id"){
          if(data.slice(1).map(row => row[0].toString()).indexOf(request.parameter.value) != -1) {
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
      
      // Parameters: {"replaceId": Id, "Column_2": Data, "Column_3": Data, ...}
      case "replace":
        var replacementRow = [data[0].slice(1).map(name => eval('request.parameter.' + name)),];
        var index = data.slice(1).map(row => row[0].toString()).indexOf(request.parameter.replaceId);
        if(index == -1) {
          result = {"status": "FAILED", "message": "Id does not exist"};
          break;
        }
        sheet.getDataRange().offset(index+1, 1, 1, replacementRow[0].length).setValues(replacementRow);
        break;
      
        // Parameters: {}
      case "get":
        result = {"status": "SUCCESS", "data": data.slice(1)};
        break;
    }
  } catch(exc) {
    // result = {"status": "FAILED", "message": exc};
  }
  
  return ContentService
  .createTextOutput(JSON.stringify(result))
  .setMimeType(ContentService.MimeType.JSON);  
}