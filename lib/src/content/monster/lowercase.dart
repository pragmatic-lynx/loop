import 'package:malison/malison.dart';

import '../../engine.dart';
import '../../hues.dart';
import '../action/missive.dart';
import '../elements.dart';
import '../tiles.dart';
import 'builder.dart';

// TODO: Describe other monsters.
void arachnids() {
  // TODO: Should all spiders hide in passages?
  family("a", flags: "fearless")
    ..groups("spider")
    ..sense(see: 4, hear: 2)
    ..stain(Tiles.spiderweb);
  breed("lesser hell spider", 3, tan, 2, dodge: 30, meander: 40)
      .attack("bite[s]", 5, Elements.poison);
  describe("Seems harmless enough. What's that dripping from its pedipalps?");

  breed("gray hell spider", 7, coolGray, 20, dodge: 30, meander: 30)
      .attack("bite[s]", 5, Elements.poison);

  breed("hell spawn", 9, ash, 14, dodge: 35, meander: 50)
    ..count(2, 7)
    ..attack("bite[s]", 10, Elements.poison);

  breed("hell spider", 12, darkBlue, 40, meander: 30)
      .attack("bite[s]", 7, Elements.poison);
  describe("""Like a large dog, if the dog had eight articulated legs, eight
  glittering eyes, and wanted nothing more than to kill you.""");
}

void bats() {
  family("b", speed: 1)
    ..groups("bat")
    ..sense(see: 2, hear: 8)
    ..fly()
    ..preferOpen();
  breed("lesser imp", 1, tan, 4, frequency: 0.5, meander: 50)
    ..defense(20, "{1} flits out of the way.")
    ..count(2, 4)
    ..attack("bite[s]", 3);

  breed("imp", 4, brown, 24, meander: 30).attack("bite[s]", 6);

  breed("cave imp", 6, lightCoolGray, 30, meander: 40)
    ..defense(20, "{1} flits out of the way.")
    ..count(2, 5)
    ..attack("bite[s]", 6);
}

void canines() {
  family("c", dodge: 25, tracking: 20, meander: 25)
    ..groups("canine")
    ..sense(see: 5, hear: 10);

  breed("hell pup", 2, buttermilk, 11)
    ..count(4)
    ..attack("bite[s]", 4)
    ..howl(range: 6);

  breed("hellhound", 4, lightCoolGray, 20)
    ..count(4)
    ..attack("bite[s]", 6)
    ..howl(range: 8);

  breed("feral hellhound", 7, carrot, 28)
    ..count(2, 5)
    ..attack("bite[s]", 8)
    ..howl();

  breed("dire hellhound", 26, ash, 60)
    ..count(3, 6)
    ..attack("bite[s]", 12)
    ..howl();

  breed("greater hellhound", 30, coolGray, 80)
    ..count(2, 6)
    ..attack("bite[s]", 16)
    ..howl();

  // TODO: Drops.
  breed("Skoll", 36, gold, 200)
    ..unique()
    ..minion("canine", 5, 9)
    ..attack("bite[s]", 20)
    ..howl();

  breed("Hati", 40, blue, 250)
    ..unique()
    ..minion("canine", 5, 9)
    ..attack("bite[s]", 23)
    ..howl();

  breed("Fenrir", 44, darkCoolGray, 300)
    ..unique()
    ..minion("canine", 3, 5)
    ..minion("Skoll")
    ..minion("Hati")
    ..attack("bite[s]", 26)
    ..howl();
}

