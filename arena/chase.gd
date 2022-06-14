extends Node

signal hit(target)

onready var parent = get_parent()
var target
var hit_radius_sqr:float = 100
const force = 0.2

func _physics_process(delta):
  if target:
    var diff = target.global_position - parent.global_position
    parent.linear_velocity += (diff - parent.linear_velocity*0.2)*force
    if diff.length_squared() < hit_radius_sqr:
      emit_signal("hit", target)
