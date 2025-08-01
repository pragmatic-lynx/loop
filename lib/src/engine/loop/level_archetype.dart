/// Defines the three types of levels in the loop system
enum LevelArchetype {
  combat('COMBAT'),
  loot('LOOT'),
  boss('BOSS');

  const LevelArchetype(this.name);
  final String name;

  @override
  String toString() => name;
}