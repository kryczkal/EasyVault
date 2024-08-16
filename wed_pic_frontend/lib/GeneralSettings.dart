class GeneralSettings {
  static final GeneralSettings _instance = GeneralSettings._internal();

  factory GeneralSettings() {
    return _instance;
  }

  GeneralSettings._internal();

  final String video_asset_placeholder_path = 'images/video_fallback.png';
}
