extends Node

const super_coords = [Vector2(-1, 1), Vector2(0, 1)]
const super_flip_coords = [Vector2(0, -1), Vector2(1, -1)]
const mega_extra_coords = [Vector2(-1, 0), Vector2(1, 0)]
const mega_coords = [Vector2(1, 0), Vector2(0, 1), Vector2(-1, 1), Vector2(-1, 0), Vector2(0, -1), Vector2(1, -1)]

const generator_output = 6.0
const component_hp = {'armor':3}
const base_component_hp = 2

const component_price = {'generator': 2}

export var tile_radius: float
export var tilset_cell_size: float
export(Dictionary) var stat_color
export(Array, Resource) var components
var component_dict = {}
onready var tile_transform = Transform2D(Vector2(tile_radius * sin(PI/3) *2, 0),
  Vector2(tile_radius * sin(PI/3), tile_radius*1.5), Vector2.ZERO)
onready var tile_inverse_trans = tile_transform.affine_inverse()

func local_to_map(pos):
  pos = tile_inverse_trans * pos
  return pos.round()

func map_to_local(pos):
  return tile_transform * pos

func _ready():
  for comp in components:
    component_dict[comp.name] = comp

const normal_neighbors = mega_coords
const super_neighbors = [Vector2(0, -1), Vector2(1, -1), Vector2(-1, 0),
  Vector2(1, 0), Vector2(1, 1), Vector2(0, 2), Vector2(-1, 2), Vector2(-2, 2), Vector2(-2, 1)]
const super_flip_neighbors = [Vector2(0, 1), Vector2(-1, 1), Vector2(-1, 0),
  Vector2(1, 0), Vector2(-1, -1), Vector2(0, -2), Vector2(1, -2), Vector2(2, -2), Vector2(2, -1)]
const mega_neighbors = [Vector2(0, -2), Vector2(1, -2), Vector2(2, -2),
  Vector2(2, -1), Vector2(2, 0), Vector2(1, 1), Vector2(0, 2), Vector2(-1, 2), Vector2(-2, 2),
  Vector2(-2, 1), Vector2(-2, 0), Vector2(-1, 1)]

func add_dict(dict, key, amount = 1):
  if key in dict:
    dict[key] += amount
  else:
    dict[key] = amount

func get2D(array, hsize, vsize, pos):
  if pos.x < 0 or pos.x >= hsize or pos.y < 0 or pos.y >= vsize:
    return null
  return array[pos.x + pos.y*hsize]

func update_range(r, value):
  if value < r[0]:
    r[0] = value
  if value + 1 > r[1]:
    r[1] = value + 1

class PlasmaStat:
  var supply:float
  var max_supply:float
  var energy:float
  var speed:float
  static func create(max_supply, supply, energy = 0, speed = 0):
    var ins = PlasmaStat.new()
    ins.max_supply = max_supply
    ins.supply = supply
    ins.energy = energy
    ins.speed = speed
    return ins
  func add(other):
    supply += other.supply
    energy += other.energy
    speed += other.speed
  func supply_ratio():
    return supply / max_supply if max_supply > 0 else INF
  func checked_add_supply(amount:float):
    var raise = min(amount, max_supply - supply)
    supply += raise
    return raise
  func consume(other):
    if other.supply == 0: return
    var raise = min(other.supply, max_supply - supply)
    var ratio = raise / other.supply
    raise = create(max_supply, raise)
    raise.energy = other.energy*ratio
    raise.speed = other.speed*ratio
    ratio = 1-ratio
    other.energy *= ratio
    other.speed *= ratio
    other.supply -= raise.supply
    add(raise)
    return raise
  func checked_add(other):
    checked_add_supply(other.supply)
    energy += other.energy
    speed += other.speed
  func clear():
    self.supply = 0
    self.energy = 0
    self.speed = 0
  func duplicate():
    var copy = create(max_supply, supply)
    copy.energy = energy
    copy.speed = speed
    return copy
  func mul(scalar):
    supply *= scalar
    energy *= scalar
    speed *= scalar
    return self
  func mul_comp(other):
    supply *= other.supply
    energy *= other.energy
    speed *= other.speed
    return self
  func _to_string():
    return '(' + str(max_supply) + ',' + str(supply) + ',' + str(energy) + ',' + str(speed) + ')'

