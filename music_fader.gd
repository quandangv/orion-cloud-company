extends AudioStreamPlayer

export var fade_speed_db:float = 20

func fade():
  set_process(true)

func restore(volume_db = 0):
  set_process(false)
  self.volume_db = volume_db

func _process(delta):
  volume_db -= delta * fade_speed_db

func _ready():
  set_process(false)
