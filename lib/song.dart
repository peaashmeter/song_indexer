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

  @override
  operator ==(Object other) => other is Song && other.link == link;

  @override
  int get hashCode => link.hashCode;
}
