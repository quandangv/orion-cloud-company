extends Node

onready var parent = get_parent()
const check_enemy_interval = 20
var check_enemy_count = randi() % check_enemy_interval

const keep_target_preference = 10 # preference to keep the target even when there are nearer targets

func target_condition(obj):
  return obj.is_inside_tree() and obj.side != 'junk'

func _process(delta):
  check_enemy_count += 1
  if check_enemy_count >= check_enemy_interval:
    check_enemy()
    check_enemy_count = 0
func check_enemy():
  var bodies = parent.detector.get_overlapping_bodies()
  var min_dists = {}
  var chosen_bodies = {}
  for body in bodies:
    if body != parent and GameUtils.is_enemy(parent.parent.side, body) and target_condition(body):
      var dist = (body.global_position - parent.parent.global_position).length() / body.size
      if body == parent.target_obj:
        dist -= keep_target_preference / max(parent.thrust/parent.parent.mass, 1)
      var rank = parent.get_target_rank(body)
      if rank in min_dists:
        var min_dist = min_dists[rank]
        if dist >= min_dist:
          continue
      min_dists[rank] = dist
      chosen_bodies[rank] = body
  if len(chosen_bodies) == 0:
    parent.remove_target()
    return
  for i in range(parent.max_rank):
    var new_target = chosen_bodies.get(i)
    if new_target:
      parent.set_target(new_target)
      return

func _ready():
  parent.connect("wake_up", self, "check_enemy")
  parent.connect("target_removed", self, "check_enemy")
