# Smasher.gd (Versão Corrigida)
extends Node2D

# --- Variáveis de Configuração ---
@export var smash_duration: float = 1.0
@export var return_duration: float = 1.0
@export var wait_at_bottom_duration: float = 1.0
@export var smash_height_offset: float = 100.0 # O quanto o pistão desce

# --- Referências ---
@onready var timer = $Timer
@onready var anim_sprite = $Smashf1s
@onready var hitbox = $Hitbox # Referência para o Area2D

var start_position: Vector2
var end_position: Vector2
var is_smashing: bool = false

func _ready():
	# Salva as posições do HITBOX, não do smasher inteiro
	start_position = hitbox.position 
	end_position = start_position + Vector2(0, smash_height_offset)
	
	# Conecta o timer
	timer.timeout.connect(_on_timer_timeout)
	
	# Conecta o hitbox para causar dano
	hitbox.body_entered.connect(_on_hitbox_body_entered)
	
	# Desliga o hitbox no início (ele só é mortal quando está caindo)
	hitbox.monitoring = false
	
	# Inicia na animação "idle"
	anim_sprite.play("idle") # (Crie uma animação "idle" no seu AnimatedSprite)

func _on_timer_timeout():
	if is_smashing:
		return
	is_smashing = true
	start_smash_cycle()

func start_smash_cycle():
	# 1. Toca a animação visual
	anim_sprite.play("smashing") # (Use o nome da sua animação de ataque)
	
	# 2. Ativa o hitbox para ele poder colidir
	hitbox.monitoring = true
	
	# 3. Cria o Tween para mover APENAS O HITBOX
	var tween = create_tween()
	
	# Mover o hitbox para baixo
	tween.tween_property(hitbox, "position", end_position, smash_duration) \
		 .set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

	# Esperar no chão
	tween.tween_interval(wait_at_bottom_duration)
	
	# Mover o hitbox de volta para cima
	tween.tween_property(hitbox, "position", start_position, return_duration) \
		 .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# 4. Quando o ciclo terminar...
	await tween.finished
	is_smashing = false
	hitbox.monitoring = false # Desliga o hitbox de novo
	anim_sprite.play("idle")
	timer.start() # Reinicia o timer principal

# 5. Causa dano se tocar o jogador
func _on_hitbox_body_entered(body):
	# Verificamos se quem entrou é o jogador
	if body.name == "RobotoBase":
		# Chama a função de dano no jogador
		# (999 é um dano alto para "esmagamento")
		body.take_damage(999)
