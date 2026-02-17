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

@export var left_door_position : Vector2i : 
	set(value):
		left_door_position = value
		build()	
@export var right_door_position : Vector2i :
	set(value):
		right_door_position = value
		build()
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
@export var window_count: int:
	set(value):
		window_count = value
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
	
	var walls: Array[Tile]
	for x in room_size.x:
		for y in room_size.y:
			var tile := TILE.instantiate() as Tile
			tile.position = get_transformed_position(Vector2(x, y))
			tile.grid_position = Vector2i(x, y)
			tiles[tile.grid_position] = tile
			container.add_child(tile)
			tile.clicked.connect(func():
				if game_mode == GameMode.EditMode: edit_click_tile(tile)
				if game_mode == GameMode.Puzzle: puzzle_click_tile(tile)
			)
			tile.mouse_entered.connect(func():
				if game_mode == GameMode.Puzzle: puzzle_mouse_entered_tile(tile)
			)
			tile.is_door = tile.grid_position == left_door_position or tile.grid_position == right_door_position
				
			if not x:
				tile.is_wall = true
				tile.wall_left.set_visible(true)
			if not y:
				tile.is_wall = true
				tile.wall_right.set_visible(true)
				tile.door_sprites.scale.x = -1
				tile.window_sprites.scale.x = -1
				
			if (not x or not y) and not tile.is_door:
				walls.push_back(tile)
			
	walls.shuffle()
	print(min(window_count, walls.size() - 1))
	for i in min(window_count, walls.size() - 1):
		walls[i].is_window = true


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
			selected_tile.current_furniture.update_state()
			
			var furniture : Furniture = selected_tile.current_furniture
			var direction = Vector2i.RIGHT if furniture.sprites_container.scale.x > 0 else Vector2i.DOWN
			#print(resource)
			var grid_pos = get_untransformed_position(furniture.position)
			for i in furniture.resource.size:
				var test_tile = tiles.get(grid_pos + direction * i) as Tile
				print(str(grid_pos + direction * i), " ", test_tile)
				if tile and test_tile == tile: continue
				if not test_tile or (test_tile.current_furniture):
					print("nooooo")
					return;
			selected_tile.current_furniture.target_position = tile.position
			selected_tile.current_furniture.apply_position()
			
		selected_tile = null
	else:
		selected_tile = tile
		tile.is_selected = true
		if selected_tile.current_furniture: selected_tile.current_furniture.update_state()

func _input(event):
	if game_mode == GameMode.Puzzle:
		if event.is_action_released("LeftClick"):
			puzzle_left_click_released()

func puzzle_click_tile(tile: Tile):
	if selected_tile:
		if selected_tile.current_furniture:
			selected_tile.is_selected = false
			if selected_tile.current_furniture: selected_tile.current_furniture.update_state()
		selected_tile = null
	else:
		if not tile.current_furniture: return;
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
				tile.current_furniture.flip()
				update_validity()
				validate_level()
				return;
		selected_tile = tile
		tile.is_selected = true
		if selected_tile.current_furniture: selected_tile.current_furniture.update_state()

func puzzle_mouse_entered_tile(tile: Tile):
	if not selected_tile or not selected_tile.current_furniture: return;
	
	if tile.is_occupied and (selected_tile.current_furniture != tile.current_furniture): return;
	if tile.grid_position == left_door_position: return;
	
	var furniture : Furniture = selected_tile.current_furniture
	var direction = Vector2i.RIGHT if furniture.sprites_container.scale.x > 0 else Vector2i.DOWN
	#print(resource)
	var grid_pos = get_untransformed_position(tile.position)
	for i in furniture.resource.size:
		var test_tile = tiles.get(grid_pos + direction * i) as Tile
		if tile and test_tile == tile: continue
		if not test_tile or (test_tile.current_furniture and test_tile.current_furniture != furniture):
			print("nooooo")
			return;
					
	selected_tile.current_furniture.target_position = tile.position
	selected_tile.current_furniture.apply_position()
	
	selected_tile = tile
	tile.is_selected = true
	if selected_tile.current_furniture: selected_tile.current_furniture.update_state()
	
	update_validity()


func puzzle_left_click_released():
	if not selected_tile or not selected_tile.current_furniture: return;
	
				
	selected_tile.is_selected = false
	selected_tile.current_furniture.update_state()
	selected_tile = null
	
	validate_level()
	
func update_validity():
	for f in get_furnitures():
		f.update_validity()
		f.update_state()
		
func validate_level():
	# check furnitures validity
	var is_valid = true
	for f in get_furnitures():
		if not f.update_validity():
			print("furnitures not valid")
			return false
	
	# check path
	var path = find_path(left_door_position, right_door_position)
	if not path:
		print("no valid path found")
		return false
	path.pop_front()
	for p in path:
		#player.position = get_transformed_position(p)
		player.animation_player.play("jump")
		await get_tree().create_timer(0.15).timeout
		get_tree().create_tween().tween_property(player, "position", get_transformed_position(p), 0.25)
		await get_tree().create_timer(0.30).timeout
	player.position = get_transformed_position(left_door_position)
	print("winnn")

func get_furnitures():
	return tiles.values().map(func(tile: Tile): return tile.current_furniture).filter(func(v): return v)

func get_neighbor_tiles(grid_pos) -> Array:
	return [
		tiles.get(grid_pos + Vector2i.LEFT),
		tiles.get(grid_pos + Vector2i.RIGHT),
		tiles.get(grid_pos + Vector2i.UP),
		tiles.get(grid_pos + Vector2i.DOWN)
	].filter(func(v): return v)
	
func get_neighbor_furnitures(grid_pos) -> Array:
	return get_neighbor_tiles(grid_pos).map(func(v: Tile): return v.current_furniture).filter(func(v): return v)

func heuristic(a: Vector2i, b: Vector2i) -> int:
	return abs(a.x - b.x) + abs(a.y - b.y)
	
func reconstruct_path(came_from: Dictionary, current: Vector2i) -> Array[Vector2i]:
	var total_path: Array[Vector2i] = [current]

	while came_from.has(current):
		current = came_from[current]
		total_path.push_front(current)

	return total_path
	
func get_neighbors(pos: Vector2i) -> Array:
	return get_neighbor_tiles(pos).map(func(t): return t.grid_position)

func is_walkable(grid_pos):
	var tile = tiles.get(grid_pos)
	return tile and not tile.current_furniture

func find_path(start: Vector2i, goal: Vector2i) -> Array[Vector2i]:
	var open_set: Array[Vector2i] = [start]
	var came_from: Dictionary = {}

	var g_score: Dictionary = {}
	g_score[start] = 0

	var f_score: Dictionary = {}
	f_score[start] = heuristic(start, goal)

	while open_set.size() > 0:
		# Get node with lowest f_score
		var current: Vector2i = open_set[0]
		for node in open_set:
			if f_score.get(node, INF) < f_score.get(current, INF):
				current = node

		if current == goal:
			return reconstruct_path(came_from, current)

		open_set.erase(current)

		for neighbor in get_neighbors(current):
			if not is_walkable(neighbor):
				continue

			var tentative_g = g_score.get(current, INF) + 1

			if tentative_g < g_score.get(neighbor, INF):
				came_from[neighbor] = current
				g_score[neighbor] = tentative_g
				f_score[neighbor] = tentative_g + heuristic(neighbor, goal)

				if not open_set.has(neighbor):
					open_set.append(neighbor)

	return [] # No path found
