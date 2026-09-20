extends Sprite2D


# Randomizes nebula everytime it's called
func _ready() -> void:
	var noise_tex : NoiseTexture2D = texture
	noise_tex.noise.seed = randi()
