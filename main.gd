@tool
extends Node2D
class_name Main

const TILE = preload("uid://cjenahwjdoaof")
const WALL = preload("uid://b2abdh8bwie2d")
const COIN = preload("uid://cieo3qdp5nvp2")
const FURNITURE = preload("uid://bt5jkavy5b063")

@export var game_mode: GameMode

enum GameMode {
	StoryMode,
	PuzzleMode,
	EditMode,
	Cinematic,
	TitleScreen
}

@onready var camera_2d: Camera2D = $World/Camera2D
@onready var world: Node2D = $World
@onready var container: Node2D = $World/Container
@onready var furnitures_container: Node2D = $World/ObjectsContainer/FurnituresContainer
@onready var player: Player = $World/ObjectsContainer/Player
@onready var player_canvas: Node2D = $World/PlayerCanvas
@export var name_control: Control
@export var room_name_label: Label

@export var story_levels: Array[StoryLevelResource]
var current_story_index := 0

@export_category("Audio")
@export var place_audio : AudioStreamPlayer2D
@export var move_audio : AudioStreamPlayer2D
@export var remove_audio : AudioStreamPlayer2D
@export var rotate_audio : AudioStreamPlayer2D
@export var player_move_audio : AudioStreamPlayer2D

@export var left_door_position : Vector2i :
	get: return current_level.left_door_position
@export var right_door_position : Vector2i :
	get: return current_level.right_door_position
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
var furnitures: Array[Furniture]
var furniture_counts : Dictionary[FurnitureResource, int]
var selected_tile : Tile
var player_room_data;
var hovered_furniture_resource: FurnitureResource

@export_category("Colors")
@export var walls_color : Color
@export var floor_color : Color

@export_category("Inventory")
@export var inventory: Inventory
@export var inventory_items : Array[ItemResource]
@export var edit_control: Control

@export_category("Level")
@export var progress_button: Button
@export var levels: Array[LevelResource]
@export var current_level_index := 0 :
	set(value):
		current_level_index = value
		build()
@export var current_level: LevelResource :
	set(value):
		current_level = value
		build()
	#get: return levels[min(current_level_index, levels.size())]
var next_level:
	get: 
		if current_level_index + 1 >= levels.size(): return null
		return levels[current_level_index + 1]
var total_score := 0
	
@export_category("Room")
@export var level_label: Label
@export var progress_label: Label
@export var level_slider: LevelSlider
@export var level_required_score := 10

@export_category("UI")
@export var validity_check_control: Control
@export var furniture_check: Label
@export var path_check: Label
@export var furniture_check_container: HBoxContainer
@export var path_check_container: HBoxContainer
@export var play_button: Button
@export var play_online_button: Button
@export var back_to_menu_button: Button


var last_furniture_check := false
var last_path_check := false
var is_valid := false

@export  var title_layer: CanvasLayer

@export_category("Furnitures")
@export var reward_control: RewardControl

@export_category("Story")
@export var story_level: int
@export_tool_button("Save Story resources") var save_to_story_resource = save_story_room
@export_tool_button("Load Story resources") var load_to_story_resource = load_story_room_at
@export_tool_button("UpdateValidity") var btn_update_validity = update_validity

func _ready():
	load_data()
	
	progress_button.pressed.connect(func():
		if game_mode == GameMode.EditMode:
			switch_to_puzzle_mode()
	)
	
	play_button.pressed.connect(func():
		game_mode = GameMode.StoryMode
		load_story_room(story_levels[current_story_index])
	)
	play_online_button.pressed.connect(func():
		switch_to_edit_mode()
	)
	
	back_to_menu_button.pressed.connect(func():
		if game_mode == GameMode.EditMode:
			if preview_furniture:
				preview_furniture.queue_free()
				inventory.add_furniture(preview_furniture.resource)
				preview_furniture = null
			player_room_data = save_room()
			save_data()
		game_mode = GameMode.TitleScreen
		title_screen_anim()
	)
	
	for f in furnitures_container.get_children():
		f = f as Furniture
		furnitures.push_back(f)
	
	match game_mode:
		#GameMode.StoryMode: load_story_room(story_levels[current_story_index])
		GameMode.StoryMode: 
			build()
		GameMode.EditMode: build()
		GameMode.PuzzleMode: build()
		GameMode.TitleScreen:
			title_screen_anim()
	
	if not Engine.is_editor_hint():
		inventory.items = inventory_items
		inventory.build_inventory()
		update_progress()
		update_validity()
		update_counts()

