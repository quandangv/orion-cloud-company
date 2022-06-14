extends "res://base/asteroid.gd"

var target:Node2D
var thrust = 4
const thrust_to_rotate_speed =1
const thrust_to_torque = 500
const thrust_to_force = 15
const force_to_speed = 1
const thrust_to_speed = thrust_to_force * force_to_speed

func _physics_process(delta):
  var direction
  var velocity = get("linear_velocity")
  var speed = velocity.length()
  var mass = get("mass")
  var diff = target.global_position - global_position
  var target_angle = (diff - velocity.project(diff.tangent()) * 2 - velocity*0.1).angle()
#  var rotation_delta = target_angle - global_rotation
#  if rotation_delta < -PI:
#    rotation_delta += PI*2
#  elif rotation_delta > PI:
#    rotation_delta -= PI*2
#  var target_angular_velocity = rotation_delta * thrust * thrust_to_rotate_speed
#  var angular_delta = target_angular_velocity - get("angular_velocity")
#  call("apply_torque_impulse", clamp(angular_delta * mass, -1, 1) * thrust * thrust_to_torque * delta)
  global_rotation = target_angle
  direction = Vector2.RIGHT.rotated(global_rotation)
  if speed > thrust * thrust_to_speed:
    direction -= velocity.normalized() * (speed - thrust * thrust_to_speed) * 0.5
  
  call("apply_central_impulse", direction * thrust * thrust_to_force * delta * mass)
