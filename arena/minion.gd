extends Node

onready var parent = get_parent()
func area_interact(other):
  SoundPlayer.play_audio('stab', parent.global_position, 1, range_lerp(other.hp, 0, 2, -20, 10))
