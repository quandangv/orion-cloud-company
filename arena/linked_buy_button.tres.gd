extends "res://arena/buy_button.gd"

export var price_unit:int = 5
export var price_level:float = 1 setget set_price_level
export(Array, NodePath) var linked

func _ready():
  for i in range(len(linked)):
    linked[i] = get_node(linked[i])
  set_price_level(price_level)

func buy():
  for node in linked:
    node.price_level += 1

func set_price_level(value):
  price_level = value
  self.price = price_unit * price_level
