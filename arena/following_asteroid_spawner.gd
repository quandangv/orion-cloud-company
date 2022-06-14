extends "res://base/asteroid_spawner.gd"

export(NodePath) var target
export var thrust_range = Vector2(4, 7)

func _ready():
  target = get_node(target)

func init_obj(asteroid):
  .init_obj(asteroid)
  asteroid.get_node('chase').target = target
  asteroid.side = "emeny"
  asteroid.get_node('chase').thrust = rand_range(thrust_range.x, thrust_range.y)
