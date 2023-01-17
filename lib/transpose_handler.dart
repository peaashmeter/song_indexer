import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class TransposeDataHandler {
  Future<Map<String, int>> getTranspositionMap() async {
    var path = (await getApplicationDocumentsDirectory()).path;
    var file = await File('$path/transpose_map.json').create();
    var content = await file.readAsString();
    if (content != '') {
      var map = Map<String, int>.from(jsonDecode(content));
      return map;
    }
    return {};
  }

  void _writeTranspositionMap(Map<String, int> map) async {
    var json = jsonEncode(map);
    var path = (await getApplicationDocumentsDirectory()).path;
    await File('$path/transpose_map.json').writeAsString(json);
  }

  void addTransposition(String path, int tranposition) async {
    var map = await getTranspositionMap();
    map[path] = tranposition;
    _writeTranspositionMap(map);
  }
}
