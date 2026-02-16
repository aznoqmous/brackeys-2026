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
		
@export var sprite_2d: Sprite2D
@export var sprite: CompressedTexture2D :
	set(value): 
		sprite = value
		if not sprite_2d: return;
		sprite_2d.material.set("shader_parameter/texture_albedo", value)

@export var selected_color: Color
@export var default_color: Color

var tile: Tile

func _ready():
	sprite_2d.material.set("shader_parameter/texture_albedo", sprite)
	update_state()

var last_position : Vector2
func _process(delta: float) -> void:
	if not main: return;
	if Engine.is_editor_hint():
		if tile and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			position = tile.position
		if position != last_position:
			if not main.tiles.has(main.get_untransformed_position(position)): return;
			var target_tile = main.tiles[main.get_untransformed_position(position)]
			if not target_tile: return
			if target_tile != tile and target_tile.is_occupied: return
			apply_position()

func load_resource(res: FurnitureResource):
	if not res or not sprite_2d: return;
	sprite = res.sprite
	sprite_2d.material.set("shader_parameter/texture_albedo", sprite)
	title_label.text = res.name
	description_label.text = get_description(res)
	name = get_furniture_name(res.type)

# register self to tile
func apply_position():
	if tile: tile.current_furniture = null
	var grid_pos = main.get_untransformed_position(position)
	main.tiles[grid_pos].current_furniture = self
	position = main.world_to_grid_position(position)
	tile = main.tiles[grid_pos]
	last_position = position

func update_state():
	sprite_2d.material.set("shader_parameter/color", selected_color if tile and tile.is_selected else default_color)

func get_description(res: FurnitureResource):
	var text = ""
	match res.requirement:
		FurnitureResource.FurnitureRequirement.NearFurniture:
			text += "needs to be placed near " + get_furniture_name(res.required_furniture)
	return text

func flip():
	scale.x = -scale.x

func get_furniture_name(type: FurnitureResource.FurnitureType):
	match type:
		FurnitureResource.FurnitureType.Chair: return "chair"
		FurnitureResource.FurnitureType.Table: return "table"
		FurnitureResource.FurnitureType.Plant: return "plant"
		FurnitureResource.FurnitureType.Shelf: return "shelf"
	return "Furniture"
