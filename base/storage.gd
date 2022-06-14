extends Node

signal player_info_changed

const player_path = "user://player.json"
const ranks = {"ensign": 1}
var player = {"rank": 0}

func _ready():
  var saved = File.new()
  if saved.file_exists(player_path):
    saved.open(player_path, File.READ)
    player = parse_json(saved.get_line())
  if not "rank" in player:
    player["rank"] = 0
  if not "name" in player:
    player["name"] = "Anonymous"
  if not "color" in player:
    var rand_color = Color(randf(), randf(), randf())
    if rand_color.v < 0.5:
      rand_color = rand_color.inverted()
    player["color"] = rand_color
  else:
    player["color"] = Color(player["color"])

func save():
  var saved = File.new()
  var data = player.duplicate(true)
  data["color"] = data["color"].to_html(false)
  saved.open(player_path, File.WRITE)
  saved.store_line(to_json(data))

func give_rank(name, save = true):
  player["rank"] = max(player["rank"], ranks[name])
  if save:
    self.save()
  emit_signal("player_info_changed", player)

func set_player_display(name, color, save = true):
  player["name"] = name
  player["color"] = color
  if save:
    self.save()
  emit_signal("player_info_changed", player)
