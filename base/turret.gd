extends Node2D

const turret_color = Color("FFFFFF")
const turret_hot_color = Color("FF4444")
const base_spread = 1.4
const base_fire_delay = 0.1
const turret_cooldown_base = 0.6
var thrust_multiplier:float = 1.2
onready var parent = get_parent()
onready var timer = $timer
onready var turret = $shape
var plasma_pool = null

var base_speed = 10
var reload_time:float = NAN
var plasma_hp:float = 12
var plasma_damage:float = 30
var fire_delay:float = 0
var turret_cooldown_speed:float
var wait_before_fire:float = -1

var fire_interval = 0
var queued_shots = 0
const max_queued_time = 0.5
var max_queued_shots:int
var plasma_mask
var plasma_layer
var buildup:float

func _ready():
  if parent.controller:
    parent.controller.connect("start_firing", self, "start_firing")
  timer.connect("timeout", self, "_on_fire_timer")

func _physics_process(delta):
  fire_interval += delta * turret_cooldown_speed
  turret.color = lerp(turret_hot_color, turret_color, clamp(fire_interval, 0, 4)/4)
  if wait_before_fire >= 0:
    if wait_before_fire < fire_delay:
      wait_before_fire += delta
    else:
      _fire()
      wait_before_fire = -1

func init(component):
  var size = 1
  var plasma_type = 'normal' if component[''] == 'turret' else 'guided'
  var stats = component["_plasma"]
  var squeeze = component["_squeeze"]
  var position = component["position"]
  var spread = clamp(inverse_lerp(24, 0, stats.supply), 0, 1)
  var base_width = size * lerp(3, 1, spread)
  var muzzle_width = size * lerp(4, 1, spread) if stats.supply > 0 else 0.2
  var length = size * lerp(8, 2, spread)
  self.rotation = component["rotation"] * PI/3
  self.position = Vector2((parent.size * cos(PI/6) + length), (position-(squeeze-1)/2.0) * parent.size / squeeze*0.8).rotated(self.rotation)
  self.plasma_pool = Pools.plasma[plasma_type]
  if stats.supply:
    var speed = stats.speed / stats.supply
    var energy = stats.energy / stats.supply
    if plasma_type == 'guided':
      self.base_speed = 6 + speed * 3
      self.thrust_multiplier = 1 + speed * 1
      parent.mark_target = true
    else:
      self.base_speed = 6 + speed * 6
    self.plasma_damage = 10 * (1 - pow(0.9, energy)) / (1 - 0.9)
    self.reload_time = 2.0/stats.supply
    self.turret_cooldown_speed = stats.supply*2
    self.max_queued_shots = round(max_queued_time / reload_time)
  else:
    self.reload_time = NAN
  self.plasma_hp = 1.5 * size
  self.fire_delay = base_fire_delay * position
  self.plasma_mask = GameUtils.get_plasma_mask(parent.side_layer)
  self.plasma_layer = GameUtils.get_plasma_layer(parent.side_layer)
  var points = PoolVector2Array()
  points.push_back(Vector2(-length, base_width))
  points.push_back(Vector2(-length, -base_width))
  points.push_back(Vector2(0, -muzzle_width))
  points.push_back(Vector2(0, muzzle_width))
  turret.polygon = points
  turret.color = turret_color
  set_physics_process(true)
  visible = true
  timer.wait_time = reload_time
  timer.stop()

func hibernate():
  set_physics_process(false)
  reload_time = NAN
  visible = false

func _on_fire_timer():
  if abs(timer.wait_time - fire_delay) > 0.0001:
    if not parent.controller.firing:
      if queued_shots <= 0:
        timer.stop()
        return
      else:
        queued_shots -= 1
    pre_fire()

func pre_fire():
  var turret_heat = pow(turret_cooldown_base, fire_interval)
  turret_heat += 1
  buildup = clamp(1 / turret_heat, 0, 1)
  wait_before_fire = fire_delay * lerp(0, 0.9, buildup)
  fire_interval = log(turret_heat)/log(turret_cooldown_base)

puppetsync func _fire(plasma_name = null):
  var speed = base_speed * exp(lerp(0, 2.5, buildup))
  var velocity = Vector2(speed, 0).rotated(self.global_rotation\
      + (randf()-0.5) * (1 - buildup) * base_spread) + parent.linear_velocity
  $audio.play()
  var plasma = plasma_pool.get_plasma(parent, plasma_hp, plasma_damage * buildup, self.global_position, velocity)
  if "target" in plasma:
    plasma.target = parent.controller.target_obj
    plasma.thrust = speed * thrust_multiplier
  plasma.collision_mask = plasma_mask
  plasma.collision_layer = plasma_layer
  if plasma_name != null:
    plasma.name = plasma_name

func start_firing():
  if not is_nan(reload_time):
    if timer.is_stopped():
      pre_fire()
      timer.start()
      queued_shots = 0
    elif queued_shots < max_queued_shots:
      queued_shots += 1
