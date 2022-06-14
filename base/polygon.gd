extends CollisionObject2D

signal destroyed()

export var size:float = 0
export var damage:float = 1
onready var collision = $collision

func destroyed():
  collision.set_deferred("disabled", true)
  BulkAnim.fade_out_grow.add(self)

func bulk_anim_done(name):
  if 'fade_out' in name:
    emit_signal("destroyed")
