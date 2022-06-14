extends Area2D

signal start_firing
signal on_lost_input
signal on_gained_input

var movement:Vector2
var firing:bool
var angle:float
var stop_multiplier = base_stop_multiplier
const thrust_to_rotate_speed = 2
var target_obj = null

const base_stop_multiplier = 1
var speed_limit:float = 40
var disabled:bool
var have_input:bool = false
const off_color = Color(0.5, 0.5, 0.5)
const mid_color = Color(0.8, 0.8, 0.8)
onready var camera = get_node("/root/game/camera")
onready var bg_modulate = get_node("/root/game/background/modulate")
onready var parent = get_parent()
onready var mouse_cast = $mouse
var direct_control = true
var mouse_targets = []
export var auto_take_input:bool = true
export(Array, NodePath) var targets

func _ready():
  if not Multiplayer.active or is_network_master():
    connect("mouse_entered", self, "_mouse_entered")
    connect("mouse_exited", self, "update_color")
  else:
    input_pickable = false
  mouse_cast.connect("body_entered", self, "body_entered_mouse")
  mouse_cast.connect("body_exited", self, "body_exited_mouse")
  $mouse_target_update.connect("timeout", self, "mouse_target_update")
  for i in range(len(targets)):
    targets[i] = get_node(targets[i])
  set_process(false)
  set_process_unhandled_input(false)

func body_entered_mouse(body):
  if GameUtils.is_shootable(parent.side, body):
    mouse_targets.append(body)
func body_exited_mouse(body):
  if body in mouse_targets:
    mouse_targets.erase(body)

func mouse_target_update():
  if mouse_targets:
    var dist = INF
    for body in mouse_targets:
      var new_dist = (mouse_cast.global_position - body.global_position).length_squared()
      if new_dist < dist:
        target_obj = body
        dist = new_dist

func wake_up():
  disabled = false
  if not Multiplayer.active or is_network_master():
    $shape.shape.radius = parent.size
    if auto_take_input and InputCoordinator.register_implicit_controller("ship", self, true):
      gained_input()
    else:
      have_input = true
      lost_input()
  else:
    have_input = true
    lost_input()

func hibernate():
  disabled = true
  InputCoordinator.unregister_implicit_controller(self)
  lost_input()

func _unhandled_input(event):
  if event.is_action('left') or event.is_action('right') or event.is_action('up') or event.is_action('down'):
    movement = Input.get_vector('left', 'right', 'up', 'down')
  if event.is_action('fire'):
    firing = event.is_pressed()
    if Input.is_action_just_pressed("fire"):
      set_start_firing()

func _physics_process(delta):
  var mouse_pos = GameUtils.global_mouse_pos
  mouse_cast.global_position = mouse_pos
  mouse_cast.scale = camera.zoom
  angle = (mouse_pos - parent.global_position).angle()

puppetsync func set_movement(value):
  movement = value
puppetsync func set_firing(value):
  firing = value
puppetsync func set_start_firing():
  emit_signal("start_firing")
puppetsync func set_angle(value):
  angle = value

func lost_input():
  if have_input:
    have_input = false
    set_process(false)
    set_process_unhandled_input(false)
    if parent.is_connected("bumped", self, "_bumped"):
      parent.disconnect("bumped", self, "_bumped")
      parent.components.disconnect("explode", self, "_explode")
      for target in targets:
        target.components.disconnect("explode", self, "_target_explode")
    camera.tracked_obj.erase(parent)
    movement = Vector2.ZERO
    firing = false
    emit_signal("on_lost_input")
  update_color()
  return true

func gained_input():
  if not have_input:
    have_input = true
    set_process(true)
    set_process_unhandled_input(true)
    if not parent.is_connected("bumped", self, "_bumped"):
      parent.connect("bumped", self, "_bumped")
      parent.components.connect("explode", self, "_explode")
      for target in targets:
        target.components.connect("explode", self, "_target_explode")
    camera.tracked_obj.append(parent)
    emit_signal("on_gained_input")
  update_color()

func _bumped(amount):
  camera.shake += amount

func _explode(comp):
  bg_modulate.color.g *= 0.5
  bg_modulate.color.b *= 0.5
  camera.shake += Vector2(30, 0)

func _target_explode(comp):
  bg_modulate.color *= 1.3

func _input_event(viewport, event, shape_idx):
  if event is InputEventMouseButton:
    if event.button_index == BUTTON_LEFT and event.pressed:
      if have_input:
        if event.doubleclick:
          InputCoordinator.unregister_implicit_controller(self)
          lost_input()
      elif not disabled and InputCoordinator.register_implicit_controller("ship", self, event.doubleclick):
        gained_input()

func _mouse_entered():
  if not disabled:
    parent.color_modifier = mid_color
func update_color():
  parent.color_modifier = Color.white if have_input or not input_pickable else off_color

func _exit_tree():
  camera.tracked_obj.erase(parent)
