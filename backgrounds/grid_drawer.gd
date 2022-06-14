extends Node2D

export var size:float = 1000
export var half_repeat:float = 1
export var color:Color = Color.white

func _draw():
  for i in range(-half_repeat, half_repeat):
    draw_line(Vector2(-half_repeat*size, i * size), Vector2(half_repeat*size, i * size), color)
    draw_line(Vector2(i * size, -half_repeat*size), Vector2(i * size, half_repeat*size), color)
