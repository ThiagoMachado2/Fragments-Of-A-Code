# Fase1.gd
extends Node2D

# Referências para o robô e a HUD (verifique se os nomes estão corretos!)
@onready var roboto = $RobotoBase
@onready var hud = $HUD

func _ready():
	# --- ESTA É A LINHA QUE FALTAVA ---
	# Conecta o sinal "health_updated" do robô
	# à função "update_health" da HUD.
	roboto.health_updated.connect(hud.update_health)
