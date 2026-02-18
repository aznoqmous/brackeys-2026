@tool
extends Node2D
class_name Furniture

@onready var main: Main = get_tree().edited_scene_root if Engine.is_editor_hint() else $/root/Main
#@onready var main: Main = $/root/Main
@onready var description_control: Control = $DescriptionControl
@onready var count_label: Label = $EditControl/CountLabel
@export var title_label: Label
@export var description_label: Label

@export var resource: FurnitureResource:
	set(value):
		resource = value
		load_resource(value)

@export var sprites_container: Node2D
@export var sprite_2d: Sprite2D
@export var sprite: CompressedTexture2D :
	set(value): 
		sprite = value
		if not sprite_2d: return;
		sprite_2d.material.set("shader_parameter/texture_albedo", value)

@export var shadow_sprite: Sprite2D
@export var shadow_sprite_2: Sprite2D


@export var selected_color: Color
@export var default_color: Color
@export var valid_color: Color
@export var preview_color: Color

var flipped : bool :
	get: return sprites_container.scale.x < 0
	
var tile: Tile
var tiles: Array[Tile]
@export var is_valid:=false
@export var is_preview := false

var target_position: Vector2

func _ready():
	sprite_2d.material.set("shader_parameter/texture_albedo", sprite)
	target_position = position
	update_state()

var last_position : Vector2
func _process(delta: float) -> void:
	if not main: return;
	scale = lerp(scale, Vector2.ONE * 1.1 if tile and tile.hovered and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) else Vector2.ONE, delta * 20.0)
	if Engine.is_editor_hint():
		if tile and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			#target_position = tile.position
			position = main.world_to_grid_position(position)
			position.y += 1 if resource.size == 2 else 0 # size 2 fix

		if target_position != last_position:
			if not main.tiles.has(main.get_untransformed_position(target_position)): return;
			var target_tile = main.tiles[main.get_untransformed_position(target_position)]
			if not target_tile: return
			if target_tile != tile and target_tile.is_occupied: return
			apply_position()
			
	else: position = lerp(position, target_position, delta * 20.0)
	if tile:
		description_control.set_visible(
			tile.hovered
			and not Input.is_action_pressed("LeftClick")
			and not main.preview_furniture
		)

func load_resource(res: FurnitureResource):
	if not res or not sprite_2d: return;
	sprite = res.sprite
	sprite_2d.material.set("shader_parameter/texture_albedo", sprite)
	title_label.text = res.name
	description_label.text = get_description(res)
	name = get_furniture_name(res.type)
	shadow_sprite.set_visible(res.size == 1)
	shadow_sprite_2.set_visible(res.size == 2)
	

# register self to tile
func apply_position():
	var grid_pos = main.get_untransformed_position(target_position)
	
	target_position = main.world_to_grid_position(target_position)
	target_position.y += 1 if resource.size == 2 else 0 # size 2 fix
	
	tile = main.tiles[grid_pos]
	last_position = target_position
	
	for t in tiles:
		t.current_furniture = null
	tiles.clear()
	for t in get_tiles(tile, flipped):
		tiles.push_back(t)
		t.current_furniture = self

func update_state()->void:
	#sprite_2d.material.set(
		#"shader_parameter/color", 
		#selected_color if tile and tile.is_selected else default_color
	#)
	if is_preview: return sprite_2d.material.set("shader_parameter/color", preview_color)
	if is_valid: return sprite_2d.material.set("shader_parameter/color", valid_color)
	sprite_2d.material.set("shader_parameter/color", default_color)

func get_description(res: FurnitureResource):
	var texts : Array
	for req in res.requirements:
		match req.requirement:
			FurnitureRequirement.Requirement.NearFurniture:
				texts.push_back("near " + get_furniture_name(req.furniture))
			FurnitureRequirement.Requirement.NotNearFurniture:
				texts.push_back("away from " + get_furniture_name(req.furniture))
			FurnitureRequirement.Requirement.NearWall:
				texts.push_back("near wall")
			FurnitureRequirement.Requirement.NearDoor:
				texts.push_back("near door")
			FurnitureRequirement.Requirement.NearWindow:
				texts.push_back("near window")
			FurnitureRequirement.Requirement.NotNearWall:
				texts.push_back("away from wall")
			FurnitureRequirement.Requirement.NotNearDoor:
				texts.push_back("away from door")
			FurnitureRequirement.Requirement.NotNearWindow:
				texts.push_back("away from window")
	if not res.requirements.size(): texts.push_back("anywhere")
	return "\n".join(texts)

func flip() -> bool:
	var ts = get_tiles(tile, not flipped)
	
	if ts.size() < resource.size: return false;
	for t in ts:
		if t.current_furniture and t.current_furniture != self: return false;
		
	sprites_container.scale.x = -sprites_container.scale.x

	apply_position()
	main.update_validity()
	return true

func get_furniture_name(type: FurnitureResource.FurnitureType):
	match type:
		FurnitureResource.FurnitureType.Chair: return "chair"
		FurnitureResource.FurnitureType.Table: return "table"
		FurnitureResource.FurnitureType.Plant: return "plant"
		FurnitureResource.FurnitureType.Shelf: return "shelf"
		FurnitureResource.FurnitureType.Bed: return "bed"
		FurnitureResource.FurnitureType.TV: return "tv"
	return "Furniture"

func update_validity() -> bool:
	for req in resource.requirements:
		for t in tiles:
			if not is_valid_requirement(req, t):
				is_valid = false
				return false
	is_valid = true
	return true
	
func is_valid_requirement(req: FurnitureRequirement, t: Tile) -> bool:
	match req.requirement:
		FurnitureRequirement.Requirement.None: return true
		FurnitureRequirement.Requirement.NearFurniture:
			var check = false
			for f in main.get_neighbor_furnitures(t.grid_position):
				if f.resource.type == req.furniture:
					check = true
					break;
			if not check: return false
		FurnitureRequirement.Requirement.NotNearFurniture:
			for f in main.get_neighbor_furnitures(t.grid_position):
				if f.resource.type == req.furniture:
					return false
		FurnitureRequirement.Requirement.NearWall:
			return t.is_wall
		FurnitureRequirement.Requirement.NearDoor:
			return t.is_door
		FurnitureRequirement.Requirement.NearWindow:
			return t.is_window
		FurnitureRequirement.Requirement.NotNearWall:
			return not t.is_wall
		FurnitureRequirement.Requirement.NotNearDoor:
			return not t.is_door
		FurnitureRequirement.Requirement.NotNearWindow:
			return not t.is_window
	return true

# returns owned tiles in placed on said tile
func get_tiles(ti: Tile, is_flipped:= true) -> Array[Tile]: 
	var direction = Vector2i.RIGHT if not is_flipped else Vector2i.DOWN
	#print(resource)
	var ts : Array[Tile]
	var grid_pos = main.get_untransformed_position(ti.position)
	for i in resource.size:
		var t = main.tiles.get(grid_pos + direction * i) as Tile
		if not t: continue;
		ts.push_back(t)
	return ts

func remove():
	for t in get_tiles(tile, flipped): t.current_furniture = null
	queue_free()

func update_count(value):
	count_label.text = str(value, "/", resource.max_count)
