@tool
extends Node2D
class_name Main

const TILE = preload("uid://cjenahwjdoaof")
const WALL = preload("uid://b2abdh8bwie2d")

@onready var container: Node2D = $Container
@onready var furnitures_container: Node2D = $ObjectsContainer/FurnituresContainer
@onready var player: Player = $ObjectsContainer/Player

@export var game_mode: GameMode

enum GameMode {
	Puzzle,
	EditMode
}

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
		
var tiles : Dictionary[Vector2i, Tile]
var selected_tile : Tile

func _ready():
	build()
	
	for f in furnitures_container.get_children():
		f = f as Furniture
		f.apply_position()

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
			tiles[tile.grid_position] = tile
			tile.clicked.connect(func():
				if game_mode == GameMode.EditMode: edit_click_tile(tile)
				if game_mode == GameMode.Puzzle: puzzle_click_tile(tile)
			)
			tile.mouse_entered.connect(func():
				if game_mode == GameMode.Puzzle: puzzle_mouse_entered_tile(tile)
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

func get_untransformed_position(world_pos: Vector2) -> Vector2i:
	var Xp = 2.0 * (world_pos.x - tile_offset.x)
	var Yp = 2.0 * (world_pos.y - tile_offset.y)

	var S = Yp / tile_size.y - room_size.x + 1 + room_size.y

	var denominator = 2.0 * tile_size.x + room_size.y
	var x = (Xp + tile_size.x * S) / denominator
	var y = S - x

	return Vector2i(round(x), round(y))

func world_to_grid_position(pos) -> Vector2:
	return get_transformed_position(get_untransformed_position(pos - container.position)) + container.position

func edit_click_tile(tile: Tile):
	# Player doesnt move this wayyy
	# player.position = tile.position + container.position
	if selected_tile:
		if selected_tile.current_furniture:
			selected_tile.is_selected = false
			if selected_tile.current_furniture: selected_tile.current_furniture.update_state()
			selected_tile.current_furniture.position = tile.position
			selected_tile.current_furniture.apply_position()
		selected_tile = null
	else:
		selected_tile = tile
		tile.is_selected = true
		if selected_tile.current_furniture: selected_tile.current_furniture.update_state()

func _input(event):
	if game_mode == GameMode.Puzzle:
		if event is InputEventMouseButton:
			if event.is_pressed():
				pass
			else:
				if selected_tile:
					selected_tile.is_selected = false
					if selected_tile.current_furniture: selected_tile.current_furniture.update_state()
					selected_tile = null
				pass

func puzzle_click_tile(tile: Tile):
	print("click")
	if selected_tile:
		if selected_tile.current_furniture:
			
			selected_tile.is_selected = false
			if selected_tile.current_furniture: selected_tile.current_furniture.update_state()
		selected_tile = null
	else:
		if not tile.current_furniture: return;
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
				tile.current_furniture.flip()
				return;
		selected_tile = tile
		tile.is_selected = true
		if selected_tile.current_furniture: selected_tile.current_furniture.update_state()

func puzzle_mouse_entered_tile(tile: Tile):
	if not selected_tile or not selected_tile.current_furniture: return;
	if tile.is_occupied: return;
	selected_tile.current_furniture.position = tile.position
	selected_tile.current_furniture.apply_position()
	
	selected_tile = tile
	tile.is_selected = true
	if selected_tile.current_furniture: selected_tile.current_furniture.update_state()
	
