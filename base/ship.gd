extends RigidBody2D

signal destroyed
signal bumped(amount)

export var starting_side:String = "friendly"
export var max_capture:int = 10
export var type:String = 'intro_ship'
const border_damage_ratio = 4
const capture_distance = 10
const release_distance_sqr = 90000
const max_opacity = 0.95
const default_color = Color(0.3, 0.3, 0.3)
var damaged_color = Color(0.7, 0, 0, 1)
var border_damage_accum = 0
var inner_damage_accum = 0
var size:float = 2
var damage = 10
var color = null setget set_color
var color_modifier:Color = Color.white setget set_color_modifier
var final_color:Color = default_color
var side:String
var side_layer
var captured = []
var targeted_position
var mark_target:bool setget set_mark_target, get_mark_target
onready var target_marker = $target_marker
onready var controller = get_node_or_null('controller')
onready var rank = $rank
onready var components = $components
onready var collision = $collision

const ship_types = {
  'armored_medium_ship': '{"map":[null,null,{"":"armor","armor":1,"hp":6,"rotation":0},{"":"armor","armor":1,"hp":6,"rotation":0},null,{"":"armor","armor":1,"hp":6,"rotation":0},{"":"core","hp":2,"rotation":0},{"":"armor","armor":1,"hp":6,"rotation":0},{"":"thruster","generators_connected":{"(9, 10)":0},"hp":2,"plasma":"(3,3,0,0)","rotation":0},{"":"generator","hp":2,"plasma":"(0,6,0,0)","plasma_downstream":[[2,2],[0,2]],"rotation":0,"wasted_plasma":"(6,0,0,0)"},{"":"thruster","generators_connected":{"(9, 10)":0},"hp":2,"plasma":"(3,3,0,0)","rotation":0},{"":"armor","armor":1,"hp":6,"rotation":0},{"":"armor","armor":1,"hp":6,"rotation":0},{"":"armor","armor":1,"hp":6,"rotation":0},{"":"armor","armor":1,"hp":6,"rotation":0},null],"mapsize":4}',
  'medium_ship': '{"map":[null,null,{"":"energizer","generators_connected":{"(10, 9)":3},"hp":2,"plasma":"(3,3,3,0)","plasma_downstream":[[3,0]],"plasma_modifier":"(1,0,1,0)","rotation":0,"wasted_plasma":"(3,0,0,0)"},{"":"energizer","hp":2,"nottop":true,"plasma":"(3,3,6,0)","plasma_downstream":[[2,1]],"plasma_modifier":"(1,0,1,0)","rotation":2,"wasted_plasma":"(3,0,0,0)"},null,{"":"generator","covered":[[0,2]],"hp":2,"plasma":"(0,6,0,0)","plasma_downstream":[[0,2],[2,0]],"rotation":0,"wasted_plasma":"(6,0,0,0)"},{"":"energizer","covered":[[0,2]],"hp":2,"nottop":true,"plasma":"(3,3,9,0)","plasma_downstream":[[3,1]],"plasma_modifier":"(1,0,1,0)","rotation":0,"wasted_plasma":"(3,0,0,0)"},{"":"turret","hp":2,"nottop":true,"plasma":"(3,3,9,0)","position":0,"rotation":0},{"":"shield","generators_connected":{"(10, 9)":0,"(10, 10)":0},"hp":2,"plasma":"(3,3,0,0)","rotation":0},{"":"generator","covered":[[0,2]],"hp":2,"plasma":"(0,6,0,0)","plasma_downstream":[[1,3],[0,3],[0,2]],"rotation":0,"wasted_plasma":"(6,0,0,0)"},{"":"energizer","covered":[[0,2]],"hp":2,"nottop":true,"plasma":"(3,3,6,0)","plasma_downstream":[[3,2]],"plasma_modifier":"(1,0,1,0)","rotation":0,"wasted_plasma":"(3,0,0,0)"},{"":"turret","hp":2,"nottop":true,"plasma":"(3,3,6,0)","position":1,"rotation":0},{"":"thruster","covered":[[0,2]],"generators_connected":{"(10, 10)":0},"hp":2,"plasma":"(3,3,0,0)","rotation":0},{"":"energizer","covered":[[0,2]],"generators_connected":{"(10, 10)":3},"hp":2,"plasma":"(3,3,3,0)","plasma_downstream":[[2,2]],"plasma_modifier":"(1,0,1,0)","rotation":5,"wasted_plasma":"(3,0,0,0)"},{"":"core","hp":2,"rotation":0},null],"mapsize":4}',
  'guided_medium_ship': '{"map":[null,null,{"":"energizer","generators_connected":{"(10, 9)":1},"hp":2,"plasma":"(3,3,3,0)","plasma_downstream":[[3,0]],"plasma_modifier":"(1,0,1,0)","rotation":0,"wasted_plasma":"(3,0,2,0)"},{"":"guiding_turret","hp":2,"nottop":true,"plasma":"(1,1,1,0)","position":0,"rotation":0},null,{"":"generator","hp":2,"plasma":"(0,6,0,0)","plasma_downstream":[[2,1],[2,0]],"rotation":0,"wasted_plasma":"(6,4,0,0)"},{"":"energizer","covered":[[1,3]],"generators_connected":{"(10, 9)":1,"(10, 10)":0},"hp":2,"plasma":"(3,3,3,0)","plasma_downstream":[[3,1]],"plasma_modifier":"(1,0,1,0)","rotation":0,"wasted_plasma":"(3,0,2,0)"},{"":"guiding_turret","covered":[[1,3]],"hp":2,"nottop":true,"plasma":"(1,1,1,0)","position":1,"rotation":0},{"":"core","hp":2,"rotation":0},{"":"generator","covered":[[1,3]],"hp":2,"plasma":"(0,6,0,0)","plasma_downstream":[[2,2],[1,3],[0,3],[2,1]],"rotation":0,"wasted_plasma":"(6,0,0,0)"},{"":"energizer","covered":[[1,3]],"generators_connected":{"(10, 10)":1},"hp":2,"plasma":"(3,2,2,0)","plasma_downstream":[[2,3]],"plasma_modifier":"(1,0,1,0)","rotation":1,"wasted_plasma":"(3,0,0,0)"},{"":"guiding_turret","covered":[[1,3]],"hp":2,"nottop":true,"plasma":"(1,1,2,0)","position":2,"rotation":0},{"":"thruster","generators_connected":{"(10, 10)":0},"hp":2,"plasma":"(3,2.5,0,0)","rotation":0},{"":"shield","generators_connected":{"(10, 10)":0},"hp":2,"plasma":"(3,2.5,0,0)","rotation":5},{"":"energizer","covered":[[1,3]],"hp":2,"nottop":true,"plasma":"(3,2,4,0)","plasma_downstream":[[3,2]],"plasma_modifier":"(1,0,1,0)","rotation":5,"wasted_plasma":"(3,0,2,0)"},null],"mapsize":4}',
  'big_ship': '{"map":[null,null,{"":"shield","generators_connected":{"(10, 9)":0},"hp":2,"plasma":"(3,2.5,0,0)","rotation":1},{"":"energizer","covered":[[2,0]],"generators_connected":{"(10, 9)":2.5},"hp":2,"plasma":"(3,2.5,2.5,0)","plasma_downstream":[[4,0]],"plasma_modifier":"(1,0,1,0)","rotation":0,"wasted_plasma":"(3,0,0,0)"},{"":"turret","hp":2,"nottop":true,"plasma":"(3,2.5,2.5,0)","position":0,"rotation":0},null,{"":"thruster","covered":[[2,0]],"generators_connected":{"(9, 10)":0,"(10, 9)":0},"hp":2,"plasma":"(3,3,0,0)","rotation":0},{"":"generator","covered":[[2,0]],"hp":2,"plasma":"(0,6,0,0)","plasma_downstream":[[3,1],[1,1],[2,0],[3,0]],"rotation":0,"wasted_plasma":"(6,0,0,0)"},{"":"energizer","covered":[[2,0]],"generators_connected":{"(10, 9)":1,"(10, 10)":1.5},"hp":2,"plasma":"(3,2.5,2.5,0)","plasma_downstream":[[4,1]],"plasma_modifier":"(1,0,1,0)","rotation":0,"wasted_plasma":"(3,0,0,0)"},{"":"turret","hp":2,"nottop":true,"plasma":"(3,2.5,2.5,0)","position":1,"rotation":0},{"":"core","hp":2,"rotation":0},{"":"generator","covered":[[0,4],[2,0]],"hp":2,"plasma":"(0,6,0,0)","plasma_downstream":[[0,3],[1,1]],"rotation":0,"wasted_plasma":"(6,0,0,0)"},{"":"generator","covered":[[0,4],[2,0]],"hp":2,"plasma":"(0,6,0,0)","plasma_downstream":[[3,2],[2,3],[3,1]],"rotation":0,"wasted_plasma":"(6,0,0,0)"},{"":"energizer","generators_connected":{"(10, 10)":3},"hp":2,"plasma":"(3,3,3,0)","plasma_downstream":[[4,2]],"plasma_modifier":"(1,0,1,0)","rotation":0,"wasted_plasma":"(3,0,0,0)"},{"":"turret","hp":2,"nottop":true,"plasma":"(3,3,3,0)","position":2,"rotation":0},{"":"thruster","covered":[[0,4]],"generators_connected":{"(9, 10)":0,"(9, 11)":0},"hp":2,"plasma":"(3,3,0,0)","rotation":0},{"":"generator","covered":[[0,4]],"hp":2,"plasma":"(0,6,0,0)","plasma_downstream":[[2,3],[1,4],[0,4],[0,3]],"rotation":0,"wasted_plasma":"(6,0,0,0)"},{"":"energizer","covered":[[0,4]],"generators_connected":{"(9, 11)":1,"(10, 10)":1.5},"hp":2,"plasma":"(3,2.5,2.5,0)","plasma_downstream":[[3,3]],"plasma_modifier":"(1,0,1,0)","rotation":0,"wasted_plasma":"(3,0,0,0)"},{"":"turret","hp":2,"nottop":true,"plasma":"(3,2.5,2.5,0)","position":3,"rotation":0},null,{"":"shield","generators_connected":{"(9, 11)":0},"hp":2,"plasma":"(3,2.5,0,0)","rotation":5},{"":"energizer","covered":[[0,4]],"generators_connected":{"(9, 11)":2.5},"hp":2,"plasma":"(3,2.5,2.5,0)","plasma_downstream":[[2,4]],"plasma_modifier":"(1,0,1,0)","rotation":0,"wasted_plasma":"(3,0,0,0)"},{"":"turret","hp":2,"nottop":true,"plasma":"(3,2.5,2.5,0)","position":4,"rotation":0},null,null],"mapsize":5}',
  'big_guided_ship': '{"map":[null,null,{"":"shield","generators_connected":{"(10, 9)":0},"hp":2,"plasma":"(3,2,0,0)","rotation":1},{"":"energizer","covered":[[2,0]],"generators_connected":{"(10, 9)":1},"hp":2,"plasma":"(3,1.666667,1.666667,0)","plasma_downstream":[[4,0]],"plasma_modifier":"(1,0,1,0)","rotation":0,"wasted_plasma":"(3,0,0.666667,0)"},{"":"guiding_turret","hp":2,"nottop":true,"plasma":"(1,1,1,0)","position":0,"rotation":0},null,{"":"thruster","covered":[[2,0]],"generators_connected":{"(10, 9)":0},"hp":2,"plasma":"(3,2,0,0)","rotation":0},{"":"generator","covered":[[2,0]],"hp":2,"plasma":"(0,6,0,0)","plasma_downstream":[[3,1],[1,1],[2,0],[3,0]],"rotation":0,"wasted_plasma":"(6,0,0,0)"},{"":"energizer","covered":[[2,0]],"generators_connected":{"(10, 9)":1,"(10, 10)":0},"hp":2,"plasma":"(3,3,3,0)","plasma_downstream":[[4,1]],"plasma_modifier":"(1,0,1,0)","rotation":0,"wasted_plasma":"(3,0,2,0)"},{"":"guiding_turret","hp":2,"nottop":true,"plasma":"(1,1,1,0)","position":1,"rotation":0},{"":"armor","armor":1,"hp":6,"rotation":0},{"":"core","covered":[[0,4],[2,0]],"hp":2,"rotation":0},{"":"generator","covered":[[0,4],[2,0]],"hp":2,"plasma":"(0,6,0,0)","plasma_downstream":[[3,2],[2,3],[3,1]],"rotation":0,"wasted_plasma":"(6,5,0,0)"},{"":"energizer","generators_connected":{"(10, 10)":1},"hp":2,"plasma":"(3,3,3,0)","plasma_downstream":[[4,2]],"plasma_modifier":"(1,0,1,0)","rotation":0,"wasted_plasma":"(3,0,2,0)"},{"":"guiding_turret","hp":2,"nottop":true,"plasma":"(1,1,1,0)","position":2,"rotation":0},{"":"thruster","covered":[[0,4]],"generators_connected":{"(9, 11)":0},"hp":2,"plasma":"(3,2,0,0)","rotation":0},{"":"generator","covered":[[0,4]],"hp":2,"plasma":"(0,6,0,0)","plasma_downstream":[[2,3],[1,4],[0,4],[0,3]],"rotation":0,"wasted_plasma":"(6,0,0,0)"},{"":"energizer","covered":[[0,4]],"generators_connected":{"(9, 11)":1,"(10, 10)":0},"hp":2,"plasma":"(3,3,3,0)","plasma_downstream":[[3,3]],"plasma_modifier":"(1,0,1,0)","rotation":0,"wasted_plasma":"(3,0,2,0)"},{"":"guiding_turret","hp":2,"nottop":true,"plasma":"(1,1,1,0)","position":3,"rotation":0},null,{"":"shield","generators_connected":{"(9, 11)":0},"hp":2,"plasma":"(3,2,0,0)","rotation":5},{"":"energizer","covered":[[0,4]],"generators_connected":{"(9, 11)":1},"hp":2,"plasma":"(3,1.666667,1.666667,0)","plasma_downstream":[[2,4]],"plasma_modifier":"(1,0,1,0)","rotation":0,"wasted_plasma":"(3,0,0.666667,0)"},{"":"guiding_turret","hp":2,"nottop":true,"plasma":"(1,1,1,0)","position":4,"rotation":0},null,null],"mapsize":5}',
  'big_fast_guided_ship': '{"map":[null,null,{"":"shield","generators_connected":{"(10, 9)":0},"hp":2,"plasma":"(3,3,0,0)","rotation":1},{"":"energizer","covered":[[2,0]],"generators_connected":{"(10, 9)":1},"hp":2,"plasma":"(3,2.5,2.5,0)","plasma_downstream":[[4,0]],"plasma_modifier":"(1,0,1,0)","rotation":0,"wasted_plasma":"(3,0,0,0)"},{"":"energizer","hp":2,"nottop":true,"plasma":"(3,2.5,5,0)","plasma_downstream":[[3,1]],"plasma_modifier":"(1,0,1,0)","rotation":2,"wasted_plasma":"(3,0,0,0)"},null,{"":"thruster","covered":[[2,0]],"generators_connected":{"(9, 10)":0,"(10, 9)":0},"hp":2,"plasma":"(3,3,0,0)","rotation":0},{"":"generator","covered":[[2,0]],"hp":2,"plasma":"(0,6,0,0)","plasma_downstream":[[2,2],[1,1],[2,0],[3,0]],"rotation":0,"wasted_plasma":"(6,1.5,0,0)"},{"":"accelerator","covered":[[2,0]],"hp":2,"nottop":true,"plasma":"(3,2.5,5,2.5)","plasma_downstream":[[4,1]],"plasma_modifier":"(1,0,0,1)","rotation":0,"wasted_plasma":"(3,0,3,1.5)"},{"":"guiding_turret","hp":2,"nottop":true,"plasma":"(1,1,2,1)","position":0,"rotation":0},{"":"core","hp":2,"rotation":0},{"":"generator","covered":[[0,4],[2,0]],"hp":2,"plasma":"(0,6,0,0)","plasma_downstream":[[2,2],[0,3],[1,1]],"rotation":0,"wasted_plasma":"(6,0,0,0)"},{"":"energizer","covered":[[0,4],[2,0]],"generators_connected":{"(9, 10)":1,"(9, 11)":0,"(10, 9)":0},"hp":2,"plasma":"(3,3,3,0)","plasma_downstream":[[3,2]],"plasma_modifier":"(1,0,1,0)","rotation":0,"wasted_plasma":"(3,0,0,0)"},{"":"accelerator","hp":2,"nottop":true,"plasma":"(3,3,3,3)","plasma_downstream":[[4,2]],"plasma_modifier":"(1,0,0,1)","rotation":0,"wasted_plasma":"(3,0,2,2)"},{"":"guiding_turret","hp":2,"nottop":true,"plasma":"(1,1,1,1)","position":1,"rotation":0},{"":"thruster","covered":[[0,4]],"generators_connected":{"(9, 10)":0,"(9, 11)":0},"hp":2,"plasma":"(3,3,0,0)","rotation":0},{"":"generator","covered":[[0,4]],"hp":2,"plasma":"(0,6,0,0)","plasma_downstream":[[1,4],[0,4],[0,3],[2,2]],"rotation":0,"wasted_plasma":"(6,1.5,0,0)"},{"":"accelerator","covered":[[0,4]],"hp":2,"nottop":true,"plasma":"(3,2.5,5,2.5)","plasma_downstream":[[3,3]],"plasma_modifier":"(1,0,0,1)","rotation":0,"wasted_plasma":"(3,0,3,1.5)"},{"":"guiding_turret","hp":2,"nottop":true,"plasma":"(1,1,2,1)","position":2,"rotation":0},null,{"":"shield","generators_connected":{"(9, 11)":0},"hp":2,"plasma":"(3,3,0,0)","rotation":5},{"":"energizer","covered":[[0,4]],"generators_connected":{"(9, 11)":1},"hp":2,"plasma":"(3,2.5,2.5,0)","plasma_downstream":[[2,4]],"plasma_modifier":"(1,0,1,0)","rotation":0,"wasted_plasma":"(3,0,0,0)"},{"":"energizer","hp":2,"nottop":true,"plasma":"(3,2.5,5,0)","plasma_downstream":[[2,3]],"plasma_modifier":"(1,0,1,0)","rotation":4,"wasted_plasma":"(3,0,0,0)"},null,null],"mapsize":5}',
}

