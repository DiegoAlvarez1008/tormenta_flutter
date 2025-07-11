class BLEStateController {
  static final BLEStateController _instance = BLEStateController._internal();

  factory BLEStateController() {
    return _instance;
  }

  BLEStateController._internal();

  bool bleActivo = false;
}
