extends "base_bot_controller.gd"

signal start_firing
signal hibernate
signal wake_up
signal target_removed
signal idle(delta)
signal before_combine_movement

var movement:Vector2
const firing = false
var angle:float
const stop_multiplier = 1
const thrust_to_rotate_speed = 3
const speed_limit = INF

var target_obj = null
var target_rank:int
var thrust:float
var waited:float
var current_firing_wait:float
var target_speed:Vector2
var bullet_speed_approx:float
var turret_count:int
var ignore_junk:bool = true
var active:bool = false

var strafe_time:float
var strafe_direction = 1
const strafe_max = 3

var firing_wait  # time to wait for turret to cool before firing again
var firing_wait_random = [6, 9] # randomize waiting time for unpredictability
const firing_angle = 0.4 # multiplier of the acceptable turret angular precision to fire
export(Array, float) var distance_kept = [10, 3] # distance to keep from the target instead of heabutting them
const base_bullet_speed = 8 # used along with turret stats to calculate approximate bullet speed
const strafe_force = [70, 0]

func stats_changed():
  """Extract the stats from our ship for better extrapolation"""
  turret_count = 0
  var avg_turret_speed = 0
  var avg_turret_cooldown = 0
  for turret in parent.components.turrets:
    if abs(turret.rotation) < 0.001 and not is_nan(turret.reload_time):
      turret_count += 1
      avg_turret_speed += turret.base_speed
      avg_turret_cooldown += turret.turret_cooldown_speed
  if turret_count and avg_turret_speed > 0:
    avg_turret_speed /= turret_count
    avg_turret_cooldown /= turret_count
    bullet_speed_approx = base_bullet_speed * avg_turret_speed
    firing_wait = 6 / sqrt(avg_turret_cooldown)
  else:
    hibernate()
  thrust = parent.components.thruster.thrust

func hibernate():
  active = false
  if parent.components.is_connected("stats_changed", self, "stats_changed"):
    parent.components.disconnect("stats_changed", self, "stats_changed")
  set_physics_process(false)
  set_process(false)
  for child in get_children():
    child.set_physics_process(false)
    child.set_process(false)
  movement = Vector2.ZERO
  emit_signal("hibernate")
func wake_up():
  active = true
  if not parent.components.is_connected("stats_changed", self, "stats_changed"):
    parent.components.connect("stats_changed", self, "stats_changed")
  stats_changed()
  set_physics_process(true)
  set_process(true)
  angle = parent.global_rotation
  movement = Vector2.ZERO
  for child in get_children():
    child.set_physics_process(true)
    child.set_process(true)
  emit_signal("wake_up")

func angle_diff(a, b):
  return fmod(a - b + PI, PI*2) - PI

const max_rank = 2
func get_target_rank(obj):
  var turrets = obj.get('turrets')
  if turrets:
    for turret in turrets:
      if not is_nan(turret.reload_time):
        return 0
  return 1

var check_target_wait:float
const check_target_interval = 0.1
const focus_period = 0.1
var diff_norm:Vector2
var diff_length:float
var new_movement:Vector2
func _physics_process(delta):
  strafe_time -= delta
  if strafe_time <= 0:
    strafe_time = randf() * strafe_max
    strafe_direction = randi() % 3 - 1
  waited += delta
  if target_obj != null:
    if !target_obj.is_inside_tree() or (ignore_junk and target_obj.side == "junk"):
      remove_target()
    else:
      var target_accel = target_obj.linear_velocity - target_speed
      target_speed = target_obj.linear_velocity
      var parent_speed = parent.linear_velocity
      if current_firing_wait - waited < focus_period or check_target_wait > check_target_interval:
        irregular_process(target_accel)
      else:
        check_target_wait += delta
      if waited >= current_firing_wait and (target_speed - parent_speed).dot(diff_norm) < bullet_speed_approx: # only fire if our projectiles can actually close the distance to them
        var distance = max(diff_length - parent.size - target_obj.size, 0.00000001) # modify the distance to decrease the turret angular precision in close range
        var acceptable_angle = asin(clamp(firing_angle * target_obj.size / sqrt(distance), 0, 1))
        if abs(angle_diff(angle, parent.global_rotation)) < acceptable_angle:
          emit_signal("start_firing") # finally, fire the turret
          current_firing_wait = firing_wait * log(distance / target_obj.size) / rand_range(firing_wait_random[0], firing_wait_random[1])
          waited = 0
  else:
    new_movement = Vector2.ZERO
  emit_signal("before_combine_movement")
  movement = combine_movement(new_movement * parent.mass / 1000) # combine with the movement from the base
  if movement.length_squared() < 0.0001:
    emit_signal("idle", delta)

func irregular_process(target_accel):
  if bullet_speed_approx == 0:
    hibernate()
    return
  var parent_speed = parent.linear_velocity
  new_movement = Vector2.ZERO
  check_target_wait = 0
  var diff = target_obj.global_position - global_position
  diff -= diff.normalized() * parent.size # Approximate the distance from our turret to the target, which is more accurate than the distance from our center
  diff = GameUtils.extrapolate(diff, target_speed, target_accel, bullet_speed_approx, parent_speed)
  diff_length = diff.length()
  if diff_length > 1000000000:
    diff_length = 1000000000
    diff_norm = Vector2.RIGHT
    diff = Vector2(1000000000, 0)
  else:
    diff_norm = diff / diff_length
  # movement
  var movement_target = diff_norm * (log(diff_length / (distance_kept[target_rank] * parent.size)))*50
  new_movement = movement_target - parent_speed
  if new_movement.length() < thrust*10: # if we don't need to move much, randomly perform one of our idle action
    if strafe_direction != 0: # strafing to dodge projectiles
      new_movement += Vector2(-movement_target.y, movement_target.x).normalized() * strafe_force[target_rank] * strafe_direction
    elif parent.targeted_position != null: # move toward the anchor
      var back = parent.targeted_position - global_position
      if abs(diff_norm.dot(back.normalized())) < 0.8: # only do this if it doesn't change our distance to the target by much
        new_movement += back - parent.linear_velocity
      else:
        strafe_time = 0
  # angle
  angle = GameUtils.moving_aim(parent_speed + new_movement*0.025 * turret_count, diff, bullet_speed_approx)
  assert(not is_nan(angle))

func set_target(new_target):
  if new_target != target_obj:
    if new_target == null:
      remove_target()
    else:
      target_obj = new_target
      target_rank = get_target_rank(new_target)
      target_speed = target_obj.linear_velocity

func remove_target():
  if target_obj != null:
    target_obj = null
    emit_signal("target_removed")
