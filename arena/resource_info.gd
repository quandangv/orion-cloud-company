extends Resource
class_name ResourceInfo

export var name:String
export var color:Color
export var chunk_mass_range:Vector2 = Vector2(2, 30)

enum SHAPE { CIRCLE = 0, SQUARE = 4, TRIANGLE = 3 }
export(SHAPE) var shape = SHAPE.SQUARE

func rand_chunk_mass():
  return rand_range(chunk_mass_range.x, chunk_mass_range.y)
func avg_chunk_mass():
  return (chunk_mass_range.x + chunk_mass_range.y)/2
