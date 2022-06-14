extends Tween

const anim_speed = 2

func _ready():
  start()
var fade_out = []
var fade_in = []

func add_fade_out(obj:Node):
  if fade_in.has(obj):
    fade_in.erase(obj)
  if not fade_out.has(obj):
    fade_out.append(obj)
    obj.visible = true
  set_process(true)
func add_fade_in(obj:Node):
  if fade_out.has(obj):
    fade_out.erase(obj)
  if not fade_in.has(obj):
    fade_in.append(obj)
    if not obj.visible:
      obj.visible = true
      obj.modulate.a = 0
  set_process(true)

func _process(delta):
  var nothing = true
  for i in range(len(fade_out)-1, -1, -1):
    var obj = fade_out[i]
    obj.modulate.a -= delta * anim_speed
    if obj.modulate.a <= 0:
      obj.visible = false
      obj.modulate.a = 0
      fade_out.remove(i)
    else:
      nothing = false
  for i in range(len(fade_in)-1, -1, -1):
    var obj = fade_in[i]
    obj.modulate.a += delta * anim_speed
    if obj.modulate.a >= 1:
      fade_in.remove(i)
      obj.modulate.a = 1
    else:
      nothing = false
  if nothing:
    set_process(false)

