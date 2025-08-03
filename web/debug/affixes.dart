import 'dart:html' as html;

import 'package:loop_rpg/src/content/elements.dart';
import 'package:loop_rpg/src/content/item/affixes.dart';
import 'package:loop_rpg/src/content/item/drops.dart';
import 'package:loop_rpg/src/content/item/items.dart';
import 'package:loop_rpg/src/debug/histogram.dart';
import 'package:loop_rpg/src/debug/html_builder.dart';
import 'package:loop_rpg/src/engine.dart';

const tries = 100000;

int get depth {
  var depthSelect = html.querySelector("#depth") as html.SelectElement;
  return int.parse(depthSelect.value!);
}

void main() {
  Items.initialize();
  Affixes.initialize();

  var depthSelect = html.querySelector("#depth") as html.SelectElement;
  for (var i = 1; i <= Option.maxDepth; i++) {
    depthSelect.append(html.OptionElement(
        data: i.toString(), value: i.toString(), selected: i == 1));
  }

  depthSelect.onChange.listen((event) {
    generate();
  });

  generate();
}

String percent(int count) {
  return "${(count * 100 / tries).toStringAsFixed(3)}%";
}

void generate() {
  var affixes = Histogram<AffixData>();

  var dropAny = parseDrop('item');

  for (var i = 0; i < tries; i++) {
    var itemType = Items.types.tryChoose(depth);
    if (itemType == null) continue;

    // Create a blank lore each time so that we can count how often a given
    // artifact shows up without uniqueness coming into play.
    var lore = Lore();

    // TODO: Pass in levelOffset.
    dropAny.dropItem(lore, depth, (item) {
      for (var affix in item.affixes) {
        affixes.add(AffixData(affix.type.id, affix.parameter, affix));
      }
    });
  }

  var builder = HtmlBuilder();
  builder.thead();
  builder.td("Affix");
  builder.td("Param");
  builder.td("Heft");
  builder.td("Weight");
  builder.td("Strike");
  builder.td("Damage");
  builder.td("Armor");
  builder.td("Brand");
  builder.td("Resistance");
  builder.td("Stat");
  builder.td("Percent");
  builder.tbody();

  var sorted = affixes.descending().toList();
  sorted.sort();

  for (var data in sorted) {
    var affix = data.affix;
    builder.td(data.id);
    builder.td(data.parameter);
    builder.td(affix.heftScale);
    builder.td(affix.weightBonus);
    builder.td(affix.strikeBonus);
    builder.td("${affix.damageBonus} ${affix.damageScale.toStringAsFixed(1)}");
    builder.td(affix.armorBonus);

    if (affix.brand != Element.none) {
      builder.td(affix.brand.abbreviation);
    } else {
      builder.td("&nbsp;");
    }

    builder.td([
      for (var element in Elements.all)
        if (affix.resistance(element) != 0)
          "${element.abbreviation}:${affix.resistance(element)}"
    ].join(" "));

    builder.td([
      for (var stat in Stat.all)
        if (affix.statBonus(stat) != 0)
          "${stat.abbreviation}:${affix.statBonus(stat)}"
    ].join(" "));

    builder.td(percent(affixes.count(data)));
    builder.trEnd();
  }

  builder.replaceContents('table');
}

class AffixData implements Comparable<AffixData> {
  final String id;

  final int parameter;

  final Affix affix;

  AffixData(this.id, this.parameter, this.affix);

  @override
  int get hashCode => Object.hash(id, parameter);

  @override
  bool operator ==(Object other) =>
      other is AffixData && id == other.id && parameter == other.parameter;

  @override
  int compareTo(AffixData other) {
    if (affix.sortIndex != other.affix.sortIndex) {
      return affix.sortIndex.compareTo(other.affix.sortIndex);
    }

    if (id != other.id) {
      return id.compareTo(other.id);
    }

    return parameter.compareTo(other.parameter);
  }
}
