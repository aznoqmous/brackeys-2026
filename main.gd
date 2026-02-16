@tool
extends Node2D
class_name Main

const TILE = preload("uid://cjenahwjdoaof")
const WALL = preload("uid://b2abdh8bwie2d")

@onready var container: Node2D = $Container
@onready var player: Player = $ObjectsContainer/Player

@export var tile_size : Vector2 :
	set(value):
		tile_size = value
		build()
		
@export var room_size : Vector2i :
	set(value):
		room_size = value
		build()
		
@export var tile_offset : Vector2 :
	set(value):
		tile_offset = value
		build()
		
func _ready():
	build()

func build():
	if not container: return;
	for c in container.get_children():
		c.queue_free()
		
	for x in room_size.x:
		for y in room_size.y:
			var tile := TILE.instantiate() as Tile
			container.add_child(tile)
			tile.position = get_transformed_position(Vector2(x, y))
			tile.grid_position = Vector2i(x, y)
			tile.clicked.connect(func(): 
				player.position = tile.position + container.position
				#print(get_untransformed_position(tile.position))
			)
			if not x:
				var wall := WALL.instantiate() as Wall
				wall.position = get_transformed_position(Vector2(x, y))
				container.add_child(wall)
			if not y:
				var wall := WALL.instantiate() as Wall
				wall.position = get_transformed_position(Vector2(x, y))
				wall.scale.x = -1
				container.add_child(wall)


func get_transformed_position(pos: Vector2) -> Vector2:
	return Vector2(
		(tile_size.x * pos.x + room_size.y  * pos.x - pos.y * tile_size.x) / 2.0 + tile_offset.x,
		((pos.y - 1 - room_size.y) * tile_size.y + room_size.x * tile_size.y + pos.x * tile_size.y) / 2.0 + tile_offset.y
	)

func get_untransformed_position(world_pos: Vector2) -> Vector2:
	var Xp = 2.0 * (world_pos.x - tile_offset.x)
	var Yp = 2.0 * (world_pos.y - tile_offset.y)

	var S = Yp / tile_size.y - room_size.x + 1 + room_size.y

	var denominator = 2.0 * tile_size.x + room_size.y
	var x = (Xp + tile_size.x * S) / denominator
	var y = S - x

	return Vector2(floor(x), floor(y))

func world_to_grid_position(pos) -> Vector2:
	return get_transformed_position(get_untransformed_position(get_transformed_position(pos)))
	
