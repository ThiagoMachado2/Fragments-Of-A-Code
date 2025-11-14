# HUD.gd
extends CanvasLayer

# Pega uma referência a todos os pips dentro do HBoxContainer
@onready var pips = $HBoxContainer.get_children()

# Esta função será chamada pelo Roboto
func update_health(current_health):

	# Percorre todos os pips de vida
	for i in range(pips.size()):

		# Se o índice (i) for MENOR que a vida atual, o pip está "cheio"
		if i < current_health:
			pips[i].set_state(true) # Define o estado como "cheio" (vermelho)
		else:
			pips[i].set_state(false) # Define o estado como "vazio" (azul)
