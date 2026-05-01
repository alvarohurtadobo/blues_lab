import 'package:flutter/material.dart';

import 'package:blues_lab/domain/value_objects/sync_grid_tile_style.dart';

/// Fill and stroke colors per [SyncGridTileStyleClass] from compiled site CSS
/// variables (`--bs-tile-*`).
class SyncGridTilePalette {
  SyncGridTilePalette._();

  static const Color stat = Color(0xFF568DD0);
  static const Color learn = Color(0xFF6AD3F3);
  static const Color powerup = Color(0xFF4AB797);
  static const Color sync = Color(0xFF8974C3);
  static const Color dmax = Color(0xFFE17DB9);
  static const Color modifier = Color(0xFFE1768A);
  static const Color passive = Color(0xFFE5CE5E);
  static const Color arc = Color(0xFFFFF4BC);

  static Color fill(SyncGridTileStyleClass c) {
    switch (c) {
      case SyncGridTileStyleClass.stat:
        return stat;
      case SyncGridTileStyleClass.learn:
        return learn;
      case SyncGridTileStyleClass.powerup:
        return powerup;
      case SyncGridTileStyleClass.sync:
        return sync;
      case SyncGridTileStyleClass.dmax:
        return dmax;
      case SyncGridTileStyleClass.modifier:
        return modifier;
      case SyncGridTileStyleClass.passive:
        return passive;
      case SyncGridTileStyleClass.arc:
        return arc;
    }
  }

  static Color dark(SyncGridTileStyleClass c) {
    switch (c) {
      case SyncGridTileStyleClass.stat:
        return const Color(0xFF18529C);
      case SyncGridTileStyleClass.learn:
        return const Color(0xFF2DA6B7);
      case SyncGridTileStyleClass.powerup:
        return const Color(0xFF056E50);
      case SyncGridTileStyleClass.sync:
        return const Color(0xFF432D7F);
      case SyncGridTileStyleClass.dmax:
        return const Color(0xFFA6186C);
      case SyncGridTileStyleClass.modifier:
        return const Color(0xFFA7364A);
      case SyncGridTileStyleClass.passive:
        return const Color(0xFF907500);
      case SyncGridTileStyleClass.arc:
        return const Color(0xFF7D765A);
    }
  }
}
