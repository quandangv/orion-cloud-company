tends Node2D

signal finished
export var speed:float = 1000
export var time:float = 1
export var color:Color = Color.white
var current_time = 0

func _ready():
  set_process(false)
func _process(delta):
  current_time += delta
  if current_time >= time:
    set_process(false)
    emit_signal("finished")
  update()
func _draw():
  draw_circle(Vector2.ZERO, current_time * speed, color)

func wake_up():
  set_process(true)
