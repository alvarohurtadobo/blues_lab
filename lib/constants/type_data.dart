import 'package:flutter/material.dart';

const typeColors = <String, Color>{
  'normal': Color(0xFFA8A878),
  'fire': Color(0xFFF08030),
  'water': Color(0xFF6890F0),
  'grass': Color(0xFF78C850),
  'electric': Color(0xFFF8D030),
  'ice': Color(0xFF98D8D8),
  'fighting': Color(0xFFC03028),
  'poison': Color(0xFFA040A0),
  'ground': Color(0xFFE0C068),
  'flying': Color(0xFFA890F0),
  'psychic': Color(0xFFF85888),
  'bug': Color(0xFFA8B820),
  'rock': Color(0xFFB8A038),
  'ghost': Color(0xFF705898),
  'dragon': Color(0xFF7038F8),
  'dark': Color(0xFF705848),
  'steel': Color(0xFFB8B8D0),
  'fairy': Color(0xFFEE99AC),
  'stellar': Color(0xFF40B5A5),
};

const typeIcons = <String, String>{
  'normal': 'assets/img/battle/TYPE_001.png',
  'fire': 'assets/img/battle/TYPE_002.png',
  'water': 'assets/img/battle/TYPE_003.png',
  'electric': 'assets/img/battle/TYPE_004.png',
  'grass': 'assets/img/battle/TYPE_005.png',
  'ice': 'assets/img/battle/TYPE_006.png',
  'fighting': 'assets/img/battle/TYPE_007.png',
  'poison': 'assets/img/battle/TYPE_008.png',
  'ground': 'assets/img/battle/TYPE_009.png',
  'flying': 'assets/img/battle/TYPE_010.png',
  'psychic': 'assets/img/battle/TYPE_011.png',
  'bug': 'assets/img/battle/TYPE_012.png',
  'rock': 'assets/img/battle/TYPE_013.png',
  'ghost': 'assets/img/battle/TYPE_014.png',
  'dragon': 'assets/img/battle/TYPE_015.png',
  'dark': 'assets/img/battle/TYPE_016.png',
  'steel': 'assets/img/battle/TYPE_017.png',
  'fairy': 'assets/img/battle/TYPE_018.png',
  'stellar': 'assets/img/battle/TYPE_099.png',
};

const zoneOptions = [
  '',
  'Normal Zone',
  'Ice Zone',
  'Fighting Zone',
  'Poison Zone',
  'Ground Zone',
  'Flying Zone',
  'Bug Zone',
  'Rock Zone',
  'Ghost Zone',
  'Dragon Zone',
  'Dark Zone',
  'Steel Zone',
  'Fairy Zone',
];

const terrainOptions = [
  '',
  'Electric Terrain',
  'Psychic Terrain',
  'Grassy Terrain',
];

const weatherOptions = ['', 'Sunny', 'Rainy', 'Hail', 'Sandstorm'];

const zoneBoostType = {
  'Normal Zone': 'Normal',
  'Ice Zone': 'Ice',
  'Fighting Zone': 'Fighting',
  'Poison Zone': 'Poison',
  'Ground Zone': 'Ground',
  'Flying Zone': 'Flying',
  'Bug Zone': 'Bug',
  'Rock Zone': 'Rock',
  'Ghost Zone': 'Ghost',
  'Dragon Zone': 'Dragon',
  'Dark Zone': 'Dark',
  'Steel Zone': 'Steel',
  'Fairy Zone': 'Fairy',
};

const terrainBoostType = {
  'Electric Terrain': 'Electric',
  'Psychic Terrain': 'Psychic',
  'Grassy Terrain': 'Grass',
};

const weatherBoostType = {'Sunny': 'Fire', 'Rainy': 'Water'};

const fieldEffectIcons = <String, IconData>{
  '': Icons.block,
  'Normal Zone': Icons.circle,
  'Ice Zone': Icons.ac_unit,
  'Fighting Zone': Icons.sports_mma,
  'Poison Zone': Icons.science,
  'Ground Zone': Icons.terrain,
  'Flying Zone': Icons.flight,
  'Bug Zone': Icons.bug_report,
  'Rock Zone': Icons.landscape,
  'Ghost Zone': Icons.visibility_off,
  'Dragon Zone': Icons.whatshot,
  'Dark Zone': Icons.dark_mode,
  'Steel Zone': Icons.construction,
  'Fairy Zone': Icons.auto_awesome,
  'Electric Terrain': Icons.flash_on,
  'Psychic Terrain': Icons.psychology,
  'Grassy Terrain': Icons.grass,
  'Sunny': Icons.wb_sunny,
  'Rainy': Icons.grain,
  'Hail': Icons.ac_unit,
  'Sandstorm': Icons.filter_drama,
};

const statusLabels = {
  'burned': '🔥 Burned',
  'paralyzed': '⚡ Paralyzed',
  'frozen': '🧊 Frozen',
  'asleep': '💤 Asleep',
  'poisoned': '☠️ Poisoned',
  'badly poisoned': '☠️ Badly Pois.',
  'confused': '💫 Confused',
  'flinching': '😵 Flinching',
  'trapped': '🕸️ Trapped',
  'restrained': '⛓️ Restrained',
};

const statusColors = {
  'burned': Color(0xFFE74C3C),
  'paralyzed': Color(0xFFF39C12),
  'frozen': Color(0xFF3498DB),
  'asleep': Color(0xFF8E44AD),
  'poisoned': Color(0xFF9B59B6),
  'badly poisoned': Color(0xFF6C3483),
  'confused': Color(0xFFE91E63),
  'flinching': Color(0xFF795548),
  'trapped': Color(0xFF607D8B),
  'restrained': Color(0xFF455A64),
};

String statusLabel(String key) => statusLabels[key] ?? key;
Color statusColor(String key) => statusColors[key] ?? Colors.grey;
Color typeColor(String type) => typeColors[type.toLowerCase()] ?? Colors.grey;

const allTypes = [
  '',
  'Normal',
  'Fire',
  'Water',
  'Grass',
  'Electric',
  'Ice',
  'Fighting',
  'Poison',
  'Ground',
  'Flying',
  'Psychic',
  'Bug',
  'Rock',
  'Ghost',
  'Dragon',
  'Dark',
  'Steel',
  'Fairy',
];

const weaknessTypes = [
  '',
  'Fire',
  'Water',
  'Grass',
  'Electric',
  'Ice',
  'Fighting',
  'Poison',
  'Ground',
  'Flying',
  'Psychic',
  'Bug',
  'Rock',
  'Ghost',
  'Dragon',
  'Dark',
  'Steel',
  'Fairy',
];
