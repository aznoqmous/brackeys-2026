extends Control
class_name InventorySlot

@onready var main: Main = $/root/Main
@onready var texture_rect: TextureRect = $TextureRect
@onready var label: Label = $Label

var resource : ItemResource

func load_resource(res: ItemResource):
	resource = res
	label.text = res.name
	texture_rect.set_visible(true)
	label.set_visible(true)
	
	match res.type:
		ItemResource.ItemType.Furniture:
			texture_rect.texture = res.furniture.sprite

func empty():
	resource = null
	texture_rect.set_visible(false)
	label.set_visible(false)
	
func _gui_input(event: InputEvent) -> void:
	if not resource: return;
	if event is InputEventMouseButton and event.is_pressed():
		clicked.emit(resource)
		
signal clicked(res: ItemResource)
