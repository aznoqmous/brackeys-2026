@tool
extends Node

var furniture_resources: Dictionary[String, FurnitureResource]

func _ready():
	for fr in load_resources("res://resources/furnitures"):
		furniture_resources[fr.name] = fr
		
func get_furniture_resource_by_name(n):
	if furniture_resources.size() <= 0:
		for fr in load_resources("res://resources/furnitures"):
			furniture_resources[fr.name] = fr
	return furniture_resources.get(n)



	

func load_resources(path: String) -> Array[FurnitureResource]:
	var result: Array[FurnitureResource] = []
	
	var dir := DirAccess.open(path)
	if dir == null:
		return result
	
	dir.list_dir_begin()
	var file_name := dir.get_next()
	
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var full_path := path.path_join(file_name)
			
			var resource := load(full_path)
			if resource is FurnitureResource:
				result.append(resource)
		
		file_name = dir.get_next()
	
	dir.list_dir_end()
	return result