class PlasmaModifier:
  extends PlasmaStat
  pass

func analyze_components(tiles, size, coord_translate = 0, use_current_hp = false):
  var coord_translate_vector = Vector2(coord_translate, coord_translate)
  var stats = {'thrust':0, 'core':0, 'price':0}
  var generators = {}
  var boosters = {}
  var turrets = {}
  var shields = {}
  var connection_dict = {}
  var hrange = [size, 0]
  var vrange = [size, 0]
  var drange = [size*2, 0]
  var vsize = ceil(len(tiles) / size)
  for x in range(size):
    for y in range(vsize):
      var tile = tiles[x + y*size]
      if tile == null or (use_current_hp and tile['_hp'] <= 0): continue
      update_range(hrange, x)
      update_range(vrange, y)
      update_range(drange, x + y)
      tile.erase('covered')
      tile.erase('warning')
      tile.erase('nottop')
      tile.erase('generators_connected')
      var pos = Vector2(x, y)
      tile['hp'] = component_hp.get(tile[''], 1) * base_component_hp
      stats['price'] += component_price.get(tile[''], 1)
      match tile['']:
        'generator':
          generators[pos] = tile
          tile['plasma'] = PlasmaStat.create(0, 6)
        'energizer':
          tile.erase('wasted_plasma')
          tile['plasma'] = PlasmaStat.create(3, 0)
          tile['plasma_modifier'] = PlasmaStat.create(1, 0, 1, 0)
          boosters[pos] = tile
        'accelerator':
          tile.erase('wasted_plasma')
          tile['plasma'] = PlasmaStat.create(3, 0)
          tile['plasma_modifier'] = PlasmaStat.create(1, 0, 0, 1)
          boosters[pos] = tile
        'guiding_turret':
          tile['plasma'] = PlasmaStat.create(1, 0)
          turrets[pos] = tile
        'turret':
          tile['plasma'] = PlasmaStat.create(3, 0)
          turrets[pos] = tile
        'thruster':
          tile['plasma'] = PlasmaStat.create(3, 0)
        'shield':
          shields[pos] = tile
          tile['plasma'] = PlasmaStat.create(3, 0)
        'core':
          stats['core'] += 1
  stats['size'] = max(0, max(hrange[1] - hrange[0], max(vrange[1] - vrange[0], drange[1] - drange[0])))
  stats['hrange'] = hrange
  stats['vrange'] = vrange
  stats['drange'] = drange
  for pos in boosters:
    var tile = get2D(tiles, size, vsize, pos + mega_coords[boosters[pos].get('rotation', 0)])
    if tile and 'plasma' in tile:
      tile['nottop'] = true
  for pos in generators:
    var tile = generators[pos]
    var downstream = []
    for angle in range(len(mega_coords)):
      var pos2 = mega_coords[angle] + pos
      var downstream_tile = get2D(tiles, size, vsize, pos2)
      var is_receiver = downstream_tile and 'plasma' in downstream_tile and downstream_tile['plasma'].supply_ratio() < 1
      if is_receiver and not 'nottop' in downstream_tile:
        add_connection_dict(connection_dict, downstream_tile, pos2+coord_translate_vector, (angle+3)%6)
        if not 'generators_connected' in downstream_tile:
          downstream_tile['generators_connected'] = {}
        downstream_tile['generators_connected'][pos] = 0
        downstream.append(pos2)
    tile['plasma_downstream'] = downstream
  for pos in generators:
    var tile = generators[pos]
    var single_source = []
    var multi_source = []
    var tile_dict = {}
    for pos2 in tile['plasma_downstream']:
      var tile2 = get2D(tiles, size, vsize, pos2)
      if tile2['plasma'].supply_ratio() < 1:
        tile_dict[pos2] = tile2
        if len(tile2['generators_connected']) <= 1:
          single_source.append(pos2)
        else:
          multi_source.append(pos2)
    var spare = 1 if multi_source else 0
    var amount = distribute_resource(pos, single_source, generator_output - spare,   tiles, size, vsize, connection_dict, coord_translate_vector)
    amount = distribute_resource(pos, multi_source, amount + spare,   tiles, size, vsize, connection_dict, coord_translate_vector)
    tile['wasted_plasma'] = PlasmaStat.create(generator_output, amount)
  for pos in shields:
    var rotation:int = shields[pos].get('rotation', 0)
    var covering = [mega_coords[rotation], mega_coords[(rotation+1)%6], mega_coords[(rotation+5)%6]]
    for _i in range(2):
      for i in range(len(covering)):
        var pos2 = pos + covering[i]
        var tile = get2D(tiles, size, vsize, pos2)
        if tile != null:
          if not 'covered' in tile:
            tile['covered'] = []
          tile['covered'].append([pos.x, pos.y])
        covering[i] += mega_coords[rotation]
  var warnings = []
  var covered = []
  for x in range(size):
    for y in range(vsize):
      var tile = tiles[x + y*size]
      if not tile:
        continue
      var coord = Vector2(x + coord_translate, y + coord_translate)
      if 'thruster' in tile['']:
        stats['thrust'] += tile['plasma'].supply
      if 'plasma' in tile:
        if tile['plasma'].supply == 0 and tile['plasma'].max_supply > 0:
          tile['warning'] = 'need_plasma_supply'
      if 'warning' in tile:
        warnings.append(coord)
      if 'covered' in tile or 'shield' in tile['']:
        covered.append(coord)
  var misc = {'warnings':warnings, 'covered':covered, 'connections':connection_dict}
  return [stats, misc]

