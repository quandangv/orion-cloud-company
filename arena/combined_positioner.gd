tool
extends Node2D

export var size = 1000 setget set_size
const start_size = 500

func get_position():
  return get_child(randi() % 4).get_position()
func set_size(value):
  size = value
  if is_inside_tree():
    $positioner1.spawn_range = Rect2(0, -value, 0, value * 2)
    $positioner2.spawn_range = Rect2(0, -value, 0, value * 2)
    $positioner3.spawn_range = Rect2(-value, 0, value * 2, 0)
    $positioner4.spawn_range = Rect2(-value, 0, value * 2, 0)

func add_tween(obj, initial, final):
  $tween.interpolate_property(obj, 'position', initial, final, 5, Tween.TRANS_QUAD, Tween.EASE_IN)

func _ready():
  add_tween($positioner1, Vector2(-start_size, 0), Vector2(-size - 100, 0))
  add_tween($positioner2, Vector2(start_size, 0), Vector2(size + 100, 0))
  add_tween($positioner3, Vector2(0, -start_size), Vector2(0, -size - 100))
  add_tween($positioner4, Vector2(0, start_size), Vector2(0, size + 100))
  $tween.start()
