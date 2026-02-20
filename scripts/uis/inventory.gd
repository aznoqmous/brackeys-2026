@tool
extends Control
class_name Inventory
@onready var main: Main = get_tree().edited_scene_root if Engine.is_editor_hint() else $/root/Main

const INVENTORY_SLOT = preload("uid://dmlxdc460lr65")
@export var inventory_slots_container: GridContainer

@export var items : Array[ItemResource]
@export var inventory_size : int :
	set(value):
		inventory_size = value
		build_inventory()
@export var game_item_resources: Array[ItemResource]
var slots : Array[InventorySlot]

func _ready():
	build_inventory()

func _process(delta: float) -> void:
	set_visible(main.game_mode == main.GameMode.EditMode)
	position.x = lerp(position.x, -size.x if main.preview_furniture else 0.0, delta * 5.0)
	
func build_inventory():
	if not inventory_slots_container: return;
	for i in inventory_slots_container.get_children(): i.queue_free()
	slots.clear()
	for i in inventory_size:
		var slot := INVENTORY_SLOT.instantiate() as InventorySlot
		inventory_slots_container.add_child(slot)
		slots.push_back(slot)
		if items.size() > i: 
			slot.load_resource(items[i])
			slot.update_state()
			slot.clicked.connect(func(ir: ItemResource):
				main.set_preview_item(ir)
				items.remove_at(i)
				build_inventory()
			)

func add_item(ir: ItemResource):
	items.push_back(ir)
	build_inventory()
	
func add_furniture(furniture: FurnitureResource):
	var index = game_item_resources.find_custom(func(i): return i.furniture == furniture)
	var ir = game_item_resources[index] as ItemResource
	add_item(ir.duplicate())
	
