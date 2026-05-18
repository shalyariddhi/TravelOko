import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

/// Returns a [TileLayer] backed by FMTC's offline cache.
/// Tiles viewed online are stored automatically and served offline.
TileLayer cachedTileLayer() {
  return TileLayer(
    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    userAgentPackageName: 'com.travel.loco',
    tileProvider: FMTCTileProvider(
      stores: const {'osmTiles': BrowseStoreStrategy.readUpdateCreate},
      loadingStrategy: BrowseLoadingStrategy.cacheFirst,
    ),
  );
}
