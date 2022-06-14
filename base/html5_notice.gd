extends Label

export(Array, NodePath) var closed_nodes

func _ready():
  if OS.get_name() == "HTML5":
    visible = true
    for item in closed_nodes:
      get_node(item).visible = false
  else:
    queue_free()
