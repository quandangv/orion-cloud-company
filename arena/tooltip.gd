extends Node

onready var parent = get_parent()
var hovered = false
var triggered = false

func trigger_entered():
  triggered = true
  BulkAnim.fade_in.add(parent)

func trigger_exited():
  print('trigger exit ', hovered)
  triggered = false
  if not hovered:
    BulkAnim.fade_out.add(parent)

func parent_entered():
  hovered = true
  BulkAnim.fade_in.add(parent)

func parent_exited():
  hovered = false
  if not triggered:
    BulkAnim.fade_out.add(parent)
