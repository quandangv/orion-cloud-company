extends Node2D

signal lost_target(target)

var target
var points
var last_stat
onready var parent = get_parent()
var _range:float
export var min_range:float = 100
export var target_size_ratio:float = 2
var startup = false

func init(target):
  var diff = target.global_position - global_position
  _range = diff.length()*1.3
  self.target = target
  last_stat = [diff.angle(), _range, target.size]
  if _range < min_range: _range = min_range
  points = null
  set_physics_process(true)
  visible = true
  return true

func hibernate():
  self.target = null
  last_stat = null
  set_physics_process(false)
  visible = false

func on_lose_target():
  assert(not target is Array)
  emit_signal("lost_target", target)
  target = last_stat

func _physics_process(delta):
  assert(target != null)
  assert(last_stat != null)
  var angle = 0
  var length = 0
  var size = 1
  if not target is Array:
    if not target.is_inside_tree():
      on_lose_target()
    else:
      size = target.size
      var position = target.global_position - global_position
      length = position.length()
      if length > _range:
        on_lose_target()
      else:
        angle = position.angle()
        last_stat = [angle, length, size]
  if target is Array:
    angle = target[0]
    length = target[1]
    size = target[2]
  if target == null:
    var temp = 0
    
  points = ShapeLib.bone.make(parent.size, size*target_size_ratio, length)
  global_rotation = angle
  update()

func _draw():
  if points:
    draw_colored_polygon(points, parent.beam_color, PoolVector2Array(), null, null, true)

func _ready():
  visible = target != null
  set_physics_process(visible)

func animate_smooth_alpha(value, delta):
  assert(value <= 1 and value >= 0)
  modulate.a = clamp(value, modulate.a - delta, modulate.a + delta)
  visible = modulate.a > 0
