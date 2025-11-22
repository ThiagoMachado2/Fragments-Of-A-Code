# LevelGate.gd (Versão Portas Laterais)
extends Area2D

@export_file("*.tscn") var proxima_fase

# Referências para as portas esquerda e direita
@onready var porta_esquerda = $PortaEsquerda
@onready var porta_direita = $PortaDireita
@onready var collision_shape = $CollisionShape2D

func _ready():
	# Garante que ambas comecem fechadas
	porta_esquerda.play("idle")
	porta_direita.play("idle")
	
	# Conecta o sinal de entrada
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	# Verifica se quem entrou foi o Jogador
	if body.name == "RobotoBase":
		
		# Verifica se a próxima fase foi definida
		if proxima_fase == null or proxima_fase == "":
			print("ERRO: Nenhuma 'proxima_fase' definida neste portão!")
			return
			
		print("Portão ativado! Abrindo portas...")
		
		# 1. Desativa a colisão para evitar múltiplos disparos
		collision_shape.set_deferred("disabled", true)
		
		# 2. Toca a animação de abrir em AMBAS as portas ao mesmo tempo
		porta_esquerda.play("open")
		porta_direita.play("open")
		
		# 3. Espera a animação terminar (basta esperar por uma delas)
		await porta_esquerda.animation_finished
		
		# 4. Troca de fase
		print("Portas abertas. Trocando de fase...")
		call_deferred("mudar_fase")

func mudar_fase():
	get_tree().change_scene_to_file(proxima_fase)
