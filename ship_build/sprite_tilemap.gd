extends Node2D

export var sprite_scale:float = 0.1

func set_cell(coord, texture, rotation = 0, prefix = ''):
  var name = prefix + str(int(coord.x)) + "," + str(int(coord.y))
  var sprite = get_node_or_null(name)
  if not sprite:
    if texture != null:
      sprite = Sprite.new()
      add_child(sprite)
      sprite.name = name
      sprite.position = ComponentUtils.map_to_local(coord)
      sprite.scale = Vector2(sprite_scale, sprite_scale)
      sprite.texture = texture
      sprite.rotation = rotation * PI / 3
      return [sprite, true]
    return [null, false]
  elif texture == null:
    sprite.texture = null
  else:
    sprite.texture = texture
    sprite.rotation = rotation * PI / 3
  return [sprite, false]

func clear():
  for child in get_children():
    child.texture = null
