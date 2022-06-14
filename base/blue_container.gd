extends Node2D

signal filled

const reset_cost = 100
export var damage:float = 20
export var radius:float = 10
export var color:Color
export var progress_speed:float = 4
export var progress:float = 10
var filled:bool = false

func _ready():
  $col.shape.radius = radius
func _draw():
  var angle = inverse_e_minus_sin_e(progress / (radius * radius / 2)) # this calculates the angle of the circular segment that would have the area specified by the progress
  if angle >= PI*2 and not filled:
    angle = PI*2
    draw_circle(Vector2.ZERO, radius, Color.white)
    filled = true
    emit_signal("filled")
  else:
    var starting_angle = (PI*2 - angle) / 2 - PI/2
    var sector_count = ShapeLib.arc_point_count(radius, angle)
    if sector_count > 2:
      var step = angle / sector_count
      var points = []
      for i in range(sector_count+1):
        points.push_back(Vector2(radius, 0).rotated(i*step + starting_angle))
      draw_colored_polygon(points, color)
  draw_arc(Vector2.ZERO, radius, 0, PI*2, 20, Color.white, 1, true)

func inverse_e_minus_sin_e(m):
  """https://en.wikipedia.org/wiki/Kepler%27s_equation#Fixed-point_iteration"""
  var e = m
  for _i in range(8):
    e = m + sin(e)
  return e

func reset():
  progress = max(0, progress - reset_cost)
  update()

func area_interact(other):
  return true
func area_collide(other, delta):
  return damage

func offer_absorb(other):
  if not filled:
    progress += other.mass * progress_speed
    update()
  return true

func offer_capture(other):
  return Vector2.ZERO
func demand_release(other):
  return true
