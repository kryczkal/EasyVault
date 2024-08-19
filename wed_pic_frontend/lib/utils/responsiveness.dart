class Responsiveness {
  static final Responsiveness _instance = Responsiveness._internal();
  factory Responsiveness() {
    return _instance;
  }
  Responsiveness._internal();

  static int getCrossAxisCount(double width, int breakpoint) {
    return 1 + (width / breakpoint).floor();
  }
}