void dragons() {
  // TODO: Tune. Give more attacks. Tune drops.
  // TODO: Juvenile and elder dragons.
  // TODO: Minions?
  var dragons = {
    "hell": [Element.none, peaGreen, sherwood],
    "earth hell": [Elements.earth, sandal, tan],
    "frost hell": [Elements.water, lightBlue, blue],
    "ice hell": [Elements.cold, lightCoolGray, ash],
    "poison hell": [Elements.poison, lilac, purple],
    "acid hell": [Elements.acid, lima, olive],
    "storm hell": [Elements.lightning, lightAqua, lightBlue],
    "fire hell": [Elements.fire, pink, red],
    "light hell": [Elements.light, buttermilk, gold],
    "shadow hell": [Elements.dark, coolGray, darkCoolGray],
    "spirit hell": [Elements.spirit, aqua, darkBlue]
  };

  var i = 0;
  dragons.forEach((name, data) {
    var element = data[0] as Element;
    var youngColor = data[1] as Color;
    var adultColor = data[1] as Color;

    family("d")
      ..groups("dragon")
      ..sense(see: 12, hear: 8)
      ..defense(10, "{2} [are|is] deflected by its scales.")
      ..preferOpen();

    var dragon =
        breed("juvenile $name dragon", 46 + i * 2, youngColor, 150 + i * 20)
          ..attack("bite[s]", 20 + i * 2)
          ..attack("claw[s]", 15 + i)
          ..drop("treasure", count: 2 + i ~/ 2)
          ..drop("magic")
          ..drop("equipment");

    if (element != Element.none) {
      dragon.cone(element, rate: 11, damage: 40 + i * 6, range: 5);
    }

    family("d")
      ..groups("dragon")
      ..sense(see: 16, hear: 10)
      ..defense(20, "{2} [are|is] deflected by its scales.")
      ..preferOpen();

    dragon = breed("$name dragon", 50 + i * 2, adultColor, 350 + i * 50)
      ..attack("bite[s]", 30 + i * 2)
      ..attack("claw[s]", 25 + i)
      ..drop("treasure", count: 5 + i ~/ 2)
      ..drop("magic", count: 3 + i ~/ 3)
      ..drop("equipment", count: 2 + i ~/ 3);

    if (element != Element.none) {
      dragon.cone(element, rate: 8, damage: 70 + i * 8);
    }

    i++;
  });
}

void eyes() {
  family("e", flags: "immobile")
    ..groups("eye")
    ..sense(see: 16, hear: 1)
    ..defense(10, "{1} blinks out of the way.")
    ..fly()
    ..preferOpen();

  breed("watching eye", 5, lightBlue, 20)
    ..attack("stare[s] at", 8)
    ..sparkBolt(rate: 5, damage: 12, range: 8);

  breed("demon eye", 9, pink, 40)
    ..attack("stare[s] at", 8)
    ..windBolt(rate: 6, damage: 15);

  breed("floating demon eye", 15, buttermilk, 60)
    ..attack("stare[s] at", 10)
    ..sparkBolt(rate: 4, damage: 24)
    ..teleport(range: 7);

  breed("baleful demon eye", 20, carrot, 80)
    ..attack("gaze[s] into", 12)
    ..fireBolt(rate: 4, damage: 20)
    ..waterBolt(rate: 4, damage: 20)
    ..teleport(range: 9);

  breed("malevolent eye", 30, red, 120)
    ..attack("gaze[s] into", 20)
    ..lightBolt(rate: 4, damage: 20)
    ..darkBolt(rate: 4, damage: 20)
    ..fireCone(rate: 7, damage: 30)
    ..teleport(range: 9);

  breed("murderous eye", 40, maroon, 180)
    ..attack("gaze[s] into", 30)
    ..acidBolt(rate: 7, damage: 40)
    ..stoneBolt(rate: 7, damage: 40)
    ..iceCone(rate: 7, damage: 30)
    ..teleport(range: 9);

  breed("watcher", 60, lightCoolGray, 300)
    ..attack("see[s]", 50)
    ..lightBolt(rate: 7, damage: 40)
    ..lightCone(rate: 7, damage: 30)
    ..darkBolt(rate: 7, damage: 50)
    ..darkCone(rate: 7, damage: 40);

  // beholder, undead beholder, rotting beholder
}

void felines() {
  family("f")
    ..sense(see: 10, hear: 8)
    ..groups("feline");
  breed("hell cat", 1, gold, 11, speed: 1, meander: 30)
    ..missive(Missive.hiss, rate: 4)
    ..attack("bite[s]", 5)
    ..attack("scratch[es]", 4);
}

