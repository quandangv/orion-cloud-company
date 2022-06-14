extends VisibilityNotifier2D

export var grace_period:float = 10
export var initial_wait:float = 0
var wait:float

func _enter_tree():
  wait = -initial_wait

func _process(delta):
  if not is_on_screen():
    wait += delta
    if wait > grace_period:
      get_parent().destroyed()
  else:
    wait = 0
