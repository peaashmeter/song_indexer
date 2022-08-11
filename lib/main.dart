import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:song_indexer/song_indexer.dart';
import 'package:song_indexer/webview.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  var indexJsonString = await rootBundle.loadString('index/songs.json');
  var savePath = (await getApplicationDocumentsDirectory()).path;
  //File songsFile = File('index/songs.json');

  //var jsonString = await songsFile.readAsString();

  runApp(SongApp(indexJsonString, savePath));
}

class SongApp extends StatefulWidget {
  final String jsonString;
  final String savePath;

  const SongApp(this.jsonString, this.savePath, {Key? key}) : super(key: key);

  @override
  State<SongApp> createState() => _SongAppState();
}

class _SongAppState extends State<SongApp> {
  List<Song> songs = [];
  bool isLoaded = false;
  int loaded = 0;
  @override
  void initState() {
    fetchDatabase().then((value) => setState(
          () {
            isLoaded = true;
            songs = value;
          },
        ));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoaded) {
      return MaterialApp(
          title: 'Сборник Песен',
          theme: ThemeData(
            primarySwatch: Colors.blue,
          ),
          home: Scaffold(
            appBar: AppBar(
              title: Text('Сборник песен'),
            ),
            body: SongList(
              songs: songs,
            ),
          ));
    } else {
      return MaterialApp(
          title: 'Сборник Песен',
          theme: ThemeData(
            primarySwatch: Colors.blue,
          ),
          home: Scaffold(
              appBar: AppBar(
                title: Text('Сборник песен'),
              ),
              body: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('Загружено песен: $loaded'),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ],
              )));
    }
  }

  Future<List<Song>> fetchDatabase() async {
    var json = jsonDecode(widget.jsonString);

    var client = HttpClient();

    List<Song> songList = [];
    for (var song in json['songs']) {
      var decoded = Song.fromJson(jsonDecode(song));
      var pathToFile = '${widget.savePath}/${decoded.link}';

      var file = File(pathToFile);

      if (file.existsSync()) {
        songList.add(decoded);
        setState(() {
          loaded++;
        });
        continue;
      } else {
        try {
          await file.create(recursive: true);
          var uri = Uri.parse('http://192.168.1.37:8081/${decoded.link}');
          var request = await client.getUrl(uri);
          var response = await request.close()
            ..pipe(File(pathToFile).openWrite());
          songList.add(decoded);
          setState(() {
            loaded++;
          });
        } catch (e) {
          setState(() {
            loaded++;
          });
        }
      }
    }

    return songList;
  }
}

class SongList extends StatefulWidget {
  final List<Song> songs;

  const SongList({super.key, required this.songs});

  @override
  State<SongList> createState() => _SongListState();
}

class _SongListState extends State<SongList> {
  late TextEditingController editingController;
  late List<Song> songs;

  @override
  void initState() {
    editingController = TextEditingController();
    songs = widget.songs;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: editingController,
            decoration: InputDecoration(
                labelText: "Поиск",
                hintText: "Поиск",
                prefixIcon: Icon(Icons.search_outlined),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(25.0)))),
            onChanged: (String query) {
              setState(() {
                songs = filterSongs(query);
              });
            },
          ),
        ),
        Expanded(
          child: ListView.separated(
              shrinkWrap: true,
              itemCount: songs.length,
              separatorBuilder: (context, index) {
                return Divider();
              },
              itemBuilder: ((context, index) {
                return SongCard(
                  name: songs[index].name,
                  artist: songs[index].artist,
                  link: songs[index].link,
                );
              })),
        ),
      ],
    );
  }

  List<Song> filterSongs(String query) {
    return List.from(widget.songs.where((song) =>
        song.artist.toLowerCase().contains(query) ||
        song.name.toLowerCase().contains(query)));
  }
}

class SongCard extends StatelessWidget {
  final String name;
  final String artist;
  final String link;

  const SongCard(
      {super.key,
      required this.name,
      required this.artist,
      required this.link});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (() async {
        var dir = (await getApplicationDocumentsDirectory()).path;
        var html = await File('$dir/$link').readAsString();
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SongView(
                html: html,
              ),
            ));
      }),
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            Text(
              name,
              style: TextStyle(fontSize: 18),
            ),
            Text(
              artist,
              style: TextStyle(fontSize: 14, color: Colors.grey[800]),
            ),
          ],
        ),
      ),
    );
  }
}
