extends ProgressBar

onready var anim = get_node("anim")
onready var active = visible

func set_value(value):
  self.value = value
  $value.text = str(stepify(value, 0.1))

func set_visibility(value):
  if active != value:
    active = value
    if value:
      anim.play("appear")
    else:
      anim.play_backwards("appear")
