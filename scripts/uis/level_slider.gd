@tool
extends Control
class_name LevelSlider

@export var fill_nine_patch_rect: NinePatchRect
@export var background: TileScaleContainer
@export var fill: TileScaleContainer
@export var fill_container: Control
@export var background_color: Color
@export var fill_color: Color
@export_range(0, 1, 0.01) var value : float :
	set(v):
		value = clamp(0, 1, v)
@export var min_size_y := 70.0

func _process(delta):
	background.modulate = background_color
	fill.size.y = lerp(fill.size.y, (fill_container.size.y - min_size_y) * value + min_size_y, delta * 5.0)
	fill.position.y = fill_container.size.y - fill.size.y
	fill_nine_patch_rect.modulate = lerp(fill_nine_patch_rect.modulate, lerp(background_color, fill_color, value), delta * 5.0)

	
