extends "res://pilot/asteroid.gd"

var og_position:Vector2
var og_mass:float
var reset_count = 0
export var primary_target_path:NodePath
export var secondary_target_path:NodePath

func _ready():
  og_position = global_position
  og_mass = get('mass')
  following = true
  primary_target = get_node(primary_target_path)
  secondary_target = get_node(secondary_target_path)
  if size > 0:
    reset()

func reset_physics():
  global_position = og_position
  set("linear_velocity", Vector2.ZERO)

func _integrate_forces(state):
  if reset_count:
    state.transform = Transform2D(0.0, og_position)
    state.linear_velocity = Vector2.ZERO
    reset_count -= 1
func reset():
  color.a = 1
  init_asteroid(size, og_mass, damage)
  set("mode", RigidBody2D.MODE_RIGID)
  update()
  reset_count = 2
  destroyed_once = false
  $collision.set_deferred(disabled, false)