void goblins() {
  family("g", meander: 10)
    ..sense(see: 8, hear: 4)
    ..groups("goblin")
    ..openDoors();
  breed("lesser demon", 4, sandal, 30, meander: 20)
    ..count(4)
    ..attack("stab[s]", 8)
    ..missive(Missive.insult, rate: 8)
    ..drop("treasure", percent: 20)
    ..drop("spear", percent: 5)
    ..drop("healing", percent: 10);

  breed("demon archer", 6, peaGreen, 36)
    ..count(2)
    ..minion("goblin", 0, 3)
    ..attack("stab[s]", 4)
    ..arrow(rate: 3, damage: 8)
    ..drop("treasure", percent: 30)
    ..drop("bow", percent: 10)
    ..drop("dagger", percent: 5)
    ..drop("healing", percent: 10);

  breed("demon fighter", 6, tan, 58)
    ..count(2)
    ..minion("goblin", 1, 4)
    ..attack("stab[s]", 12)
    ..drop("treasure", percent: 20)
    ..drop("spear", percent: 10)
    ..drop("armor", percent: 10)
    ..drop("resistance", percent: 5)
    ..drop("healing", percent: 10);

  breed("demon warrior", 8, lightCoolGray, 68)
    ..count(2)
    ..minion("goblin", 1, 5)
    ..attack("stab[s]", 16)
    ..drop("treasure", percent: 25)
    ..drop("axe", percent: 10)
    ..drop("armor", percent: 10)
    ..drop("resistance", percent: 5)
    ..drop("healing", percent: 10)
    ..flags("protective");

  breed("demon mage", 9, darkBlue, 50)
    ..minion("goblin", 1, 4)
    ..attack("whip[s]", 7)
    ..fireBolt(rate: 12, damage: 12)
    ..sparkBolt(rate: 12, damage: 16)
    ..drop("treasure", percent: 20)
    ..drop("robe", percent: 10)
    ..drop("magic", percent: 30);

  breed("demon ranger", 12, sherwood, 60)
    ..minion("goblin", 0, 5)
    ..attack("stab[s]", 10)
    ..arrow(rate: 3, damage: 12)
    ..drop("treasure", percent: 20)
    ..drop("bow", percent: 15)
    ..drop("armor", percent: 10)
    ..drop("magic", percent: 20);

  breed("Belphegor, the Demon Prince", 14, darkCoolGray, 120)
    ..unique(pronoun: Pronoun.he)
    ..minion("goblin", 4, 8)
    ..attack("hit[s]", 10)
    ..attack("slash[es]", 14)
    ..darkBolt(rate: 20, damage: 20)
    ..drop("treasure", count: 3)
    ..dropGood("equipment", count: 2, depthOffset: 4)
    ..drop("magic", count: 3, depthOffset: 4)
    ..flags("protective");

  // TODO: Hobgoblins, bugbears, bogill.
  // TODO: https://en.wikipedia.org/wiki/Moss_people
}

void humanoids() {}

void insects() {
  family("i", tracking: 3, meander: 40, flags: "fearless")
    ..groups("bug")
    ..sense(see: 5, hear: 2);
  // TODO: Spawn as eggs which can hatch into cockroaches?
  breed("hell roach[es]", 1, brown, 4, frequency: 0.4)
    ..count(2, 5)
    ..preferCorner()
    ..attack("crawl[s] on", 2)
    ..spawn(rate: 4)
    ..drop("Insect Wing", percent: 30);
  describe("""It's not quite as easy to squash one of these when it's as long as
      your arm.""");

  breed("hell centipede", 3, red, 14, speed: 2, meander: 20)
    ..attack("crawl[s] on", 4)
    ..attack("bite[s]", 8);

  family("i", tracking: 3, meander: 40, flags: "fearless")
    ..groups("fly")
    ..sense(see: 5, hear: 2);
  breed("fire imp", 8, carrot, 6, speed: 1, meander: 70)
    ..count(3, 8)
    ..attack("bite[s]", 12, Elements.fire)
    ..drop("Insect Wing", percent: 40);
}

