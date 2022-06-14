extends MarginContainer

export(Color) var safe_color
export(Color) var danger_color

var stat_bars = {}
var autohide_bars = []

func _ready():
  for bar in $container.get_children():
    bar.get_node("label").text = bar.name
    stat_bars[bar.name] = bar
    if not bar.visible:
      autohide_bars.append(bar.name)

func set_stat(stats):
  for name in stats:
    if name in stat_bars:
      stat_bars[name].set_value(stats[name])

func selection_changed(new_tile):
  if new_tile:
    new_tile = new_tile.duplicate()
    if "plasma" in new_tile:
      new_tile["plasma_supply"] = new_tile["plasma"].supply
      stat_bars["plasma_supply"].max_value = new_tile["plasma"].max_supply
      new_tile["plasma_energy"] = new_tile["plasma"].energy
      new_tile["plasma_speed"] = new_tile["plasma"].speed
    if "wasted_plasma" in new_tile:
      if new_tile["wasted_plasma"].supply > 0:
        new_tile["wasted_plasma_supply"] = new_tile["wasted_plasma"].supply
        stat_bars["wasted_plasma_supply"].max_value = new_tile["wasted_plasma"].max_supply
      else:
        new_tile.erase("wasted_plasma_supply")
  else:
    new_tile = {}
  for bar in autohide_bars:
    if bar in new_tile:
      stat_bars[bar].set_visibility(true)
      if not new_tile[bar] is bool:
        stat_bars[bar].set_value(new_tile[bar])
    else:
      stat_bars[bar].set_visibility(false)