func set_mark_target(value):
  if target_marker:
    target_marker.active = value
func get_mark_target():
  return target_marker != null and target_marker.active

func serialize():
  return {"position": global_position, "rotation":global_rotation, "type":type}

func init_deserialize(data):
  type = data["type"]

func deserialize(data):
  global_position = data["position"]
  global_rotation = data["rotation"]

func _ready():
  for type in ship_types:
    ship_types[type] = ComponentUtils.reanalyze_ship(parse_json(ship_types[type]))
    print(type,ship_types[type]['stats'])
  load_ship_type(type)

func load_ship_type(ship_type):
  type = ship_type
  components.load_ship(ship_types[ship_type])

func offer_capture(other):
  for i in range(len(captured)-1, -1, -1):
    if (captured[i].global_position - global_position).length_squared() > release_distance_sqr:
      captured[i].released()
      captured.remove(i)
  if len(captured) < max_capture:
    captured.append(other)
    return Vector2(capture_distance, 0).rotated(PI*2/max_capture * len(captured))
func demand_release(other):
  var index = captured.find(other)
  if index >= 0:
    captured.remove(index)
  return true

func set_side(side):
  self.side = side
  if side_layer == null:
    side_layer = GameUtils.get_layer_index(side)
  self.color = GameUtils.ship_colors.get(side, Color.gray)

