extends Node2D

var movement_contribution:Vector2
const weight = 10

var tracked_projectiles = []
var tracked_bodies = []
var dodge_tmp = []
var dodge_count:int = randi() % dodge_interval
const dodge_interval = 13
const max_tracked_projectiles = 9
const max_tracked_bodies = 15
const safe_distance_ratio = 2
const max_speed_factor = 1000000
var max_speed:float = INF
const safe_body_distance_ratio = 0.0005

onready var parent = get_parent()
onready var detector = $detector
export var detect_radius:float = 150
export var dodge_bodies:bool = true
export var dodge_enemies:bool = true

func _ready():
  detector.connect("area_entered", self, "area_entered")
  detector.connect("area_exited", self, "area_exited")
  if dodge_bodies:
    detector.connect("body_entered", self, "body_entered")
    detector.connect("body_exited", self, "body_exited")
  detector.scale = Vector2(detect_radius, detect_radius)

func _process(delta):
  dodge_count += 1
  if dodge_count > dodge_interval:
    update_movement()
    dodge_count = 0

func update_movement():
  if is_inside_tree():
    movement_contribution = -GameUtils.dodge_projectiles(parent, safe_distance_ratio, tracked_projectiles, dodge_tmp, max_tracked_projectiles, 2)
    var body_dodge = GameUtils.dodge_bodies(parent, safe_body_distance_ratio, tracked_bodies, dodge_tmp, max_tracked_bodies, 2)
    max_speed = max_speed_factor / body_dodge.z if body_dodge.z else INF
    movement_contribution -= Vector2(body_dodge.x, body_dodge.y)

func combine_movement(movement):
  var result = movement + movement_contribution * weight
  var self_speed = parent.linear_velocity.length()
  if self_speed > max_speed:
    result -= parent.linear_velocity * (self_speed - max_speed)
  return result

func area_entered(projectile):
  if GameUtils.is_enemy(parent.side, projectile):
    tracked_projectiles.push_back(projectile)
    dodge_count += dodge_interval/2

func area_exited(projectile):
  var index = tracked_projectiles.find(projectile)
  if index >= 0:
    tracked_projectiles.remove(index)

func body_entered(body):
  if (dodge_enemies or not GameUtils.is_enemy(parent.side, body)) and body != parent:
    tracked_bodies.push_back(body)
    dodge_count += dodge_interval/2

func body_exited(body):
  var index = tracked_bodies.find(body)
  if index >= 0:
    tracked_bodies.remove(index)
