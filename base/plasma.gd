extends "polygon.gd"

export var collateral_rate:float = 0.9
var lifetime:float
var hp:float
var og_hp:float
var side:String
var source
var color:Color
var linear_velocity:Vector2
onready var fill = $fill

var overlap_bodies = []
var overlap_areas = []

func degradation_rate():
  return 0.5 * lifetime

func _ready():
  connect("area_entered", self, "area_entered")
  connect("area_exited", self, "area_exited")
  connect("body_entered", self, "body_entered")
  connect("body_exited", self, "body_exited")

func init_plasma(size, hp, velocity):
  self.size = size
  collision.shape.radius = size
  self.lifetime = 0
  self.hp = hp
  self.og_hp = hp
  self.linear_velocity = velocity

func _process(delta):
  update()
func _physics_process(delta):
  position += linear_velocity * delta
  var damage_amount = 0
  for other in overlap_areas:
    damage_amount += other.damage
    assert(not is_nan(other.damage))
  for other in overlap_bodies:
    var other_damage = other.area_collide(self, delta)
    assert(not is_nan(other_damage))
    damage_amount += other_damage
  lifetime += delta
  damage_amount += degradation_rate()
  take_damage(damage_amount * delta)

puppetsync func master_destroyed(current_damage):
  damage = current_damage
  destroyed()

remote func take_damage(amount):
  if is_nan(hp):
    assert(false, "plasma hp is NAN")
    hp = 0
  assert(not is_nan(amount))
  if hp > 0:
    hp -= amount
    if hp <= 0:
      damage *= pow(collateral_rate, -hp)
      assert(not is_inf(damage))
      if not Multiplayer.active:
        depleted()
      elif is_network_master():
        rpc("master_destroyed", damage)
    else:
      color.a = lerp(0.2, 1, hp/og_hp)
  elif damage:
    damage *= pow(collateral_rate, amount)
    assert(not is_inf(damage))

func depleted():
  destroyed()

func area_entered(other):
  if GameUtils.is_enemy(side, other):
    SoundPlayer.play_audio("plasma_area", global_position)
    overlap_areas.push_back(other)

func area_exited(other):
  if other in overlap_areas:
    overlap_areas.erase(other)

func body_entered(other):
  if other.has_method("area_interact") and other.area_interact(self):
    overlap_bodies.push_back(other)
    if hp > 0:
      SoundPlayer.play_audio("plasma_body", global_position, hp/og_hp)

func body_exited(other):
  if other in overlap_bodies:
    overlap_bodies.erase(other)
