extends Control
class_name InventorySlot

@onready var main: Main = $/root/Main
@onready var texture_rect: TextureRect = $TextureRect
@onready var label: Label = $Label
@onready var score_control: Control = $ScoreControl
@onready var score_label: Label = $ScoreControl/ScoreLabel

var resource : ItemResource

var hovered := false
func _ready():
	mouse_entered.connect(func():
		hovered = true
		main.hovered_furniture_resource = resource.furniture if (resource and resource.type == ItemResource.ItemType.Furniture) else null
	)
	mouse_exited.connect(func():
		hovered = false
		main.hovered_furniture_resource = null
	)
	
func _process(delta: float) -> void:
	texture_rect.scale = lerp(texture_rect.scale, Vector2.ONE * 1.2 if hovered else Vector2.ONE, delta * 10.0)

func load_resource(res: ItemResource):
	resource = res
	label.text = res.name
	texture_rect.set_visible(true)
	label.set_visible(true)
	match res.type:
		ItemResource.ItemType.Furniture:
			texture_rect.texture = res.furniture.sprite
			score_label.text = str(res.furniture.score)
			score_control.set_visible(true)

func empty():
	resource = null
	texture_rect.set_visible(false)
	label.set_visible(false)
	score_control.set_visible(false)
	
func _gui_input(event: InputEvent) -> void:
	if not resource: return;
	if event is InputEventMouseButton and event.is_pressed():
		match resource.type:
			ItemResource.ItemType.Furniture:
				var count = main.furniture_counts.get(resource.furniture)
				count = count if count else 0
				if count >= resource.furniture.max_count:
					return
		clicked.emit(resource)
			
func update_state():
	modulate = Color.WHITE
	if not resource: return;
	match resource.type:
		ItemResource.ItemType.Furniture:
			var count = main.furniture_counts.get(resource.furniture)
			count = count if count else 0
			if count >= resource.furniture.max_count:
				modulate = Color.DIM_GRAY
			
signal clicked(res: ItemResource)
