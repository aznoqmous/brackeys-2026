@tool
extends Resource
class_name FurnitureResource

@export var name: String
@export var description: String
@export var type: FurnitureType
@export var max_count : int = 0
@export var sprite: CompressedTexture2D

@export_category("Requirement")
@export var requirement: FurnitureRequirement
@export var required_furniture: FurnitureType
		
@export var required_tile_attribute: TileAttribute



enum FurnitureRequirement {
	None,
	NearFurniture,
	OnTileWithAttribute
}

enum FurnitureType {
	Chair,
	Table,
	Plant,
	Shelf
}

enum TileAttribute {
	Window,
	Door,
	Wall
}
