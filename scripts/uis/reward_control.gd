extends Control
class_name RewardControl

@onready var main: Main = $/root/Main
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var label: Label = $Control/Label
@onready var furniture_label: Label = $Control/FurnitureLabel
@onready var furniture_texture: TextureRect = $Control/FurnitureTexture
@onready var star_texture: TextureRect = $Control/StarTexture
@onready var progress_button: Button = $Control/ProgressButton

var resource:  FurnitureResource

func _ready():
	progress_button.pressed.connect(func():
		set_visible(false)
		main.switch_to_edit_mode()
		main.inventory.add_furniture(resource)
	)

func _process(delta):
	label.scale = Vector2.ONE * (1.0 + sin(Time.get_ticks_msec()/1000.0 * 0.5) * 0.1)
	star_texture.rotation += delta * TAU / 2.0

func show_reward(res):
	set_visible(true)
	load_resource(res)
	animation_player.play("show")

func load_resource(res: FurnitureResource):
	resource = res
	furniture_label.text = res.name
	furniture_texture.texture = res.sprite