func distribute_resource(source_pos, receivers, amount:float,   tiles, size, vsize, connection_dict, coord_translate_vector):
  var count = len(receivers)
  while count > 0:
    var divided_output = amount / count
    for i in range(len(receivers)-1, -1, -1):
      var current_pos = receivers[i]
      var tile = get2D(tiles, size, vsize, current_pos)
      var taken = tile['plasma'].checked_add_supply(divided_output)
      if taken > 0 and 'plasma_modifier' in tile:
        var modified = tile['plasma_modifier'].duplicate().mul(taken)
        tile['plasma'].checked_add(modified)
        modified.supply = taken
        var existing = 0
        if not 'wasted_plasma' in tile:
          tile['wasted_plasma'] = PlasmaStat.create(tile['plasma'].max_supply, 0)
        else:
          existing = tile['wasted_plasma'].supply
        tile['wasted_plasma'].add(modified)
        var tracker = [current_pos]
        var current = tile
        while true:
          var angle = current.get('rotation', 0)
          current_pos += mega_coords[angle]
          if current_pos in tracker:
            break
          var cont = false
          var next = get2D(tiles, size, vsize, current_pos)
          if not next:
            current['warning'] = 'need_plasma_output'
          elif 'plasma_modifier' in next:
            tracker.append(current_pos)
            if not 'wasted_plasma' in next:
              next['wasted_plasma'] = next['plasma'].duplicate()
            var raise = next['plasma'].consume(current['wasted_plasma'])
            modified = next['plasma_modifier'].duplicate().mul(raise.supply)
            next['plasma'].checked_add(modified)
            next['wasted_plasma'].add(raise)
            next['wasted_plasma'].add(modified)
            add_connection_dict(connection_dict, next, current_pos+coord_translate_vector, int(angle+3)%6)
            current['plasma_downstream'] = [current_pos]
            cont = true
          elif 'plasma' in next and not 'generator' in next['']:
            next['plasma'].consume(current['wasted_plasma'])
            add_connection_dict(connection_dict, next, current_pos+coord_translate_vector, int(angle+3)%6)
            current['plasma_downstream'] = [current_pos]
          else:
            current['warning'] = 'need_plasma_output'
          var returned = current['wasted_plasma'].supply - existing
          taken -= returned
          current['wasted_plasma'].supply -= returned
          assert(taken >= 0)
          if not cont:
            break
          current = next
        tile['generators_connected'][source_pos] = taken
      if taken < divided_output:
        count -= 1
        receivers.remove(i)
      amount -= taken
      if amount <= 0:
        return 0
  return amount

