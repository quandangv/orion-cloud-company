extends Node

var last_velocity:Vector2
onready var parent = get_parent()
const collision_threshold = 20
const collision_damage_multiplier = 0.005
export var sound_base_frequency:float = 2

func _physics_process(_delta):
  last_velocity = parent.linear_velocity

func body_entered(other):
  # Godot is inconsistent about when to emit this signal, the velocity of the other body may be before or after collision
  # So we just ignore the other body and track our velocity before and after collision
  var dir = parent.linear_velocity - last_velocity
  var damage = dir.length() - collision_threshold
  if damage > 0:
    damage *= parent.mass * collision_damage_multiplier
    var damage_scale = clamp(inverse_lerp(1, 10, damage), 0, 1)
    SoundPlayer.play_audio("collision", parent.global_position, lerp(1, 0.2, damage_scale) * sound_base_frequency, lerp(-10, 10, damage_scale))
    parent.body_collide(other, dir, damage)
    if other.has_method('body_collide') and other.get('passive_collision_damage'):
      other.body_collide(parent, -dir, damage)
