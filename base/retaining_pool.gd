extends Node

export(PackedScene) var scene
var pool = []

func _create():
  var instance = scene.instance()
  add_child(instance)
  if instance.has_signal("destroyed"):
    instance.connect("destroyed", self, "_recycle", [instance])
  return instance

func _recycle(instance):
  if !instance.has_meta("recycled"):
    instance.set_meta("recycled", true)
    instance.set_physics_process(false)
    instance.set_process(false)
    pool.append(instance)

func get_object():
  var instance
  if len(pool) == 0:
    instance = _create()
  else:
    instance = pool.pop_back()
  instance.set_physics_process(true)
  instance.set_process(true)
  instance.remove_meta("recycled")
  return instance
