class BackendConstants {
  static final BackendConstants _instance = BackendConstants._internal();

  factory BackendConstants() {
    return _instance;
  }

  BackendConstants._internal();

  final String apiUrl =
      'https://europe-west1-careful-bridge-432408-c6.cloudfunctions.net';
  final String mediaEndpoint = '/list-bucket-files';
}
