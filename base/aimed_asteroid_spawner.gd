extends "asteroid_spawner.gd"

export var initial_velocity:float = 50
export var aim_rand_range:Vector2 = Vector2(200, 200)
export(NodePath) var target

func _ready():
  target = get_node(target)

func init_obj(asteroid):
  .init_obj(asteroid)
  asteroid.linear_velocity = (target.global_position - asteroid.global_position + Vector2((randf()-0.5) * aim_rand_range.x, (randf()-0.5) * aim_rand_range.y)).normalized() * initial_velocity / asteroid.size
