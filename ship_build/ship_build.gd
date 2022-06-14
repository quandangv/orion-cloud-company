extends Node

const SEL_POSITION = 0
const SEL_TYPE = 1

export var halfsize:int = 10
export(NodePath) var type_buttons_path
export(NodePath) var selection_detail_path
export(NodePath) var warning_path
var tiles: Array
var size: int
var type_buttons_anim: AnimationPlayer
var selection_detail
var warning
var general_warning

export(NodePath) var ghost_path
var ghost
onready var map = $map
onready var selection = $map/selection

func _ready():
  type_buttons_anim = get_node(type_buttons_path).find_node("anim")
  selection_detail = get_node(selection_detail_path)
  ghost = get_node(ghost_path)
  warning = get_node(warning_path)
  size = halfsize*2+1
  map.halfsize = halfsize
  $ui/base/toolbar.connect("rotation_changed", self, "rotation_changed")
  $ui/base/toolbar.connect("selection_changed", self, "tool_changed")
  tool_changed(null)
  reset_tiles()

func _unhandled_input(event):
  if event is InputEventMouseMotion:
    var show_ghost = false
    var mouse = map.get_mouse_pos()
    if event.button_mask & BUTTON_RIGHT:
      set_tile(mouse, null)
      unselect_tile()
    elif event.button_mask & BUTTON_LEFT:
      var selected = $ui/base/toolbar.get_selected()
      if selected:
        set_tile(mouse, {"": selected, "rotation": $ui/base/toolbar.rotation})
    else:
      show_ghost = true
    ghost.update_pos(inrange(mouse) and show_ghost, mouse)
  if event is InputEventMouseButton:
    var mouse = map.get_mouse_pos()
    if event.button_mask & BUTTON_RIGHT:
      set_tile(mouse, null)
    elif event.button_mask & BUTTON_LEFT:
      var selected = $ui/base/toolbar.get_selected()
      if selected:
        set_tile(mouse, {"": selected, "rotation": $ui/base/toolbar.rotation})
      elif inrange(mouse):
        var new_selected_tile
        while true:
          new_selected_tile = tiles[get_tile_index(mouse)]
          if new_selected_tile == null or mouse == selection.pos:
            unselect_tile()
          elif new_selected_tile[""] == "redirect":
            mouse += new_selected_tile["target"]
            continue
          else:
            select_tile(mouse, new_selected_tile)
          break

func unselect_tile():
  if selection.pos != null:
    selection.disappear()
    type_buttons_anim.play("appear")
    selection_detail.disappear()
    $ui/base/stats.selection_changed(null)
    warning.init(general_warning)

func select_tile(pos, tile):
  $ui/base/stats.selection_changed(tile)
  $ui/base/toolbar.rotation = tile.get("rotation", 0)
  selection.init(pos, tile)
  type_buttons_anim.play_backwards("appear")
  if "warning" in tile:
    warning.init(tile["warning"])
  else:
    warning.disappear()
  selection_detail.appear(tile[""])

func check_near(pos, type, delta):
  for d in delta:
    var neighbor = pos + d
    if not inrange(neighbor):
      return false
    var tile = tiles[get_tile_index(neighbor)]
    if tile == null or tile[""] != type:
      return false
  return true

func inrange(pos):
  return pos.x >= -halfsize and pos.x <= halfsize and  pos.y >= -halfsize and pos.y <= halfsize

func tool_changed(selected_tool):
  if selected_tool != null:
    selection.disappear()
    ghost.init(false, map.get_local_mouse_position(), selected_tool)
  else:
    ghost.hibernate()

func rotation_changed(rotation):
  ghost.target_rotation = rotation * PI / 3
  if selection.pos != null:
    var tile = get_tile(selection.pos)
    tile["rotation"] = rotation
    reanalyze()
    map.set_cell(selection.pos, tile, $ui/base/toolbar.rotation)

func get_tile(pos):
  return tiles[get_tile_index(pos)]

func reset_tiles():
  map.clear()
  tiles = []
  tiles.resize(size*size)

func get_tile_index(pos):
  return pos.x + halfsize + (pos.y  + halfsize)* size

func get_tile_pos(index):
  return Vector2(index % size - halfsize, int(index / size) - halfsize)

func set_tile(pos, tile, reanalyze = true):
  if not inrange(pos):
    return
  if tile == null:
    tile = null
  var index = get_tile_index(pos)
  var current = tiles[index]
  if current == tile:
    return
  if current != null:
    if current[""] == "redirect":
      set_tile(current["target"] + pos, null, false)
    if "occupies" in current:
      for delta in current["occupies"]:
        tiles[get_tile_index(pos + delta)] = null
  tiles[index] = tile
  if tile != null:
    if "occupies" in tile:
      for delta in tile["occupies"]:
        set_tile(pos + delta, {"": "redirect", "target": -delta}, false)
  map.set_cell(pos, tile, $ui/base/toolbar.rotation)
  if reanalyze:
    reanalyze()

func reanalyze():
  var stats = ComponentUtils.analyze_components(tiles, size, -halfsize)
  var misc = stats[1]
  stats = stats[0]
  if misc["warnings"]:
    general_warning = "issues at " + PoolStringArray(misc["warnings"]).join(', ')
  else:
    general_warning = null
  warning.init(general_warning)
  $ui/base/stats.set_stat(stats)
  map.draw_misc(misc)

func print_ship():
  var final = ComponentUtils.finalize_ship(tiles, size)
  print(to_json({'map':final['map'], 'mapsize':final['mapsize']}))
