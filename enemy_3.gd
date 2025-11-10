# Enemy3.gd (Versão CORRIGIDA com await)
extends Node2D

# Carrega o "molde" do projétil
const BULLET_SCENE = preload("res://enemy_3_bullet.tscn")

@onready var turret_sprite: AnimatedSprite2D = $TurretSprite
@onready var attack_effect: AnimatedSprite2D = $AttackEffect
@onready var fire_point: Marker2D = $FirePoint
@onready var timer: Timer = $Timer

# --- NOVO: Delay para Sincronização ---
# Este é o tempo (em segundos) entre o início da animação "fire"
# e o momento em que o tiro deve sair.
# Ex: Se sua animação tem 10 frames e 10 FPS, e o tiro sai no
# frame 7, o delay deve ser 0.7 (7 / 10).
@export var fire_delay: float = 0.7

# Trava para impedir múltiplos disparos
var is_attacking = false

func _ready():
	# Conecta os sinais
	timer.timeout.connect(_on_timer_timeout)
	turret_sprite.animation_finished.connect(_on_animation_finished)
	
	turret_sprite.play("idle")

# 1. O Timer dispara (a cada 2s)
func _on_timer_timeout():
	# Se já estivermos atacando, não faz nada
	if is_attacking:
		return
		
	is_attacking = true
	
	# 2. Toca as animações de "carregamento"
	# (Certifique-se de que o "Loop" delas está DESLIGADO no editor)
	turret_sprite.play("fire")
	attack_effect.play("fire")

	# 3. Espera o tempo de delay que definimos
	await get_tree().create_timer(fire_delay).timeout
	
	# 4. Se ainda estivermos no estado de ataque, atira!
	if is_attacking:
		_fire_projectile()

# 5. Função que realmente cria o projétil
func _fire_projectile():
	var bullet = BULLET_SCENE.instantiate()
	bullet.global_transform = fire_point.global_transform
	get_parent().add_child(bullet)

# 6. Quando a animação "fire" da torreta TERMINA
func _on_animation_finished():
	if turret_sprite.animation == "fire":
		# Volta ao estado ocioso
		turret_sprite.play("idle")
		is_attacking = false
		# Reinicia o timer para o próximo ciclo
		timer.start()
