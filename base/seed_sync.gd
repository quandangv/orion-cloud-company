extends Timer

var generator = RandomNumberGenerator.new()

func _ready():
  connect("timeout", self, "timeout")
  stop()

func timeout():
  rpc_unreliable("sync_seed", generator.randi())

remotesync func sync_seed(value):
  seed(value)