func _input(event):
	
	if game_mode == GameMode.PuzzleMode:
		if event.is_action_released("LeftClick"):
			puzzle_left_click_released()
			validate_level()
			if is_valid:
				game_mode = GameMode.Cinematic
				await player_animation()
				reward_control.show_reward(Data.furniture_resources.values().pick_random())
					
	if game_mode == GameMode.StoryMode:
		if event.is_action_released("LeftClick"):
			puzzle_left_click_released()
			validate_level()
			if is_valid:
				game_mode = GameMode.Cinematic
				await player_animation()
				current_story_index += 1
				save_data()
				load_story_room(story_levels[current_story_index])
				game_mode = GameMode.StoryMode
				
	if game_mode == GameMode.EditMode:
		if event.is_action_released("LeftClick"):
			if preview_furniture and preview_furniture.tile:
				edit_click_tile(preview_furniture.tile)
			else: puzzle_left_click_released()
			
			if preview_furniture: return
			if not next_level:return
			if total_score >= next_level.required_score and is_valid:
				if total_score >= next_level.required_score:
					current_level_index += 1
					room_size = current_level.room_size
					animate_build(true, false)
				update_progress()
			

	#if event.is_action_pressed("ui_down"):
		##create_random_room()
		#shuffle_room()
		#update_validity()
		#start_puzzle()

var title_screen_time := 0
func title_screen_anim():
	var ttt = Time.get_ticks_msec()
	title_screen_time = ttt
	if game_mode != GameMode.TitleScreen: return
	if Data.furniture_resources.size():
		player.randomize()
		current_level = story_levels.pick_random().level
		create_random_room()
		shuffle_room()
		#load_story_room(story_levels.pick_random())
		await animate_build(true)
	await get_tree().create_timer(0.5).timeout
	if ttt != title_screen_time: return
	title_screen_anim()
	
func _process(delta):
	if preview_furniture and not preview_furniture.tile:
		preview_furniture.target_position = get_mouse_position()
	title_layer.set_visible(game_mode == GameMode.TitleScreen)
	edit_control.set_visible(game_mode == GameMode.EditMode)
	furniture_check_container.scale = lerp(furniture_check_container.scale, Vector2.ONE, delta * 5.0)
	path_check_container.scale = lerp(path_check_container.scale, Vector2.ONE, delta * 5.0)
	validity_check_control.set_visible(game_mode != GameMode.TitleScreen)
	player.set_visible(game_mode != GameMode.TitleScreen)
	name_control.set_visible(game_mode != GameMode.TitleScreen)
	back_to_menu_button.set_visible(game_mode != GameMode.TitleScreen)
func build():
	if not container: return;
	for c in container.get_children():
		c.queue_free()
	
	tiles.clear()
	
	var walls: Array[Tile]
	for x in current_level.room_size.x:
		for y in current_level.room_size.y:
			var tile := TILE.instantiate() as Tile
			tile.position = get_transformed_position(Vector2(x, y))
			tile.grid_position = Vector2i(x, y)
			tiles[tile.grid_position] = tile
			container.add_child(tile)
			tile.clicked.connect(func():
				if game_mode == GameMode.StoryMode: puzzle_click_tile(tile)
				if game_mode == GameMode.PuzzleMode: puzzle_click_tile(tile)
				if game_mode == GameMode.EditMode: edit_click_tile(tile)
			)
			tile.mouse_entered.connect(func():
				if game_mode == GameMode.StoryMode: puzzle_mouse_entered_tile(tile)
				if game_mode == GameMode.PuzzleMode: puzzle_mouse_entered_tile(tile)
				if game_mode == GameMode.EditMode: edit_mouse_entered(tile)
			)
			tile.is_door = tile.grid_position == left_door_position or tile.grid_position == right_door_position
				
			if not y:
				tile.is_wall = true
				tile.wall_right.set_visible(true)
				tile.door_sprites.scale.x = -1
				tile.window_sprites.scale.x = -1
			if not x:
				tile.is_wall = true
				tile.wall_left.set_visible(true)
				tile.window_sprites.scale.x = 1
				
			if tile.grid_position.x == current_level.room_size.x - 1 or tile.grid_position.y == current_level.room_size.y - 1:
				tile.is_wall = true
			
			if (not x or not y) and not tile.is_door:
				walls.push_back(tile)
				
	for w in current_level.window_positions:
		var tile = tiles.get(w)
		if not tile: continue
		tile.is_window = true
		if tile.grid_position.x:
			for i in current_level.room_size.x + 1:
				var t = tiles.get(w + Vector2i(0, i))
				if not t: continue
				t.is_lit = true
		else:
			for i in current_level.room_size.y + 1:
				var t = tiles.get(w + Vector2i(i, 0))
				if not t: continue
				t.is_lit = true
	
	player_canvas.position = get_transformed_position(left_door_position)
	player.position = get_transformed_position(left_door_position)
	camera_2d.position.y = tile_size.y / 2.0 * (room_size.x - room_size.y) - (4.0 - max(room_size.x, room_size.y)) * tile_size.y / 2.0
	
	for f in furnitures:
		if f.saved_grid_position:
			f.apply_grid_position(f.saved_grid_position)
			if Engine.is_editor_hint(): f.position = f.target_position
		else:
			f.apply_position()
			
	update_counts()

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
	if preview_furniture:
		if not is_available_position(tile, preview_furniture): return;
		preview_furniture.is_preview = false
		preview_furniture.apply_position()
		preview_furniture = null
		update_validity()
		update_counts()
	else:
		puzzle_click_tile(tile)

