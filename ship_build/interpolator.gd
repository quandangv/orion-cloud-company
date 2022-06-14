extends Node2D

export var latency = 0.1
var target_pos: Vector2
var target_rotation: float
var target_modulate: Color
onready var img = $img

func _process(delta):
  var weight = delta / latency
  position = lerp(position, target_pos, weight)
  rotation = lerp_angle(rotation, target_rotation, weight)
  modulate = lerp(modulate, target_modulate, weight)

func update_color(white):
  target_modulate = Color.white if white else Color.transparent

func update_pos(white, pos):
  update_color(white)
  target_pos = ComponentUtils.map_to_local(pos)

func init(white, pos, component):
  set_process(true)
  visible = true
  position = pos
  update_color(white)
  img.set_component(component)

func hibernate():
  update_color(false)
  set_process(false)
  visible = false
