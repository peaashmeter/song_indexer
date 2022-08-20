import 'dart:convert';
import 'dart:io';
import 'package:html/parser.dart';

void main(List<String> arguments) async {
  Map<String, int> songsByPopularity = {};

  var dir = Directory('artists');
  await for (var artist in dir.list()) {
    try {
      var html = await (artist as File).readAsString();
      var document = parse(html);

      var table = document.getElementById('tablesort');
      var rows = table!.getElementsByTagName('tr');
      for (var r in rows.getRange(1, rows.length)) {
        var columns = r.getElementsByTagName('td');
        songsByPopularity.addAll({
          columns[0].children[0].attributes['href']!.replaceAll('../', ''):
              int.parse(columns[2].text.replaceAll(',', ''))
        });
      }
    } catch (e) {
      print(e);
      continue;
    }
  }

  var sorted = songsByPopularity.entries.toList()
    ..sort(((a, b) => b.value.compareTo(a.value)));

  songsByPopularity = Map.fromEntries(sorted);

  List<Song> songs = [];

  for (var e in songsByPopularity.entries) {
    try {
      var song = File(e.key);
      var html = await song.readAsString();
      var document = parse(html);

      var name = document.querySelector('[itemprop=name]')?.text;
      var artist = document.querySelector('[itemprop=byArtist]')?.text;

      var link = song.path;

      songs.add(Song(name ?? '', artist ?? '', link, e.value));

      print('Обработано песен: ${songs.length}');
    } catch (e) {
      continue;
    }
  }

  List<String> songsJson = [];

  for (var song in songs) {
    songsJson.add(jsonEncode(song));
  }
  Map<String, dynamic> json = {'songs': songsJson};
  var jsonString = jsonEncode(json);

  File jsonFile = await File('songs.json').create();
  await jsonFile.writeAsString(jsonString);
}

class Song {
  final String name;
  final String artist;
  final String link;
  final int popularity;

  Song(this.name, this.artist, this.link, this.popularity);

  Song.fromJson(Map<String, dynamic> json)
      : this(json['name'], json['artist'], json['link'].replaceAll('\\', '/'),
            json['pop']);

  Map<String, dynamic> toJson() => {
        'name': name,
        'artist': artist,
        'link': link.replaceAll('\\', '/'),
        'pop': popularity
      };
}