void jellies() {
  family("j", frequency: 0.7, speed: -1, meander: 30, flags: "fearless")
    ..groups("jelly")
    ..sense(see: 3, hear: 1)
    ..preferWall()
    ..count(4);
  breed("soul devourer", 1, lima, 5)
    ..stain(Tiles.greenJellyStain)
    ..attack("crawl[s] on", 3);
  // TODO: More elements.

  family("j", frequency: 0.6, flags: "fearless immobile")
    ..groups("jelly")
    ..sense(see: 2, hear: 1)
    ..preferCorner()
    ..count(4);
  breed("green soul mass", 2, peaGreen, 8)
    ..stain(Tiles.greenJellyStain)
    ..attack("crawl[s] on", 4)
    ..spawn(rate: 4);

  breed("frozen soul mass", 4, ash, 14)
    ..stain(Tiles.whiteJellyStain)
    ..attack("crawl[s] on", 5, Elements.cold)
    ..spawn(rate: 4);

  breed("earth soul mass", 6, tan, 20)
    ..stain(Tiles.brownJellyStain)
    ..attack("crawl[s] on", 8, Elements.earth)
    ..spawn(rate: 4);

  breed("burning soul mass", 15, red, 30)
    ..emanate(4)
    ..stain(Tiles.redJellyStain)
    ..attack("crawl[s] on", 10, Elements.fire)
    ..spawn(rate: 4);

  breed("electric soul mass", 20, purple, 40)
    ..emanate(3)
    ..stain(Tiles.violetJellyStain)
    ..attack("crawl[s] on", 12, Elements.lightning)
    ..spawn(rate: 4);

  // TODO: Erode nearby walls?
  breed("acid soul mass", 25, mint, 50)
    ..stain(Tiles.greenJellyStain)
    ..attack("crawl[s] on", 13, Elements.acid)
    ..spawn(rate: 4);

  breed("poison soul mass", 35, sherwood, 60)
    ..stain(Tiles.greenJellyStain)
    ..attack("crawl[s] on", 14, Elements.poison)
    ..spawn(rate: 4);

  // TODO: Fly?
  breed("ectoplasm", 45, darkCoolGray, 40)
    ..stain(Tiles.grayJellyStain)
    ..attack("crawl[s] on", 15, Elements.spirit)
    ..spawn(rate: 4);
}

void kobolds() {
  family("k", meander: 15, flags: "cowardly")
    ..groups("kobold")
    ..sense(see: 10, hear: 4);
  breed("scurrilous imp", 1, pink, 12, meander: 20)
    ..count(2)
    ..attack("club[s]", 4)
    ..missive(Missive.insult)
    ..haste()
    ..drop("treasure", percent: 20)
    ..drop("club", percent: 10)
    ..drop("speed", percent: 20);

  breed("vexing imp", 2, purple, 16)
    ..count(2)
    ..minion("kobold", 0, 1)
    ..attack("scratch[es]", 4)
    ..missive(Missive.insult)
    ..sparkBolt(rate: 5, damage: 6)
    ..drop("treasure", percent: 25)
    ..drop("teleportation", percent: 20);

  family("k", meander: 20).groups("kobold");
  breed("demon imp", 3, red, 20)
    ..count(3)
    ..minion("canine", 0, 3)
    ..attack("poke[s]", 4)
    ..teleport(range: 6)
    ..drop("treasure", percent: 25)
    ..drop("equipment", percent: 10)
    ..drop("magic", percent: 20);

  breed("imp shaman", 4, darkBlue, 20)
    ..count(2)
    ..minion("canine", 0, 3)
    ..attack("hit[s]", 4)
    ..waterBolt(rate: 10, damage: 8)
    ..drop("treasure", percent: 25)
    ..drop("robe", percent: 10)
    ..drop("magic", percent: 20);

  breed("imp trickster", 5, gold, 24)
    ..attack("hit[s]", 5)
    ..missive(Missive.insult)
    ..sparkBolt(rate: 5, damage: 8)
    ..teleport(rate: 7, range: 6)
    ..haste(rate: 7)
    ..drop("treasure", percent: 35)
    ..drop("magic", percent: 20);

  breed("imp priest", 6, blue, 30)
    ..count(2)
    ..minion("kobold", 1, 3)
    ..attack("club[s]", 6)
    ..heal(rate: 15, amount: 10)
    ..haste(rate: 7)
    ..drop("treasure", percent: 20)
    ..drop("club", percent: 10)
    ..drop("robe", percent: 10)
    ..drop("magic", percent: 30);

  breed("imp incanter", 7, lilac, 33)
    ..count(2)
    ..minion("kobold", 1, 3)
    ..minion("canine", 0, 3)
    ..attack("scratch[es]", 4)
    ..missive(Missive.insult, rate: 6)
    ..sparkBolt(rate: 5, damage: 10)
    ..drop("treasure", percent: 30)
    ..drop("robe", percent: 10)
    ..drop("magic", percent: 35)
    ..flags("cowardly");

  breed("imp warlock", 8, violet, 46)
    ..minion("kobold", 2, 5)
    ..minion("canine", 0, 3)
    ..attack("stab[s]", 5)
    ..iceBolt(rate: 8, damage: 12)
    ..sparkBolt(rate: 8, damage: 12)
    ..drop("treasure", percent: 30)
    ..drop("staff", percent: 20)
    ..drop("robe", percent: 10)
    ..drop("magic", percent: 30);

  breed("Malphas", 10, carrot, 80, speed: 1, meander: 10)
    ..unique(pronoun: Pronoun.he)
    ..minion("kobold", 4, 10)
    ..minion("canine", 1, 3)
    ..attack("stab[s]", 5)
    ..missive(Missive.insult, rate: 7)
    ..teleport(rate: 5, range: 6)
    ..teleport(rate: 50, range: 30)
    ..lightningCone(rate: 8, damage: 12)
    ..drop("treasure", count: 3, depthOffset: 5)
    ..dropGood("spear", percent: 20, depthOffset: 5)
    ..dropGood("armor", percent: 30, depthOffset: 5)
    ..drop("magic", count: 2, depthOffset: 5);

  // homonculous
}

