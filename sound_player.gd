extends Node

export(PackedScene) var player_pool_scene
export(Array, Resource) var sounds
export var base_attenuation:float = 2
export var base_player_count:int = 10
const time_merge = 0.1
const pitch_merge = 0.1
const position_merge_sqr = 100
var sound_dict = {}
var current_player_dict = {}

func _ready():
  for sound in sounds:
    var pool = player_pool_scene.instance()
    pool.size = int(ceil(base_player_count * sound.simultaneity))
    pool.name = sound.name
    add_child(pool)
    for player in pool.get_children():
      player.attenuation = sound.attenuation * base_attenuation
      player.bus = sound.bus
      player.stream = sound.sound
    sound_dict[sound.name] = [pool, sound]
    current_player_dict[sound.name] = []

func play_audio(name, position, pitch = null, volume_db = 0):
  var dict = sound_dict[name]
  pitch = dict[1].pitch if pitch == null else pitch
  volume_db += dict[1].volume_db
  for player in current_player_dict.get(name): # try merging the same sounds that are played at a similar time, pitch, and position
    if abs(log(player.pitch_scale/pitch)) < pitch_merge and (player.global_position - position).length_squared() < position_merge_sqr / (player.attenuation*player.attenuation):
      # merge the two sound
      player.volume_db = linear2db(db2linear(player.volume_db) + db2linear(volume_db))
      return
  var player = dict[0].get_object()
  if player == null:
    return
  player.global_position = position
  player.volume_db = volume_db
  player.pitch_scale = pitch
  player.play()
  current_player_dict[name].append(player)
  yield(get_tree().create_timer(time_merge), "timeout")
  current_player_dict[name].erase(player)
  if player.playing:
    yield(player, "finished")
  dict[0]._recycle(player)