func set_color(value):
  if value != color:
    color = value
    update_final_color()
    update()

func set_color_modifier(value):
  if value != color_modifier:
    color_modifier = value
    update_final_color()
    update()

func update_final_color():
  var opaque = (color * color_modifier) if color else default_color
  final_color.r = opaque.r
  final_color.g = opaque.g
  final_color.b = opaque.b

func reset():
  components.reset()
  visible = false
  collision.set_deferred('disabled', false)
  BulkAnim.fade_in_grow.add(self)
  self.color = null
  set_side(starting_side)
  inner_damage_accum = 1
  border_damage_accum = 1
  final_color.a = max_opacity
  for i in range(len(captured)-1, -1, -1):
    captured[i].released()
    captured.remove(i)
  if controller:
    controller.wake_up()

func init(size):
  self.size = size
  $collision.scale = Vector2(size, size)
  rank.scale = Vector2(1, 1) * size * 0.012
  calc_points(0)

func calc_points(roundness=0):
  points = ShapeLib.shape.make(-size*1.1, roundness*0.2, 6, 2)
  points.append(points[0])
  update()

func ship_destroyed(completely = false):
  if side != "junk":
    self.color = null
    if controller:
      controller.hibernate()
    set_side('junk')
  if completely:
    collision.set_deferred('disabled', true)
    BulkAnim.fade_out_grow.add(self)