func edit_mouse_entered(tile):
	if preview_furniture:
		if not is_available_position(tile, preview_furniture): return;
		preview_furniture.target_position = tile.position
		preview_furniture.apply_position()
		update_validity()
	else:
		puzzle_mouse_entered_tile(tile)

func is_available_position(tile, furniture:Furniture):
	var ptiles = furniture.get_tiles(tile, furniture.flipped)
	if ptiles.size() != furniture.resource.size: return false
	for t in ptiles:
		if t.current_furniture and t.current_furniture != furniture: return false
	return true

var left_clicked_time := 0.0
var double_click_time := 0.3
func rotate_furniture(tile):
	if not tile.current_furniture: return;
	tile.current_furniture.flip()
	rotate_audio.play()
	update_validity()
	
func remove_furniture(tile):
	inventory.add_furniture(tile.current_furniture.resource)
	furnitures.erase(tile.current_furniture)
	tile.current_furniture.remove()
	remove_audio.play()
	update_validity()
	update_progress()
	update_counts()
	
	if preview_furniture: return
	if not next_level:return
	if total_score >= next_level.required_score and is_valid:
		if total_score >= next_level.required_score:
			current_level_index += 1
			build()
			animate_build()
		update_progress()
	pass
func puzzle_click_tile(tile: Tile):
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		rotate_furniture(tile)
		return;
	if selected_tile:
		if selected_tile.current_furniture:
			selected_tile.is_selected = false
			if selected_tile.current_furniture: selected_tile.current_furniture.update_state()
		selected_tile = null
	else:
		if not tile.current_furniture: return;
		
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			if game_mode == GameMode.EditMode:
				if Time.get_ticks_msec() / 1000.0 - left_clicked_time < double_click_time:
					remove_furniture(tile)
					left_clicked_time = 0
					return
				left_clicked_time = Time.get_ticks_msec() / 1000.0
			


		selected_tile = tile
		tile.is_selected = true
		if selected_tile.current_furniture: selected_tile.current_furniture.update_state()

func puzzle_mouse_entered_tile(tile: Tile):
	if not selected_tile or not selected_tile.current_furniture: return;
	
	if tile.is_occupied and (selected_tile.current_furniture != tile.current_furniture): return;
	if tile.grid_position == left_door_position: return;
	
	if not is_available_position(tile, selected_tile.current_furniture): return;
					
	selected_tile.current_furniture.target_position = tile.position
	selected_tile.current_furniture.apply_position()
	move_audio.play()
	
	selected_tile = tile
	tile.is_selected = true
	if selected_tile.current_furniture: selected_tile.current_furniture.update_state()
	
	update_validity()


func puzzle_left_click_released():
	if not selected_tile or not selected_tile.current_furniture: return;
	
	selected_tile.is_selected = false
	selected_tile.current_furniture.update_state()
	selected_tile = null

