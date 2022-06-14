extends CanvasModulate

func _process(delta):
  color = lerp(color, Color.white, delta)
