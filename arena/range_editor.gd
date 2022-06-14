extends HBoxContainer

signal low_changed(delta)
signal high_changed(delta)

func set_visibility_state(value):
  $low.visible = value
  $high.visible = value
  $label.visible = not value

func change_low(delta):
  emit_signal('low_changed', delta)

func change_high(delta):
  emit_signal('high_changed', delta)

func update_text(value:Vector2):
  $range.text = str(value.x) + '-' + str(value.y)
