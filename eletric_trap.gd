# EletricTrap.gd (Versão Dano Contínuo)
extends Node2D

@onready var anim_sprite = $AnimatedSprite2D
@onready var shock_area = $ShockArea

# Novo Timer para controlar a frequência do dano
var damage_timer: Timer
var player_in_trap = null # Guarda a referência do jogador

@export var damage_interval: float = 1.0 # Tempo entre os danos (segundos)

func _ready():
	anim_sprite.play("active")
	
	# Conecta os sinais de entrada e saída
	shock_area.body_entered.connect(_on_body_entered)
	shock_area.body_exited.connect(_on_body_exited)
	
	# Cria e configura o timer de dano via código
	damage_timer = Timer.new()
	damage_timer.wait_time = damage_interval
	damage_timer.one_shot = false # Repete infinitamente
	damage_timer.timeout.connect(_on_damage_timer_timeout)
	add_child(damage_timer)

# Quando o jogador ENTRA na armadilha
func _on_body_entered(body):
	if body.name == "RobotoBase":
		player_in_trap = body
		
		# Causa o primeiro dano imediatamente
		apply_damage()
		
		# Inicia o timer para os próximos danos
		damage_timer.start()

# Quando o jogador SAI da armadilha
func _on_body_exited(body):
	if body.name == "RobotoBase":
		player_in_trap = null
		damage_timer.stop() # Para de causar dano

# Chamado pelo Timer a cada 'damage_interval' segundos
func _on_damage_timer_timeout():
	if player_in_trap:
		apply_damage()

# Função auxiliar para aplicar o dano
func apply_damage():
	if player_in_trap and player_in_trap.has_method("take_damage"):
		print("O jogador tomou um choque contínuo!")
		player_in_trap.take_damage(1)
