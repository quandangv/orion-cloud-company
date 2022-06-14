extends Node

export var size_range:Vector2
export var distance_range:Vector2 setget set_distance_range
export var speed_range:Vector2
export var color:Color = Color.darkgreen
export(NodePath) var center
export var starting_count:int = 20
onready var parent = get_parent()

func _ready():
  center = get_node(center)
  yield(get_tree(), 'idle_frame')
  spawn_multiple(starting_count, 1)

func spawn_multiple(count, delay = 0.4):
  for i in range(count):
    spawn_rand(rand_size())
    yield(get_tree().create_timer(delay), "timeout")

func rand_size():
  return rand_range(size_range.x, size_range.y)

func spawn_rand(size):
  spawn(size)

func spawn(size):
  var obj = $pool.get_object()
  obj.global_position = parent.global_position + Vector2(parent.size + size, 0).rotated(randf()*PI*2)
  obj.color = color
  obj.side = 'friendly'
  obj.visible = false
  var controller = obj.get_node('orbiting_controller')
  controller.distance = lerp(distance_range.x, distance_range.y, randf())
  controller.speed = lerp(speed_range.x, speed_range.y, randf())
  controller.target = center
  BulkAnim.fade_in_grow.add(obj)
  return obj

func set_distance_range(value):
  if value.x == value.y:
    value.y += 1
  if get_node_or_null('pool'):
    for obj in $pool.get_children():
      var controller = obj.get_node('orbiting_controller')
      controller.distance = range_lerp(controller.distance, distance_range.x, distance_range.y, value.x, value.y)
  distance_range = value
