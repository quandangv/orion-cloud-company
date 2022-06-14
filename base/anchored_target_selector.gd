extends "res://base/target_selector.gd"

export var max_from_anchor:float = 200 # maximum distance from the anchor will we pursue a target
onready var max_from_anchor_sqr = max(max_from_anchor*max_from_anchor, 0.001)
var ship

func _idle(delta):
  if ship.targeted_position != null:
    var movement = ship.targeted_position - ship.global_position - ship.linear_velocity
    var movement_length_sqr = movement.length_squared()
    if movement_length_sqr > 1:
      movement /= pow(movement_length_sqr, 0.2) *0.25
    parent.movement += movement
  if parent.movement.length_squared() > 0.01:
    parent.angle = parent.movement.angle()
  assert(not is_nan(parent.angle))

func before_combine_movement():
  if ship.targeted_position != null:
    if (parent.global_position - ship.targeted_position).length_squared() > max_from_anchor_sqr:
      parent.new_movement = ship.targeted_position - ship.global_position - ship.linear_velocity

func _ready():
  parent.connect("wake_up", self, "wake_up")
  parent.connect("idle", self, "_idle")
  parent.connect("before_combine_movement", self, "before_combine_movement")

func wake_up():
  ship = parent.parent
  if ship.targeted_position == null:
    ship.targeted_position = ship.global_position
