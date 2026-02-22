class_name Player
extends Node2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@export var face_sprites: Array[CompressedTexture2D]
@export var accessories_sprites: Array[CompressedTexture2D]
@onready var body_inner: Sprite2D = $SpriteContainer/Face/BodyInner
@onready var hat: Sprite2D = $SpriteContainer/Face/Hat

func _ready() -> void:
	pass

func randomize():
	var tex = face_sprites.pick_random()
	body_inner.texture = tex
	body_inner.material.set("shader_parameter/texture_albedo", tex)
	
	var atex = accessories_sprites.pick_random()
	hat.texture = tex
	hat.material.set("shader_parameter/texture_albedo", atex)
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_up"):
		randomize()
