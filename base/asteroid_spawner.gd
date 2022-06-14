extends "spawner.gd"

export var available_sizes_range:Vector2

func init_obj(obj):
  var size = lerp(available_sizes_range.x, available_sizes_range.y, randf())
  obj.init_asteroid(size, size * size, 20)
  .init_obj(obj)
