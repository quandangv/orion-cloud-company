extends Node

export(Array, NodePath) var excluded

var animated = []

func _ready():
  for i in range(len(excluded)):
    excluded[i] = get_node(excluded[i])
  set_process(false)

func has(obj):
  return obj in animated

func interrupt(obj):
  animated.erase(obj)

func add(obj):
  for node in excluded:
    if node.has(obj):
      node.interrupt(obj)
  if not animated.has(obj):
    animated.append(obj)
    on_add(obj)
  set_process(true)

func animate(obj, delta):
  return true

func on_add(obj):
  pass

func final_state(obj):
  pass

func _process(delta):
  var nothing = true
  for i in range(len(animated)-1, -1, -1):
    var obj = animated[i]
    if animate(obj, delta):
      final_state(obj)
      if obj.has_method('bulk_anim_done'):
        obj.bulk_anim_done(name)
      animated.remove(i)
    else:
      nothing = false
  if nothing:
    set_process(false)

