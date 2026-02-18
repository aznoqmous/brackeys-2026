extends Resource
class_name FurnitureRequirement


@export var requirement : Requirement

@export_category("Near Furniture")
@export var furniture : FurnitureResource.FurnitureType

enum Requirement {
	None,
	
	NearFurniture,
	NotNearFurniture,
	
	NearWall,
	NearDoor,
	NearWindow,
	
	NotNearWall,
	NotNearDoor,
	NotNearWindow,
}
