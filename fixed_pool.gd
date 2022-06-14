extends Node

export(PackedScene) var scene
export var size:int = 20
var pool = []

func _ready():
  for i in range(size):
    var object = scene.instance()
    add_child(object)
    pool.append(object)
    if object.has_signal("destroyed"):
      object.connect("destroyed", self, "_recycle", [object])

func _recycle(instance):
  if !instance.has_meta("recycled"):
    instance.set_meta("recycled", true)
    pool.append(instance)

func get_object():
  var object = pool.pop_back()
  if object == null:
    return null
  object.remove_meta("recycled")
  return object
