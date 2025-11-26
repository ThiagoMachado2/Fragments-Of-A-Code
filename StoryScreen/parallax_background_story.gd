extends ParallaxBackground

@export var scroll_speed: Vector2 = Vector2(100, 0) # Velocidade global

func _process(delta):
	# Atualiza cada camada baseada no tempo
	for layer in get_children():
		if layer is ParallaxLayer:
			var factor = layer.motion_scale
			var new_offset = layer.motion_offset + scroll_speed * factor * delta
			layer.motion_offset = new_offset
