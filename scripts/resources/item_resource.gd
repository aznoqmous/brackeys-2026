extends Resource
class_name ItemResource

@export var name: String
@export var type: ItemType
@export_category("Furniture")
@export var furniture: FurnitureResource

enum ItemType {
	Furniture
}
