extends "res://base/asteroid_spawner.gd"

export var rate_range:Vector2 # range
export var rate_pos_range:Vector2 # range
export var initial_velocity:Vector2
export var velocity_angle_range:float
export var attach_distance:Vector2
export(NodePath) var target
export(NodePath) var stage_name
export(NodePath) var blue_container
export var normal_color:Gradient
export var fuel_color:Color
export var fuel_chance:float = 0.3

func attach():
  stage_name.text = "asteroids"
  target = get_node(target)
  blue_container = get_node(blue_container)
  get_parent().disconnect("screen_entered", self, "attach")
  wake_up()

func _ready():
  stage_name = get_node(stage_name)

func _process(_delta):
  global_position = target.global_position + attach_distance
  spawn_rate = lerp(rate_range.x, rate_range.y, clamp(inverse_lerp(rate_pos_range.x, rate_pos_range.y, target.global_position.x), 0, 1))

func init_obj(asteroid):
  .init_obj(asteroid)
  asteroid.linear_velocity = initial_velocity.rotated((randf()-0.5)*velocity_angle_range)
  if randf() < fuel_chance:
    asteroid.color = fuel_color
    asteroid.following = true
    asteroid.primary_target = blue_container
  else:
    asteroid.color = normal_color.interpolate(randf())
    asteroid.following = false

func destroyed():
  set_process(false)
  for asteroid in $pool.get_children():
    asteroid.force_follow_primary = true
    asteroid.destroyed_by(self)
  hibernate()