func shift_coordinate(coord_arr, x, y):
  for i in range(len(coord_arr)):
    coord_arr[i] = [coord_arr[i][0] - x, coord_arr[i][1] - y]

func finalize_ship(tiles, size):
  var stats = analyze_components(tiles, size)[0]
  var hhits = []
  var vhits = []
  var dhits = []
  var map = []
  var turrets = []
  var turret_rotation_count = {0:0, 1:0, 2:0, 3:0, 4:0, 5:0}
  var real_size = stats['size']
  var mapsize = 0
  if real_size != 0:
    for _i in range(real_size):
      hhits.append([])
      vhits.append([])
      dhits.append([])
    var hrange = stats['hrange']
    var vrange = stats['vrange']
    var drange = stats['drange']
    mapsize = hrange[1] - hrange[0]
    map.resize(mapsize*(vrange[1] - vrange[0]))
    for y in range(vrange[0], vrange[1]):
      for x in range(hrange[0], hrange[1]):
        var tile = tiles[x + y*size]
        if tile != null:
          var mapx = x-hrange[0]
          var mapy = y-vrange[0]
          if 'turret' in tile['']:
            tile['rotation'] = int(tile['rotation'])
            tile['position'] = turret_rotation_count[tile['rotation']] # give turrets with same rotation different positions so that they don't overlap when displayed
            turret_rotation_count[tile['rotation']] += 1
            turrets.append([mapx, mapy])
          if 'covered' in tile:
            shift_coordinate(tile['covered'], hrange[0], vrange[0])
          if 'plasma_downstream' in tile:
            shift_coordinate(tile['plasma_downstream'], hrange[0], vrange[0])
          if 'connected_generators' in tile:
            var dict = tile['connected_generators']
            var keys = dict.keys()
            var new_keys = Array(keys)
            shift_coordinate(new_keys, hrange[0], vrange[0])
            for i in range(len(keys)):
              if new_keys[i][0] != keys[i][0] or new_keys[i][1] != keys[i][1]:
                dict[new_keys[i]] = dict[keys[i]]
                dict.erase(keys[i])
          map[mapx + mapy*mapsize] = tile
          vhits[mapx].append(tile)
          hhits[mapy].append(tile)
          dhits[x+y-drange[0]].append([mapx, mapy, tile])
    for line in dhits:
      line.sort_custom(self, 'by_x')
  for line in dhits:
    for i in range(len(line)):
      line[i] = line[i][2]
  stats.erase('hrange')
  stats.erase('vrange')
  stats.erase('drange')
  stats.erase('warnings')
  return {'map':map, 'hhits':hhits, 'vhits':vhits, 'dhits':dhits, 'stats':stats, 'turrets':turrets, 'mapsize': mapsize, 'turret_rotations': turret_rotation_count}

func reanalyze_ship(data):
  var tiles = data['map']
  var size = data['mapsize']
  return finalize_ship(tiles, size)

func by_x(a, b):
  return a[0] < b[0]

func add_connection_dict(dict, tile, key, item):
  if key in dict:
    dict[key][1].append(item)
  else:
    dict[key] = [tile, [item]]
