@tool
extends Node2D
class_name Furniture

@onready var main: Main = $/root/Main

@export var sprite_2d: Sprite2D
@export var sprite: CompressedTexture2D :
	set(value): 
		sprite = value
		if not sprite_2d: return;
		sprite_2d.material.set("shader_parameter/texture_albedo", value)

func _ready():
	sprite_2d.material.set("shader_parameter/texture_albedo", sprite)

var last_position : Vector2
func _process(delta: float) -> void:
	if not main:
		main = get_tree().root.get_child(0) as Main
		return;
	if position != last_position and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		position = main.world_to_grid_position(position)
		last_position = position
