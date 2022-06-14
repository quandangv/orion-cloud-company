extends Node

var resource_types = []
var resource_abundance = []
onready var parent = get_parent()

func spawn_resource():
  for i in range(len(resource_types)):
    Pools.resource.spawn_amount(resource_types[i], resource_abundance[i], parent)
