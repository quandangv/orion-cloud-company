extends Node2D

export var halfsize = 5
export var grid_color: Color
export var coordinate_color: Color
export var coordinate_font: Font
export(Vector2) var mapping_offset
export var covered_texture:Texture
export var straigth_connection_texture:Texture
export var front_connection_texture:Texture
export var back_connection_texture:Texture
onready var top = $top
onready var mid = $mid
onready var bottom = $bottom

func get_mouse_pos():
  var pos = get_local_mouse_position()
  return ComponentUtils.local_to_map(pos)

func _draw():
  var rid = get_canvas_item()
  for x in range(-halfsize, halfsize+1):
    if x == 0:
      coordinate_font.draw_char(rid, ComponentUtils.map_to_local(Vector2(x, x)), ord(str(x)), -1, coordinate_color)
    else:
      coordinate_font.draw(rid, ComponentUtils.map_to_local(Vector2(x, 0)), str(x), coordinate_color)
      coordinate_font.draw(rid, ComponentUtils.map_to_local(Vector2(0, x)), str(x), coordinate_color)
    for y in range(-halfsize, halfsize+1):
      var pos = ComponentUtils.map_to_local(Vector2(x, y))
      draw_circle(pos, 7.5, grid_color)
  draw_circle(Vector2.ZERO, 5, grid_color)

func set_cell(pos, tile, rotation):
  if tile == null:
    bottom.set_cell(pos, null)
    top.set_cell(pos, null)
    return
  var component = ComponentUtils.component_dict[tile[""]]
  bottom.set_cell(pos, component.bottom_texture, tile["rotation"])
  top.set_cell(pos, component.top_texture, tile["rotation"])

func clear():
  bottom.clear()
  top.clear()

func draw_misc(misc):
  var covered = misc["covered"]
  var connections = misc["connections"]
  for child in mid.get_children():
    if "covered" in child.name:
      var coord = ComponentUtils.local_to_map(child.position)
      if not coord in covered and child.visible:
        BulkAnim.fade_out.add(child)
    if "connection" in child.name:
      var coord = ComponentUtils.local_to_map(child.position)
      if (not coord in connections or not int(child.name[0]) in connections[coord][1]):
        child.visible = false
  for coord in covered:
    var result = mid.set_cell(coord, covered_texture, 0, "covered")
    if result[1]:
      result[0].modulate.a = 0
    BulkAnim.fade_in.add(result[0])
  for coord in connections:
    var list = connections[coord][1]
    var tile = connections[coord][0]
    for angle in list:
      var result
      if 'plasma_modifier' in tile:
        var my_angle = tile.get("rotation", 0)
        var angle_diff = (angle - my_angle + 6) % 6
        if angle_diff == 3:
          result = mid.set_cell(coord, straigth_connection_texture, angle, str(angle) + "connection")
        elif angle_diff == 1:
          result = mid.set_cell(coord, front_connection_texture, my_angle, str(angle) + "connection")
        elif angle_diff == 5:
          result = mid.set_cell(coord, front_connection_texture, my_angle, str(angle) + "connection")
        elif angle_diff == 2:
          result = mid.set_cell(coord, back_connection_texture, my_angle, str(angle) + "connection")
        elif angle_diff == 4:
          result = mid.set_cell(coord, back_connection_texture, my_angle, str(angle) + "connection")
        else:
          continue
        if (-1 if angle_diff > 3 else 1) * result[0].scale.y < 0:
          result[0].scale.y *= -1
      else:
        result = mid.set_cell(coord, straigth_connection_texture, angle, str(angle) + "connection")
      if result[1]:
        result[0].modulate.a = 0
      BulkAnim.fade_in.add(result[0])
