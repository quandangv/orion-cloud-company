extends "res://base/asteroid.gd"

const primary_target_follow_range_sqr = 10000
var primary_target_capture_range_sqr = 100
var primary_target:Node
var secondary_target:Node
var following:bool
var following_secondary:bool
var force_follow_primary:bool
var destroyed_once:bool
var follow_distance

func _enter_tree():
  destroyed_once = false
  secondary_target = null
  $collision.set_deferred(disabled, false)
  force_follow_primary = false
  set("mode", RigidBody2D.MODE_RIGID)

func destroyed_by(other):
  if following and not destroyed_once:
    var target = other.get("source")
    following_secondary = false
    if target:
      follow_distance = target.offer_capture(self)
      if follow_distance != null:
        secondary_target = target
        following_secondary = true
    if following_secondary or force_follow_primary:
      set("mass", sqrt(og_hp / hp_multiplier))
      set("mode", RigidBody2D.MODE_KINEMATIC)
      destroyed_once = true
      $collision.set_deferred(disabled, true)
      color.a = 1
      update()
      return
  destroyed()
func draw():
  if destroyed_once:
    draw_colored_polygon(points, color)
  else:
    .draw()
func released():
  .destroyed()

func _physics_process(delta):
  if destroyed_once:
    var target = primary_target.global_position - global_position
    if following_secondary:
      if target.length_squared() < primary_target_follow_range_sqr:
        if secondary_target.demand_release(self):
          following_secondary = false
      else:
        target = secondary_target.global_position - global_position
        target = target - follow_distance.rotated(target.length_squared()/400)
    elif target.length_squared() < primary_target_capture_range_sqr and primary_target.offer_absorb(self):
      destroyed_once = false
      secondary_target = null
      .destroyed()
    translate(target*0.02)
