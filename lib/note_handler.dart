import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class NotesDataHandler {
  Future<Map<String, String>> getNotesMap() async {
    var path = (await getApplicationDocumentsDirectory()).path;
    var file = await File('$path/notes_map.json').create();
    var content = await file.readAsString();
    if (content != '') {
      var map = Map<String, String>.from(jsonDecode(content));
      return map;
    }
    return {};
  }

  void _writeNotesMap(Map<String, String> map) async {
    var json = jsonEncode(map);
    var path = (await getApplicationDocumentsDirectory()).path;
    await File('$path/notes_map.json').writeAsString(json);
  }

  void setNote(String path, String note) async {
    var map = await getNotesMap();
    map[path] = note;
    _writeNotesMap(map);
  }
}