func bulk_anim_done(name):
  if 'fade_out' in name:
    emit_signal("destroyed")

func add_border_damage(damage):
  border_damage_accum += border_damage_ratio * damage / size
  
func set_fill_alpha(value):
  final_color.a = clamp(lerp(0.2, max_opacity, value), 0, 1)

func area_interact(other):
  return GameUtils.is_enemy(side, other)
func area_collide(other, delta):
  if not Multiplayer.active or is_network_master():
    var other_damage = other.damage * delta
    assert(other_damage >= 0)
    var actual_damage = components.take_damage((-other.linear_velocity).angle(), other_damage)
    var damage_back = damage * actual_damage / other_damage
    if Multiplayer.active:
      rpc("show_take_damage", actual_damage)
      other.rpc("take_damage", damage_back * delta)
    return damage_back
  return 0

func body_collide(other, dir, damage):
  emit_signal("bumped", dir)
  for _i in range(100):
    damage -= components.take_damage((other.global_position - global_position).angle(), damage)
    if damage <= 0 or components.real_mass <= 0: break

puppet func show_take_damage(damage):
  add_border_damage(damage)

func _process(delta):
  var update = false
  if border_damage_accum > 0:
    update = true
    border_damage_accum = max(border_damage_accum - delta, 0)
    rank.modulate = lerp(Color.white, damaged_color * lerp(final_color, Color.white, inner_damage_accum), min(border_damage_accum, 1))
  if inner_damage_accum > 0:
    update = true
    inner_damage_accum = max(inner_damage_accum - delta, 0)
  if update:
    self.update()

var points
func _draw():
  draw_colored_polygon(points, lerp(final_color, Color.white, clamp(inner_damage_accum, 0, 1)))
  draw_polyline(points, rank.modulate, 1, true)

# multiplayer synchronization

var target_velocity = null
var position_diff:Vector2
func _sync():
  rpc_unreliable("request_sync", global_position, linear_velocity)
puppet func request_sync(pos, velocity):
  target_velocity = velocity
  position_diff = pos - global_position

func _integrate_forces(state):
  if target_velocity != null:
    state.linear_velocity = target_velocity
    target_velocity = null
  if position_diff != Vector2.ZERO:
    var change = position_diff * 0.05
    state.transform.origin += change
    position_diff -= change
    if position_diff.length_squared() < 0.0001:
      position_diff = Vector2.ZERO
