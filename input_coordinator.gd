extends Node

const controller_priorities = {"camera":1, "ship":0}
var _explicit_controllers = []
var _implicit_controllers = []
var _implicit_controllers_priorities = []

func register_implicit_controller(type, controller, front = false):
  var priority = controller_priorities[type]
  var index = _implicit_controllers_priorities.bsearch(priority)
  var front_index = index
  while index < len(_implicit_controllers) and _implicit_controllers_priorities[index] == priority: # Check if the controller have already been added
    if _implicit_controllers[index] == controller:
      if front:
        break
      if index == 0:
        return true
      else:
        return false
    index += 1
  if front:
    index = front_index
  _implicit_controllers_priorities.insert(index, priority)
  _implicit_controllers.insert(index, controller)
  if not controller.is_connected("tree_exiting", self, "unregister_implicit_controller"):
    controller.connect("tree_exiting", self, "unregister_implicit_controller", [controller])
  if index == 0:
    if len(_implicit_controllers) >= 2:
      if not _implicit_controllers[1] or _implicit_controllers[1].lost_input():
        _implicit_controllers.remove(1)
        _implicit_controllers_priorities.remove(1)
    return true
  else:
    return false

func unregister_implicit_controller(controller):
  for i in range(len(_implicit_controllers) - 1, -1, -1):
    var item = _implicit_controllers[i]
    if item == null:
      _implicit_controllers.remove(i)
      _implicit_controllers_priorities.remove(i)
    elif item == controller:
      _implicit_controllers.remove(i)
      _implicit_controllers_priorities.remove(i)
      controller.disconnect("tree_exiting", self, "unregister_implicit_controller")
      if i == 0 and len(_implicit_controllers) > 0:
        _implicit_controllers.front().gained_input()
      break
