extends Node2D

export var spawn_range:Rect2

func get_position():
  return Vector2(randf()*spawn_range.size.x, randf()*spawn_range.size.y) + spawn_range.position + global_position
