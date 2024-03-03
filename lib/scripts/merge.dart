import 'dart:convert';
import 'dart:io';

import 'package:song_indexer/song.dart';

void main(List<String> args) async {
  final oldSongs = (File('index/songs_old.json')
          .readAsStringSync()
          .decode()['songs'] as List)
      .map((e) => Song.fromJson(jsonDecode(e)))
      .toSet();

  final newSongs =
      (File('index/songs.json').readAsStringSync().decode()['songs'] as List)
          .map((e) => Song.fromJson(jsonDecode(e)))
          .toSet();

  final union = newSongs.union(oldSongs).toList()
    ..sort(
      (a, b) => b.popularity.compareTo(a.popularity),
    );

  print(oldSongs.length);
  print(newSongs.length);
  print(union.length);

  List<String> songsJson = [];

  for (var song in union) {
    songsJson.add(jsonEncode(song));
  }

  Map<String, dynamic> json = {'songs': songsJson};
  var jsonString = jsonEncode(json);

  File jsonFile = await File('index/merge.json').create();
  await jsonFile.writeAsString(jsonString);
}

extension on String {
  dynamic decode() => jsonDecode(this);
}
