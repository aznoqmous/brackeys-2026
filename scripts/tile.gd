@tool
class_name Tile
extends Area2D

@export var inner: Sprite2D
@export var selection: Sprite2D

var default_color: Color
var hovered := false
var grid_position : Vector2i

func _ready() -> void:
	default_color = inner.modulate
	mouse_entered.connect(func():
		inner.modulate = Color.WHITE
		hovered = true
	)
	
	mouse_exited.connect(func():
		inner.modulate = default_color
		hovered = false
	)
	
func _input(event: InputEvent) -> void:
	if hovered and event is InputEventMouseButton and event.is_pressed():
		clicked.emit()

signal clicked()