void lizardMen() {
  // troglodyte

  family("l", meander: 10, flags: "fearless")
    ..groups("saurian")
    ..sense(see: 10, hear: 5)
    ..defense(5, "{2} [are|is] deflected by its scales.");
  breed("hell lizard", 11, gold, 26)
    ..attack("claw[s]", 8)
    ..attack("bite[s]", 10)
    ..drop("treasure", percent: 30)
    ..drop("armor", percent: 10)
    ..drop("spear", percent: 10);

  breed("hell lizard guard", 15, lima, 30)
    ..minion("saurian", 0, 2)
    ..attack("claw[s]", 10)
    ..attack("bite[s]", 14)
    ..drop("treasure", percent: 30)
    ..drop("armor", percent: 10)
    ..drop("spear", percent: 10);

  breed("armored hell lizard", 17, lightCoolGray, 38)
    ..minion("saurian", 0, 2)
    ..attack("claw[s]", 10)
    ..attack("bite[s]", 15)
    ..drop("treasure", percent: 30)
    ..drop("armor", percent: 20)
    ..drop("spear", percent: 10);

  breed("hell guardian", 19, darkCoolGray, 50)
    ..minion("saurian", 0, 3)
    ..minion("salamander", 0, 2)
    ..attack("claw[s]", 10)
    ..attack("bite[s]", 15)
    ..drop("treasure", percent: 40)
    ..drop("equipment", percent: 10);

  breed("hell saurian", 21, carrot, 64)
    ..minion("saurian", 1, 4)
    ..minion("salamander", 0, 2)
    ..attack("claw[s]", 12)
    ..attack("bite[s]", 17)
    ..drop("treasure", percent: 50)
    ..drop("equipment", percent: 10);
}

void mushrooms() {}

void nagas() {
  // TODO: https://en.wikipedia.org/wiki/Nagaraja
}

void orcs() {
  family("o", meander: 10)
    ..sense(see: 7, hear: 6)
    ..groups("orc")
    ..openDoors()
    ..flags("protective");
  breed("demon", 28, carrot, 100)
    ..count(3, 6)
    ..attack("stab[s]", 12)
    ..drop("treasure", percent: 20)
    ..drop("equipment", percent: 5)
    ..drop("spear", percent: 5);

  breed("demon brute", 29, mint, 120)
    ..minion("orc", 2, 5)
    ..attack("bash[es]", 16)
    ..drop("treasure", percent: 20)
    ..drop("club", percent: 10)
    ..drop("armor", percent: 10);

  breed("demon soldier", 30, lightCoolGray, 140)
    ..count(4, 6)
    ..minion("orcus", 1, 5)
    ..attack("stab[s]", 20)
    ..drop("treasure", percent: 25)
    ..drop("axe", percent: 10)
    ..drop("armor", percent: 10);

  breed("demon chieftain", 31, red, 180)
    ..minion("orcus", 2, 10)
    ..attack("stab[s]", 10)
    ..drop("treasure", count: 2, percent: 40)
    ..drop("equipment", percent: 20)
    ..drop("item", percent: 20);

  // TODO: Uniques. Some kind of magic-user.
}

