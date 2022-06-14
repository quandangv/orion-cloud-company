extends Node2D

signal destroyed()

var points
var color
var linear_velocity:Vector2
const drag = 0.01
onready var collision = $collision
onready var chase = $chase
var target_stash
var limit_sqr:float
var other_targets = []

var resource_name:String
var resource_amount:float
var resource_amount_og:float

func init(velocity, size, side_count, type):
  collision.set_deferred("disabled", false)
  scale = Vector2(size, size)
  if side_count > 0:
    points = ShapeLib.shape.make(1, 0.8, side_count, size*2)
  else:
    points = null
  color = type.color
  resource_name = type.name
  resource_amount = size*size
  resource_amount_og = resource_amount
  chase.hit_radius_sqr = size*size
  linear_velocity = velocity
  modulate = Color.white
  chase.target = null
  other_targets.clear()
  update()

func _draw():
  if points:
    draw_colored_polygon(points, color, PoolVector2Array(), null, null, true)
  else:
    draw_circle(Vector2.ZERO, 1, color)
    draw_arc(Vector2.ZERO, 1, 0, PI*2, ShapeLib.circle_point_count(scale.x), color, 1, true)

func _physics_process(delta):
  position += linear_velocity * delta
  linear_velocity *= (1-drag)
  if chase.target:
    if not (chase.target in other_targets) and (global_position - chase.target.global_position).length_squared() > limit_sqr:
      next_target()

func next_target():
  for target in other_targets:
    if target != chase.target:
      var stash = target.get_node_or_null('stash')
      if stash and stash.accept_resource(resource_name):
        chase.target = target
        return
  chase.target = null

func body_entered(body, stash = null, force = false):
  if not stash:
    stash = body.get_node_or_null('stash')
    if not stash: return
    if not body in other_targets:
      other_targets.append(body)
  if not chase.target or force:
    if stash.accept_resource(resource_name):
      target_stash = stash
      chase.target = body
      limit_sqr = (global_position - chase.target.global_position).length_squared()

func body_exited(body):
  if body in other_targets:
    other_targets.erase(body)

func chase_hit(target):
  dump_stash(target_stash)

func dump_stash(stash):
  resource_amount -= stash.take_resource(resource_name, resource_amount)
  chase.target = null
  modulate.a = lerp(0.2, 1, resource_amount / resource_amount_og)
  if resource_amount <= 0:
    collision.set_deferred("disabled", true)
    emit_signal("destroyed")
