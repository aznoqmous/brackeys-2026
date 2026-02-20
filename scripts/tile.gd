@tool
class_name Tile
extends Area2D

@onready var main: Main = get_tree().edited_scene_root if Engine.is_editor_hint() else $/root/Main

@export var inner_sprite: Sprite2D
@export var selection_sprite: Sprite2D

@onready var door_sprites: Node2D = $Door
@onready var door_opened_sprite: Sprite2D = $Door/DoorOpened
@onready var wall_sprites: Node2D = $Wall
@onready var wall_right: Sprite2D = $Wall/WallRight
@onready var wall_left: Sprite2D = $Wall/WallLeft
@export var debug_label: Label

@onready var window_sprites: Node2D = $Window

@export var is_door: bool :
	set(value):
		is_door = value
		door_sprites.set_visible(value)
		
@export var is_wall: bool :
	set(value):
		is_wall = value
		wall_sprites.set_visible(value)
		
@export var is_window: bool :
	set(value):
		is_window = value
		window_sprites.set_visible(value)

@export var is_door_opened: bool :
	set(value):
		is_door_opened = value
		door_opened_sprite.set_visible(value)
		
var default_color: Color
var hovered := false
var grid_position : Vector2i

var current_furniture: Furniture
var current_player: Player
var is_occupied: bool :
	get: return current_player or current_furniture
var is_selected:= false

func _ready() -> void:
	default_color = inner_sprite.modulate
	mouse_entered.connect(func():
		inner_sprite.modulate = Color.WHITE
		hovered = true
	)
	
	mouse_exited.connect(func():
		inner_sprite.modulate = default_color
		hovered = false
	)
	debug_label.text = str(grid_position)
	
func _input(event: InputEvent) -> void:
	if hovered and event is InputEventMouseButton and event.is_pressed():
		clicked.emit()
		
func _process(delta: float) -> void:
	if not main: return;
	wall_left.material.set("shader_parameter/color", main.walls_color)
	wall_right.material.set("shader_parameter/color", main.walls_color.darkened(0.2))
	inner_sprite.modulate = main.walls_color.darkened(0.2)
	scale = lerp(scale, Vector2.ONE, delta * 5.0)

signal clicked()
