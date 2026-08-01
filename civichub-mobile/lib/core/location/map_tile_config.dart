class MapTileConfig {
  const MapTileConfig({
    required this.urlTemplate,
    required this.userAgentPackageName,
    required this.attribution,
  });

  final String urlTemplate;
  final String userAgentPackageName;
  final String attribution;

  static const openStreetMap = MapTileConfig(
    urlTemplate: String.fromEnvironment(
      'CIVICHUB_MAP_TILE_URL',
      defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    ),
    userAgentPackageName: 'com.civichub.mobile',
    attribution: 'OpenStreetMap contributors',
  );
}
