extends Button

signal press_original
signal press_other

export var other_text:String
onready var original_text:String = text

var is_original = true setget set_is_original

func _ready():
  toggle_mode = false

func _pressed():
  if is_original:
    emit_signal("press_original")
  else:
    emit_signal("press_other")

func set_is_original(value):
  if value != is_original:
    is_original = value
    if is_original:
      text = original_text
    else:
      text = other_text
