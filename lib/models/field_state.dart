class FieldState {
  String zone;
  bool zoneEx;
  String terrain;
  bool terrainEx;
  String weather;
  bool weatherEx;
  int targetCount;

  FieldState({
    this.zone = '',
    this.zoneEx = false,
    this.terrain = '',
    this.terrainEx = false,
    this.weather = '',
    this.weatherEx = false,
    this.targetCount = 3,
  });
}
