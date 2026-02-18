extends Node2D
class_name Coin

var life := 0.0

func _ready() -> void:
	scale = Vector2.ONE * 2.0
	
func _process(delta):
	scale = lerp(scale, Vector2.ONE, delta * 5.0)
	life += delta
	position.y -= delta * 30.0
	if life > 1.0: queue_free()