void people() {
  family("p", tracking: 14, meander: 10)
    ..groups("human")
    ..sense(see: 10, hear: 5)
    ..openDoors()
    ..emanate(2);
  breed("Harold the Damned", 1, lilac, 30)
    ..unique(pronoun: Pronoun.he)
    ..attack("hit[s]", 3)
    ..missive(Missive.clumsy)
    ..drop("treasure", percent: 80)
    ..drop("weapon", percent: 20, depthOffset: 4)
    ..drop("armor", percent: 30, depthOffset: 4)
    ..drop("magic", percent: 40, depthOffset: 4);

  breed("lost soul", 1, buttermilk, 14, dodge: 15, meander: 30)
    ..attack("hit[s]", 3)
    ..missive(Missive.clumsy, rate: 12)
    ..drop("treasure", percent: 15)
    ..drop("weapon", percent: 10)
    ..drop("armor", percent: 15)
    ..drop("magic", percent: 20)
    ..flags("cowardly");

  breed("tormented soul", 2, carrot, 17)
    ..attack("hit[s]", 2)
    ..attack("stab[s]", 4)
    ..drop("treasure", percent: 20)
    ..drop("whip", percent: 10)
    ..drop("armor", percent: 15)
    ..drop("magic", percent: 20)
    ..flags("cowardly");

  breed("damned sorcerer", 3, purple, 20, meander: 30)
    ..attack("hit[s]", 2)
    ..sparkBolt(rate: 10, damage: 8)
    ..drop("treasure", percent: 15)
    ..drop("magic", percent: 30)
    ..drop("dagger", percent: 5)
    ..drop("staff", percent: 5)
    ..drop("robe", percent: 10)
    ..drop("boots", percent: 5);

  breed("damned ranger", 5, peaGreen, 30, dodge: 25, meander: 20)
    ..attack("slash[es]", 2)
    ..arrow(rate: 4, damage: 2)
    ..missive(Missive.clumsy, rate: 10)
    ..drop("treasure", percent: 20)
    ..drop("potion", percent: 20)
    ..drop("bow", percent: 10)
    ..drop("body", percent: 20);

  breed("fallen priest", 5, blue, 34, meander: 40)
    ..attack("hit[s]", 8)
    ..heal(rate: 15, amount: 8)
    ..missive(Missive.clumsy)
    ..drop("treasure", percent: 35)
    ..drop("scroll", percent: 20)
    ..drop("club", percent: 10)
    ..drop("robe", percent: 10)
    ..flags("fearless");
}

void quadrupeds() {}

void rodents() {
  family("r", dodge: 30, meander: 30)
    ..groups("rodent")
    ..sense(see: 4, hear: 6)
    ..preferWall();
  breed("hell [mouse|mice]", 1, sandal, 3, frequency: 0.7)
    ..count(6)
    ..attack("bite[s]", 3)
    ..attack("scratch[es]", 2);

  breed("hell rat", 2, coolGray, 8, meander: 20)
    ..count(4)
    ..attack("bite[s]", 4)
    ..attack("scratch[es]", 3);

  breed("diseased hell rat", 3, peaGreen, 10)
    ..attack("bite[s]", 8, Elements.poison)
    ..attack("scratch[es]", 4);

  breed("plague hell rat", 6, lima, 20)
    ..count(4)
    ..attack("bite[s]", 15, Elements.poison)
    ..attack("scratch[es]", 8);

  breed("giant hell rat", 8, carrot, 40)
    ..attack("bite[s]", 12)
    ..attack("scratch[es]", 8);

  breed("The Hell Rat King", 8, maroon, 120)
    ..unique(pronoun: Pronoun.he)
    ..attack("bite[s]", 16)
    ..attack("scratch[es]", 10)
    ..minion("rodent", 8, 16)
    ..drop("treasure", count: 3)
    ..dropGood("item", percent: 50, depthOffset: 10);
}

void slugs() {
  family("s", tracking: 2, flags: "fearless", speed: -3, dodge: 5, meander: 30)
    ..groups("slug")
    ..sense(see: 3, hear: 1);
  breed("hell slug", 3, olive, 20).attack("crawl[s] on", 8);

  breed("poison hell slug", 6, lima, 50)
      .attack("crawl[s] on", 12, Elements.poison);

  // TODO: Leave a trail.
  breed("acid hell slug", 9, olive, 70).attack("crawl[s] on", 16, Elements.acid);
}

void troglodytes() {}

void minorUndead() {}

void vines() {
  family("v", flags: "fearless immobile")
    ..groups("vine")
    ..sense(see: 10, hear: 10);
  breed("hell vine", 16, peaGreen, 40).attack("strangle", 12);
  // TODO: Touch to confuse?
  breed("poison hell vine", 19, lilac, 50)
    ..whip(rate: 3, damage: 10)
    ..attack("touch[es]", 12, Elements.poison);
  breed("creeping hell vine", 22, lima, 60)
    ..spawn(preferStraight: true)
    ..whip(rate: 3, damage: 10)
    ..attack("strangle", 8);
  breed("strangling hell vine", 26, sherwood, 80).attack("strangle", 14);
}

