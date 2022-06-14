extends "polygon.gd"

signal destroyed_by(other)
signal destroyed_by_()
signal area_interact(other)

const max_initial_torque = 10
const hp_multiplier = 0.25
onready var passive_collision_damage = not get_node_or_null('collision_damage')
export var side = "junk"
var hp:float
var og_hp:float
var points = []
var line_points = []
export var color:Color = Color.gray
export var side_count:int = 4

func init_asteroid(size, mass, damage, reset = true):
  self.size = size
  init_points()
  collision.polygon = ShapeLib.shape.make(-size, 0.7, side_count, 0.5)
  hp = mass * hp_multiplier
  set("mass", mass)
  self.og_hp = self.hp
  self.damage = damage
  set("rotation", randf()*PI*2)
  set("angular_velocity", randf()*max_initial_torque / hp)
  collision.set_deferred("disabled", false)
  if reset:
    BulkAnim.fade_in_grow.final_state(self)
  self_modulate = Color.white

func init_points():
  points = ShapeLib.shape.make(-size, 0.7, side_count, 2)
  line_points = points.duplicate()
  line_points.append(line_points[0])

func _draw(): draw()
func draw():
  draw_colored_polygon(points, color)
  draw_polyline(line_points, Color.white, 1, true)

func area_interact(other):
  if hp > 0:
    emit_signal("area_interact", other)
    return true

func area_collide(other, delta):
  if not GameUtils.is_enemy(side, other):
    var damage = other.damage*delta
    return take_damage(other, damage*0.5)
  return take_damage(other, other.damage*delta)

func body_collide(other, dir, damage):
  take_damage(other, damage)

func take_damage(other, other_damage):
  if hp > 0:
    hp -= other_damage
    if hp <= 0:
      destroyed_by(other)
    else:
      update()
      self_modulate.a = lerp(0.3, 1, hp/og_hp)
      set("mass", lerp(0.2, 1, hp/og_hp) * og_hp / hp_multiplier)
  else:
    return 0
  return damage

func destroyed():
  collision.set_deferred("disabled", true)
  BulkAnim.fade_out_shrink.add(self)

func destroyed_by(other):
  destroyed()
  # asteroid explosion sound
#  SoundPlayer.play_audio('collision', global_position, range_lerp(size, 1, 10, 0.5, 1), range_lerp(size, 1, 10, -10, -5))
  emit_signal("destroyed_by", other)
  emit_signal("destroyed_by_")

func hibernate():
  collision.set_deferred("disabled", true)
  set_physics_process(false)
func wake_up():
  collision.set_deferred("disabled", false)
  set_physics_process(true)
