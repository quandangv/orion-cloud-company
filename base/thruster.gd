extends Node2D

export var thrust:float = 1
const thrust_to_torque = 400
const thrust_to_force = 150
const min_movement = 0.01
const modulate_factor = 0.1
const size_factor = 1
var move_direction:Vector2
var move_strength:float
onready var parent = get_parent()
onready var particles = $particles

func _ready():
  init(thrust)
func _draw():
  var color = Color.white
  draw_circle(Vector2.ZERO, 1, color)
  draw_rect(Rect2(0, -1, 1, 2), color, true)

func move(direction, delta):
  move_direction = direction
  var move_strength = move_direction.length()
  if move_strength < min_movement: # if user give no input
    move_direction = -parent.linear_velocity * parent.controller.stop_multiplier
    move_strength = move_direction.length()
    if move_strength != 0 and move_strength < thrust * thrust_to_force * delta / parent.mass:
      parent.linear_velocity = Vector2.ZERO
      move_strength = 0
  if move_strength >= 0.99: # if user input is out of bound
    move_direction = move_direction.normalized()
    move_strength = 1
  move_direction *= exp(-move_direction.dot(parent.linear_velocity.normalized())*0.5)
  
  if move_strength > 0.1: # if there is any input after everything
    rotation = lerp_angle(rotation, (-move_direction).angle() - parent.global_rotation, 0.05)
  particles.emitting = randf() < move_strength
  if move_strength > 0:
    parent.apply_central_impulse(move_direction * thrust * thrust_to_force * delta)

func init(thrust):
  if thrust > 0:
    particles.emitting = true
    particles.amount = thrust*2
    particles.modulate = Color(1, 1, 1, modulate_factor * thrust)
  else:
    particles.emitting = false
  self.thrust = thrust
  visible = thrust > 0
  scale = Vector2(1, 1) * sqrt(thrust) * size_factor
  update()

func _physics_process(delta):
  if thrust > 0 and parent.controller:
    assert(not is_nan(parent.controller.movement.x) and not is_nan(parent.controller.movement.y), "Controller movement is NAN")
    if is_nan(parent.controller.movement.x) or is_nan(parent.controller.movement.y):
      parent.controller.movement = Vector2.ZERO
    move(parent.controller.movement, delta)
    assert(not is_nan(parent.controller.angle), "Controller angle is NAN")
    if is_nan(parent.controller.angle):
      parent.controller.angle = 0
    var rotation_delta = parent.controller.angle - parent.global_rotation
    if rotation_delta < -PI:
      rotation_delta += PI*2
    elif rotation_delta > PI:
      rotation_delta -= PI*2
    var target_angular_velocity = rotation_delta * thrust * parent.controller.thrust_to_rotate_speed*0.6
    var angular_delta = target_angular_velocity - parent.angular_velocity
    parent.apply_torque_impulse(clamp(angular_delta * parent.mass, -1, 1) * thrust * thrust_to_torque * delta)
