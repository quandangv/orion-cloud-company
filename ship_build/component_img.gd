extends Node

export var img_root = ""
onready var top:Sprite = get_node(img_root + "top")
onready var base:Sprite = get_node(img_root + "base")

func set_component(type):
  var component = ComponentUtils.component_dict[type]
  top.texture = component.top_texture
  base.texture = component.bottom_texture
