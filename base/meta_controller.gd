extends Node2D

onready var parent = get_parent().get_parent()

func _ready():
  parent.connect("design_changed", self, "_load")
  get_parent().connect("wake_up", self, "wake_up")

func wake_up():
  parent.color = GameUtils.ship_colors.get("controlled", Color.gray)
  _load()

func _load():
  $shape.shape.radius = parent.size
