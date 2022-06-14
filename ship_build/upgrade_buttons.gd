extends Control

onready var anim = $anim
onready var help = $help
var type

func set_help(prefix):
  help.bbcode_text = "[b]" + tr(prefix + type).to_upper() + "[/b] " + tr(prefix + type + "_help")

func appear(type):
  disappear()
  if anim.is_playing():
    yield(anim, "animation_finished")
  self.type = type
  set_help("")
  anim.queue("appear")

func disappear():
  if visible:
    anim.play_backwards("appear")
