class Responsiveness {
  static final Responsiveness _instance = Responsiveness._internal();
  factory Responsiveness() {
    return _instance;
  }
  Responsiveness._internal();

  static int getCrossAxisCount(double width, int breakpoint) {
    final ratio = (width - breakpoint) / breakpoint;
    return ratio > 0 ? 1 + ratio.floor() : 1;
  }
}
