extends Node

onready var parent = get_parent()

const movement_change = [2, 5]
const movement_intensity = [0.1, 0.5]
var until_movement_change:float
var movement:Vector2
var angle:float
onready var bias_target = parent.global_position

func _idle(delta):
  until_movement_change -= delta
  if until_movement_change <= 0:
    until_movement_change = rand_range(movement_change[0], movement_change[1])
    var velocity = parent.parent.linear_velocity
    movement = Vector2(rand_range(movement_intensity[0], movement_intensity[1]), 0).rotated(randf()*PI*2) + (bias_target - parent.global_position - velocity) * 0.001
    angle = movement.angle()
    assert(not is_nan(angle))
    movement -= velocity * 0.01 / until_movement_change
  parent.movement = movement
  parent.angle = angle

func _ready():
  parent.connect("idle", self, "_idle")
