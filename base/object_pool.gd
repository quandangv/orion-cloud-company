extends Node

export(PackedScene) var scene
var pool = []

func _create():
  var object = scene.instance()
  add_child(object)
  if object.has_signal("destroyed"):
    object.connect("destroyed", self, "_recycle", [object])
  return object

func _recycle(instance):
  if !instance.has_meta("recycled"):
    instance.set_meta("recycled", true)
    remove_child(instance)
    pool.append(instance)

func get_object():
  var object
  if len(pool) == 0:
    object = _create()
  else:
    object = pool.pop_back()
    add_child(object)
  object.remove_meta("recycled")
  return object
