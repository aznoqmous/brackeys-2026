@tool
extends Resource
class_name FurnitureResource

@export var name: String
@export var description: String
@export var type: FurnitureType
@export var max_count : int = 0
@export var sprite: CompressedTexture2D
@export var size: int = 1 

@export_category("Requirement")
@export var requirements: Array[FurnitureRequirement]
	
enum FurnitureType {
	Chair,
	Table,
	Plant,
	Shelf,
	TV,
	Bed
}
