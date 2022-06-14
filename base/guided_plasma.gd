extends "res://base/plasma.gd"

signal idle(delta)

var target = weakref(null) setget set_target
export var thrust:float = 2
export var thrust_to_force = 2

var points:PoolVector2Array

func set_target(value:Node2D):
  target = weakref(value)
  update()

func init_plasma(size, hp, velocity):
  .init_plasma(size, hp, velocity)
  points = ShapeLib.shape.make(-size*1.2, 0.7, 3, 2)
  update()

func _draw():
  var target_obj = target.get_ref()
  if target_obj:
    draw_colored_polygon(points, color)
  else:
    draw_circle(Vector2.ZERO, size, color)

func degradation_rate():
  return (0.5 if target else 1) * .degradation_rate()

func _physics_process(delta):
  var target_obj = target.get_ref()
  if target_obj != null and target_obj.is_inside_tree():
    var diff = target_obj.global_position - global_position
    var diff_length = diff.length()
    diff += target_obj.linear_velocity * diff_length / (thrust * thrust_to_force + linear_velocity.length())
    var mass = get("mass")
    var direction = diff - linear_velocity.project(diff.tangent()) * 2 - linear_velocity*0.1
    steer(direction*10, delta)
  else:
    emit_signal('idle', delta)

func steer(direction, delta):
  global_rotation = direction.angle()
  var strength = direction.length()
  if strength == 0: return
  if direction.dot(linear_velocity) / strength < thrust:
    linear_velocity += (direction / strength if strength > 1 else direction) * thrust * thrust_to_force * delta
