/// A class that represents a media object in the app and database.
class Media {
  final String url;
  final String type; // "image" or "video"

  final String name;
  final String size;

  Media(
      {required this.url,
      required this.type,
      required this.name,
      required this.size});

  factory Media.fromJson(Map<String, dynamic> json) {
    return Media(
      url: json['url'],
      type: json['type'],
      name: json['name'],
      size: json['size'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'type': type,
      'name': name,
      'size': size,
    };
  }
}