func update_validity():
	for f in furnitures:
		f.update_validity()
		f.update_state()
	validate_level()

func create_random_room():
	for f in furnitures: f.queue_free()
	furnitures.clear()
		
	for i in 20:
		var fr = Data.furniture_resources.values().pick_random()
		var f = FURNITURE.instantiate() as Furniture
		furnitures_container.add_child(f)
		f.resource = fr
		furnitures.push_back(f)

func shuffle_room():
	furnitures.shuffle()
	for f in furnitures:
		f.set_visible(false)
		f.tile = null
		f.tiles.clear()
		
	for t in tiles.values():
		t.current_furniture = null
		
	for f in furnitures:
		var i = 0
		while i < 100:
			var flipped = randf() < 0.5
			i += 1
			var x = floor(randf_range(0, room_size.x - (f.resource.size if not flipped else 0)))
			var y = floor(randf_range(0, room_size.y - (f.resource.size if flipped else 0)))
			var tt = tiles.get(Vector2i(x, y))
			if not tt: continue
			if tt.grid_position == left_door_position or tt.grid_position == right_door_position: continue
			var ts = f.get_tiles(tt, f.flipped if not flipped else not f.flipped)
			if ts.size() < f.resource.size: continue;
			var skip = false
			for t in ts:
				if t.is_occupied: skip = true
				if t.grid_position == left_door_position or t.grid_position == right_door_position: skip = true
			if skip: continue
			else:
				f.target_position = tt.position
				f.tile = tt
				if flipped: f.flip()
				f.apply_position()
				if f.resource.requirements.size():
					f.update_validity()
					if f.is_valid: continue
				f.set_visible(true)
				break
				
	furnitures = furnitures.filter(func(c): return c.tile)
		
func validate_level():
	var valid = true
	# check furnitures validity
	furniture_check.text = "✔"
	for f in furnitures:
		if not f.update_validity():
			furniture_check.text = "❌"
			valid = false
			break
	
	if valid and not last_furniture_check:
		furniture_check_container.scale = Vector2.ONE * 1.2
	last_furniture_check = valid
	
	# check path
	path_check.text = "✔"
	var path = find_path(left_door_position, right_door_position)
	if not path:
		path_check.text = "❌"
		valid = false
		last_path_check = false
	else:
		if not last_path_check: path_check_container.scale = Vector2.ONE * 1.2
		last_path_check = true
	is_valid = valid
	if game_mode == GameMode.EditMode: update_progress()
	return valid
	
func player_animation():
	var path = find_path(left_door_position, right_door_position)
	game_mode = GameMode.Cinematic
	path.pop_front()
	for p in path:
		#player.position = get_transformed_position(p)
		player.animation_player.play("jump")
		await get_tree().create_timer(0.15).timeout
		get_tree().create_tween().tween_property(player, "position", get_transformed_position(p), 0.25)
		await get_tree().create_timer(0.30).timeout
		player_move_audio.play()
	

func get_furnitures():
	var fs : Array[Furniture]
	for f in furnitures_container.get_children():
		if not f: continue
		f = f as Furniture
		fs.push_back(f)
	return fs
	#return tiles.values().map(func(tile: Tile): return tile.current_furniture).filter(func(v): return v)

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

func update_counts():
	if game_mode != GameMode.EditMode: return
	furniture_counts.clear()
	
	for f in furnitures:
		if not furniture_counts.has(f.resource): furniture_counts[f.resource] = 0
		furniture_counts[f.resource] += 1
	for f in furnitures:
		f.update_count(furniture_counts[f.resource])
	
	for iis in inventory.slots:
		iis.update_state()

var preview_furniture : Furniture
func set_preview_item(ir: ItemResource):
	var furniture := FURNITURE.instantiate() as Furniture
	furnitures_container.add_child(furniture)
	furniture.resource = ir.furniture
	preview_furniture = furniture
	preview_furniture.is_preview = true
	furnitures.push_back(preview_furniture)
	preview_furniture.update_state()
	preview_furniture.position = get_mouse_position()
	update_progress()

func update_progress():
	level_label.text = str("Level ", current_level_index + 1)
	if not next_level:return
	total_score = 0
	for f in furnitures:
		total_score += f.resource.score
	progress_label.text = str(total_score, "/", next_level.required_score)
	level_slider.value = float(total_score) / float(next_level.required_score)
	progress_button.set_visible(is_valid)


