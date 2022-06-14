extends Node

onready var pool = $pool
export var plasma_size:float

func get_plasma(source, hp, damage, position, velocity):
  var plasma = pool.get_object()
  BulkAnim.fade_in_grow.final_state(plasma)
  plasma.global_position = position
  plasma.damage = damage
  plasma.side = source.side
  plasma.source = source
  plasma.color = GameUtils.plasma_colors.get(source.side, Color.gray)
  plasma.init_plasma(plasma_size, hp, velocity)
  plasma.collision.set_deferred('disabled', false)
  return plasma
