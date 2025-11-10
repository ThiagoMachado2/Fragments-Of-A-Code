# Enemy3Bullet.gd
extends Area2D

var velocidade = 300.0

func _physics_process(delta):
	# --- ESTA É A CORREÇÃO ---
	# Move o projétil "para frente" (ao longo do seu próprio eixo Y)
	# "transform.y" é a direção "para baixo" (frente) local do sprite.
	position += transform.y * velocidade * delta

# (O resto do seu script, incluindo a função _on_body_entered, permanece o mesmo)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Enemies"):
		return 
	
	if body.name == "RobotoBase":
		print("Armadilha (Enemy3) acertou o jogador!")
		# body.take_damage(1)
	
	queue_free()