void worms() {
  family("w", dodge: 15, meander: 40, flags: "fearless")
    ..groups("worm")
    ..sense(see: 2, hear: 3);
  breed("blood hell worm", 1, maroon, 4, frequency: 0.5)
    ..count(3, 7)
    ..attack("crawl[s] on", 5);

  breed("fire hell worm", 10, carrot, 6)
    ..count(2, 6)
    ..preferWall()
    ..attack("crawl[s] on", 5, Elements.fire);

  family("w", dodge: 10, meander: 30, flags: "fearless").groups("worm");
  breed("hell worm", 3, pink, 30, speed: -2).attack("crawl[s] on", 5);

  breed("alaskan bull worm", 7, sandal, 80, speed: -2)
      .attack("crawl[s] on", 12, Elements.acid);
}

void skeletons() {
  family("x", meander: 30)
    ..groups("skeleton")
    ..sense(see: 4, hear: 4);
  // TODO: Special room/trap where these get spawned and come up from the
  // ground?
  breed("demon bone hand", 3, coolGray, 18, frequency: 3.0, meander: 40, speed: -1)
      .attack("claw[s]", 6);

  breed("demon bone arm", 4, lightCoolGray, 26, frequency: 4.0, meander: 40)
      .attack("claw[s]", 8);

  breed("demon skull", 7, sandal, 33, frequency: 3.0, meander: 40, speed: -2)
      .attack("bite[s]", 10);

  breed("headless bone demon", 10, buttermilk, 44, frequency: 4.0, meander: 60)
    ..sense(see: 0, hear: 0)
    ..openDoors()
    ..attack("claw[s]", 7)
    ..drop("treasure", percent: 30)
    ..drop("weapon", percent: 10)
    ..drop("armor", percent: 10);

  breed("armless bone demon", 12, mint, 50, frequency: 4.0)
    ..attack("bite[s]", 9)
    ..attack("kick[s]", 7)
    ..drop("treasure", percent: 30)
    ..drop("armor", percent: 10);

  breed("one-armed bone demon", 13, lima, 60, frequency: 5.0)
    ..openDoors()
    ..attack("claw[s]", 7)
    ..amputate("armless bone demon", "demon bone arm", "{1}'s arm falls off!")
    ..amputate("armless bone demon", "demon bone hand", "{1}'s hand falls off!")
    ..drop("treasure", percent: 30)
    ..drop("weapon", percent: 5)
    ..drop("armor", percent: 10);

  breed("bone demon", 15, ash, 70, frequency: 6.0)
    ..openDoors()
    ..attack("claw[s]", 7)
    ..attack("bite[s]", 9)
    ..amputate("headless bone demon", "demon skull", "{1}'s head pops off!")
    ..amputate("one-armed bone demon", "demon bone arm", "{1}'s arm falls off!")
    ..amputate("one-armed bone demon", "demon bone hand", "{1}'s hand falls off!")
    ..drop("treasure", percent: 40)
    ..drop("weapon", percent: 10)
    ..drop("armor", percent: 10);

  breed("bone demon warrior", 17, pink, 90, frequency: 6.0)
    ..openDoors()
    ..attack("slash[es]", 13)
    ..attack("stab[s]", 10)
    ..amputate("headless bone demon", "demon skull", "{1}'s head pops off!")
    ..amputate("one-armed bone demon", "demon bone arm", "{1}'s arm falls off!")
    ..amputate("one-armed bone demon", "demon bone hand", "{1}'s hand falls off!")
    ..drop("treasure", percent: 50)
    ..drop("weapon", percent: 20)
    ..drop("armor", percent: 15);

  breed("robed bone demon", 19, lilac, 110, frequency: 4.0)
    ..openDoors()
    ..attack("slash[es]", 13)
    ..attack("stab[s]", 10)
    ..lightningBolt(rate: 8, damage: 15)
    ..amputate("headless bone demon", "demon skull", "{1}'s head pops off!")
    ..amputate("one-armed bone demon", "demon bone arm", "{1}'s arm falls off!")
    ..amputate("one-armed bone demon", "demon bone hand", "{1}'s hand falls off!")
    ..drop("treasure", percent: 50)
    ..drop("magic", percent: 20)
    ..drop("armor", percent: 10);

  // TODO: Stronger skeletons.
}

void zombies() {}
