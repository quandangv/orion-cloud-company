extends Control

export var action_button_path:NodePath
onready var action_button = get_node(action_button_path)
export var join_path:NodePath
onready var join_button = get_node(join_path)
export var host_path:NodePath
onready var host_button = get_node(host_path)
export var color_path:NodePath
onready var color_picker = get_node(color_path)
export var close_button_path:NodePath
onready var close_button = get_node(close_button_path)
export var text_box_path:NodePath
onready var text_box = get_node(text_box_path)
var action = null
var address = null
var showing_color_picker:bool = false

func _ready():
  close_button.connect("toggled", self, "set_prompt_visible")
  action_button.connect("pressed", self, "action_button_pressed")
  color_picker.connect("color_changed", self, "change_color")
  host_button.connect("press_original", self, "prep_host_game")
  join_button.connect("press_original", self, "prep_join_game")
  host_button.connect("press_other", self, "close_connection")
  join_button.connect("press_other", self, "close_connection")
  Multiplayer.connect("client_connected", self, "join_success")
  Multiplayer.connect("client_connect_failed", self, "join_failure")
  Multiplayer.connect("deactivate", self, "clear_address")
  Multiplayer.connect("player_info_updated", self, "info_update")

func clear_address():
  address = null

func info_update(id, info):
  var name = info["name"]
  if id in Multiplayer.player_info:
    var old_name = Multiplayer.player_info[id]["name"]
    if old_name != name:
      show_textbox(false, old_name + " changed their name to " + name, "close", "Okay")
    else:
      show_textbox(false, old_name + " changed their color", "close", "Okay")
  else:
    show_textbox(false, info["name"] + " has joined!", "close", "Yay!")

func get_public_ipv6():
  for ip in IP.get_local_addresses():
    if ip.find(':') != -1 and (ip[0] == '2' or ip[0] == '3'):
      return ip
  printerr("Can't find a public IPv6 address")
  return IP.get_local_addresses()[0]

func not_already_initialized():
  var tree = get_tree()
  if tree.network_peer == null:
    return true
  elif tree.is_network_server():
    show_textbox(false, "already hosting", "close", "Okay")
  else:
    show_textbox(false, "already joined", "close", "Okay")
func prep_host_game():
  if not_already_initialized():
    show_textbox(true, "", "host_game", "Use Port", String(Multiplayer.default_port))
func host_game():
  if text_box.text == "":
    text_box.text = text_box.placeholder_text
  var error = Multiplayer.host_game(int(text_box.text))
  if not error:
    host_button.is_original = false
    join_button.disabled = true
    print(IP.get_local_addresses())
    address = get_public_ipv6() + ":" + String(Multiplayer.my_port)
    show_address()
  else:
    show_textbox(false, error, "prep_host_game", "Try different port")
func show_address():
  show_textbox(false, address, "copy", "Copy address")

func prep_join_game():
  if not_already_initialized():
    show_textbox(true, "", "join_game", "Join with address", OS.clipboard)
func join_game():
  if text_box.text == "":
    text_box.text = text_box.placeholder_text
  var error = Multiplayer.join_game(text_box.text)
  if not error:
    join_button.is_original = false
    host_button.disabled = true
    address = text_box.text
    show_textbox(false, "joining...", "close", "Okay")
  else:
    address = null
    show_textbox(false, error, "prep_join_game", "Try different address")

func join_success():
  show_textbox(false, "joined!", "close", "Yay!")

func join_failure():
  address = null
  show_textbox(false, "failed to join", "prep_join_game", "Try different address")

func prep_name_player():
  show_textbox(true, Storage.player["name"], "name_player", "Select Name")
  color_picker.color = Storage.player["color"]
  set_show_color_picker(true)
func name_player():
  Storage.set_player_display(text_box.text, color_picker.color)
  set_prompt_visible(false)
  set_show_color_picker(false)

func close_connection():
  host_button.is_original = true
  join_button.is_original = true
  host_button.disabled = false
  join_button.disabled = false
  close_button.visible = false
  set_prompt_visible(false)
  Multiplayer.close_connection()

func show_textbox(editable, text, action, action_text, placeholder = ""):
  text_box.editable = editable
  text_box.text = text
  self.action = action
  action_button.text = action_text
  set_prompt_visible(true)
  text_box.placeholder_text = placeholder
  close_button.visible = true
  set_show_color_picker(false)

func set_show_color_picker(value):
  color_picker.get_parent().visible = value
  showing_color_picker = value

func copy():
  OS.clipboard = text_box.text

func action_button_pressed():
  if action:
    call(action)

func close():
  if address != null:
    show_address()
  set_prompt_visible(false)

func set_prompt_visible(value):
  text_box.visible = value
  action_button.visible = value
  close_button.pressed = value
  if showing_color_picker:
    color_picker.get_parent().visible = value
