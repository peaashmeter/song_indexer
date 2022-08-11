import 'dart:convert';
import 'dart:io';
import 'package:html/parser.dart';

void main(List<String> arguments) async {
  List<Song> songs = [];

  var dir = Directory('songs');
  await for (var artist in dir.list()) {
    if (artist is Directory) {
      await for (var song in artist.list()) {
        if (song is File) {
          try {
            var html = await song.readAsString();
            var document = parse(html);

            var name = document.querySelector('[itemprop=name]')?.text;
            var artist = document.querySelector('[itemprop=byArtist]')?.text;

            var link = song.path;

            songs.add(Song(name ?? '', artist ?? '', link));
          } catch (e) {
            print(e);
          }
        }
      }
      print('проиндексирован исполнитель ${artist.path}');
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

  Song(this.name, this.artist, this.link);

  Song.fromJson(Map<String, dynamic> json)
      : this(json['name'], json['artist'], json['link'].replaceAll('\\', '/'));

  Map<String, dynamic> toJson() =>
      {'name': name, 'artist': artist, 'link': link};
}
