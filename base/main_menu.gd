extends Label

func _ready():
  SceneManager.play_scene_music("main_menu")
func play():
  SceneManager.fade_load("main_menu", "intro")


func multiplay():
  SceneManager.fade_load("main_menu", "sandbox")
