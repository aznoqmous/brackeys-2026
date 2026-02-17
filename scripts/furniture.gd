@tool
extends Node2D
class_name Furniture

@onready var main: Main = get_tree().edited_scene_root if Engine.is_editor_hint() else $/root/Main
#@onready var main: Main = $/root/Main
@onready var description_control: Control = $DescriptionControl
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

var tile: Tile
var tiles: Array[Tile]
@export var is_valid:=false

var target_position: Vector2

func _ready():
	sprite_2d.material.set("shader_parameter/texture_albedo", sprite)
	target_position = position
	update_state()

var last_position : Vector2
func _process(delta: float) -> void:
	position = lerp(position, target_position, delta * 20.0)
	if not main: return;
	if Engine.is_editor_hint():
		if tile and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			target_position = tile.position
		if target_position != last_position:
			if not main.tiles.has(main.get_untransformed_position(target_position)): return;
			var target_tile = main.tiles[main.get_untransformed_position(target_position)]
			if not target_tile: return
			if target_tile != tile and target_tile.is_occupied: return
			apply_position()

	if tile: description_control.set_visible(tile.hovered and not Input.is_action_pressed("LeftClick"))

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
	for t in tiles:
		t.current_furniture = null
	tiles.clear()
	
	var grid_pos = main.get_untransformed_position(target_position)

	if tile: tile.current_furniture = null
	main.tiles[grid_pos].current_furniture = self
	target_position = main.world_to_grid_position(target_position)
	tile = main.tiles[grid_pos]
	last_position = target_position
	
	tiles.clear()
	
	var direction = Vector2i.RIGHT if sprites_container.scale.x > 0 else Vector2i.DOWN
	for i in resource.size:
		var tile = main.tiles.get(grid_pos + direction * i) as Tile
		tiles.push_back(tile)
		tile.current_furniture = self

func update_state():
	#sprite_2d.material.set(
		#"shader_parameter/color", 
		#selected_color if tile and tile.is_selected else default_color
	#)
	sprite_2d.material.set(
		"shader_parameter/color", 
		valid_color if is_valid else default_color
	)

func get_description(res: FurnitureResource):
	var text = ""
	for req in res.requirements:
		match req.requirement:
			FurnitureRequirement.Requirement.NearFurniture:
				text += "needs to be placed near " + get_furniture_name(req.furniture)
	return text

func flip():
	var ts = get_tiles(tile, -scale.x)
	for t in ts:
		if not t or (t.current_furniture and t.current_furniture != self): return;
		
	sprites_container.scale.x = -sprites_container.scale.x

	apply_position()
	main.update_validity()

func get_furniture_name(type: FurnitureResource.FurnitureType):
	match type:
		FurnitureResource.FurnitureType.Chair: return "chair"
		FurnitureResource.FurnitureType.Table: return "table"
		FurnitureResource.FurnitureType.Plant: return "plant"
		FurnitureResource.FurnitureType.Shelf: return "shelf"
	return "Furniture"

func update_validity() -> bool:
	for req in resource.requirements:
		if not is_valid_requirement(req):
			is_valid = false
			return false
	is_valid = true
	return true
	
func is_valid_requirement(req: FurnitureRequirement) -> bool:
	match req.requirement:
		FurnitureRequirement.Requirement.None: return true
		FurnitureRequirement.Requirement.NearFurniture:
			var check = false
			for f in main.get_neighbor_furnitures(tile.grid_position):
				if f.resource.type == req.furniture:
					check = true
					break;
			if not check: return false
		FurnitureRequirement.Requirement.NotNearFurniture:
			for f in main.get_neighbor_furnitures(tile.grid_position):
				if f.resource.type == req.furniture:
					return false
		FurnitureRequirement.Requirement.NearWall:
			return tile.is_wall
		FurnitureRequirement.Requirement.NearDoor:
			return tile.is_door
		FurnitureRequirement.Requirement.NearWindow:
			return tile.is_window
	return true

# returns owned tiles in placed on said tile
func get_tiles(ti: Tile, flipped:= true) -> Array[Tile]: 
	var direction = Vector2i.RIGHT if not flipped else Vector2i.DOWN
	#print(resource)
	var ts : Array[Tile]
	var grid_pos = main.get_untransformed_position(ti.position)
	for i in resource.size:
		var t = main.tiles.get(grid_pos + direction * i) as Tile
		if not t: continue;
		ts.push_back(t)
	return ts
