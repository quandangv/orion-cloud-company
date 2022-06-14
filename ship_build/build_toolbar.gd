extends MarginContainer

signal rotation_changed(rotation)
signal selection_changed(selection)

var _pressed_button = null
var rotation = 0

func _ready():
  for button in $container/container/buttons/types.get_children():
    if button is Button:
      button.pressed = false
      button.set_component(button.name)
      button.get_node("label").text = button.name
      button.connect("toggled", self, "_button_toggled", [button])

func _button_toggled(pressed, button):
  if _pressed_button:
    _pressed_button.set_pressed_no_signal(false)
  if pressed:
    _pressed_button = button
  else:
    _pressed_button = null
  rotation = 0
  emit_signal("rotation_changed", rotation)
  emit_signal("selection_changed", get_selected())

func get_selected():
  return _pressed_button.name if _pressed_button else null

func _unhandled_key_input(event):
  if event.pressed:
    if event.scancode == KEY_R:
      rotation = (rotation + (5 if event.shift else 1)) % 6
      emit_signal("rotation_changed", rotation)
    elif event.scancode == KEY_ESCAPE:
      _button_toggled(false, _pressed_button)
