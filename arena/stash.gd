extends Node

signal content_changed(content)

export var capacity:float = 100
var content = {}
var content_size:float = 0

func accept_resource(type):
  return true

func take_resource(type, amount):
  amount = _take_resource(type, amount)
  content_changed()
  return amount

func _take_resource(type, amount):
  amount = min(capacity - content_size, amount)
  content[type] = content.get(type, 0) + amount
  content_size += amount
  return amount

func take_resource_dict(dict):
  var og_size = content_size
  for type in dict:
    dict[type] -= _take_resource(type, dict[type])
  if content_size > og_size:
    content_changed()
  return dict

func content_changed():
  emit_signal("content_changed", content)

func request_all_content(requester, stash, resource_types = null):
  if requester.side == get_parent().side and content_size > 0:
    var result
    if resource_types == null:
      resource_types = content.keys()
    if stash and stash.capacity < INF:
      var available = stash.capacity - stash.content_size
      if available <= 0: return
      var taken = 0
      result = {}
      for key in resource_types:
        if not stash.accept_resource(key):
          continue
        var amount = content[key]
        if amount < available:
          available -= amount
          taken += amount
          content[key] = 0
          result[key] = amount
        else:
          content[key] = amount - available
          result[key] = available
          taken += available
          break
      content_size -= taken
    else:
      result = content.duplicate()
      for key in resource_types:
        content_size -= content[key]
        content[key] = 0
    content_changed()
    stash.take_resource_dict(result)
    for value in result.values():
      assert(value == 0)

func request_exact(type, amount):
  if type in content and content[type] > amount:
    content[type] -= amount
    content_size -= amount
    content_changed()
    return amount
  return 0

func request_resource(type, amount, max_ratio = 1):
  if type in content:
    var taken = min(amount, content[type]*max_ratio)
    if taken > 0:
      content[type] -= taken
      content_size -= taken
      content_changed()
      return taken
  return 0

func clear():
  content = {}
  content_size = 0
  content_changed()
