@tool
extends Node2D
class_name Wall

@export var left_color: Color
@export var right_color: Color
@onready var sprite_2d: Sprite2D = $Sprite2D

func _ready() -> void:
	sprite_2d.modulate = left_color if scale.x > 0 else right_color