func get_mouse_position():
	return (get_viewport().get_mouse_position() - container.global_position) / get_viewport().get_camera_2d().zoom / world.scale

func save_story_room():
	furnitures = get_furnitures()
	var fs : Array
	for f in furnitures:
		f.target_position = f.position
		f.apply_position()
		
		fs.push_back({
			"grid_position": {"x": f.tile.grid_position.x, "y": f.tile.grid_position.y},
			"name": f.resource.name,
			"flipped": f.flipped
		})
		
	var data = {
		"furnitures": fs
	}
	var story = StoryLevelResource.new()
	story.level = current_level
	story.data = JSON.stringify(data)
	print(str("Saving story ", story_level))
	print(data)
	ResourceSaver.save(story, str("res://resources/story/story-", story_level, ".tres"))

func load_story_room_at():
	var res := load(str("res://resources/story/story-", story_level, ".tres")) as StoryLevelResource
	load_story_room(res)
	
func load_story_room(res: StoryLevelResource):
	room_name_label.text = str("Room ", current_story_index + 1)
	load_room(res.data, res.level)

func save_room():
	var fs : Array
	for f in furnitures:
		fs.push_back({
			"grid_position": {"x": f.tile.grid_position.x, "y": f.tile.grid_position.y},
			"name": f.resource.name,
			"flipped": f.flipped
		})
		
	var data = {
		"name": "aznoqmous",
		"level": current_level_index,
		"furnitures": fs
	}
	
	return JSON.stringify(data)
	
func load_room(str_data, level: LevelResource):
	var data = JSON.parse_string(str_data)
	
	current_level = level
	for f in furnitures:
		f.remove()
	furnitures.clear()
	
	build()
	for f in data.furnitures:
		var nf := FURNITURE.instantiate() as Furniture
		var fr := Data.get_furniture_resource_by_name(f.name) as FurnitureResource
		furnitures_container.add_child(nf)
		nf.resource = fr
		nf.apply_grid_position(Vector2i(f.grid_position.x, f.grid_position.y))
		furnitures.push_back(nf)
		if Engine.is_editor_hint():
			nf.owner =  get_tree().edited_scene_root
			nf.position = get_transformed_position(nf.tile.grid_position)
			nf.target_position = get_transformed_position(nf.tile.grid_position)
		if f.flipped: nf.flip()
	
	player.position = get_transformed_position(left_door_position)

func switch_to_edit_mode():
	game_mode = GameMode.EditMode
	if player_room_data: load_room(player_room_data, levels[current_level_index])
	update_validity()
	update_counts()
	
func switch_to_puzzle_mode():
	player_room_data = save_room() # save to db
	game_mode = GameMode.PuzzleMode
	load_room(player_room_data, levels[current_level_index]) # load from db
	shuffle_room()
	animate_build()
	update_validity()

func animate_build(animate_level:=true, animate_furnitures:=true):
	if animate_level: for t in tiles.values(): t.set_visible(false)
	if animate_furnitures: for f in furnitures: f.set_visible(false)
	
	var speed = 0.05
	if animate_level:
		for t in tiles.values():
			await get_tree().create_timer(speed).timeout
			if not t: return;
			t.set_visible(true)
			t.scale = Vector2.ZERO
	
	if animate_furnitures:
		for f in furnitures:
			await get_tree().create_timer(0.2).timeout
			if not f: return;
			f.set_visible(true)
			f.position.y -= 200.0

var save_path := "user://savegame.save"
var username : String
func save_data():
	var data = {
		"username": username,
		"items": inventory.items.map(func(a): return a.furniture.name),
		"current_story_index": current_story_index,
		"online_level": current_level_index,
		"online_room": player_room_data
	}
	var save_file = FileAccess.open(save_path, FileAccess.WRITE)
	save_file.store_line(JSON.stringify(data))
	
func load_data():
	if not FileAccess.file_exists(save_path):
		return
	var save_file = FileAccess.open("user://savegame.save", FileAccess.READ)
	var data = JSON.parse_string(save_file.get_as_text())
	username = data.username
	if data.has("current_story_index"): current_story_index = data.current_story_index
	if data.has("online_level"): current_level_index = data.online_level
	if data.has("online_room"): player_room_data = data.online_room
	print(username, story_level, current_level_index, player_room_data)
