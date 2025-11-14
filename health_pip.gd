# HealthPip.gd
extends TextureRect

# Carrega as duas texturas (Cheia e Vazia)
# Vamos usar a mais cheia e a mais vazia para clareza
var texture_full = preload("res://ui/cyberpunk/2 Bars/HealthBar1.png")
var texture_empty = preload("res://ui/cyberpunk/2 Bars/HealthBar8.png")

func _ready():
	# Garante que o pip comece cheio
	set_state(true)

# Função para mudar o estado do pip
func set_state(is_full: bool):
	if is_full:
		self.texture = texture_full
	else:
		self.texture = texture_empty
