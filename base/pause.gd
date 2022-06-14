extends Control

export var resume_icon:Texture
var pause_icon
onready var pause = $pause
onready var exit = $exit

func _ready():
  pause_icon = pause.icon

func pause_changed(paused):
  if paused:
    pause.icon = resume_icon
    pause.text = "RESUME"
    $anim.play("pause_menu")
  else:
    pause.icon = pause_icon
    pause.text = "PAUSE"
    $anim.play_backwards("pause_menu")
  get_tree().paused = paused

func _exit_tree():
  get_tree().paused = false
