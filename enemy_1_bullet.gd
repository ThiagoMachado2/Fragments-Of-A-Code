# EnemyBullet.gd
extends Area2D

var velocidade = 250.0
var direcao = Vector2.LEFT # O inimigo vai definir isso no momento do disparo

func _physics_process(delta):
	# Move o projétil
	position += direcao * velocidade * delta

# Esta é a função que DEVE estar conectada ao sinal 'body_entered'
func _on_body_entered(body: Node2D) -> void:
	
	# --- ESTA É A CORREÇÃO ---
	# Se acertou o próprio inimigo (ou qualquer outro inimigo), ignore.
	if body.is_in_group("Enemies"):
		return # Não faz nada, apenas continua voando
	
	# Se acertar o jogador
	if body.name == "RobotoBase":
		print("Acertou o jogador!")
		# No futuro, o script do roboto precisará ter a função take_damage
		# body.take_damage(1) 
		queue_free() # Destrói o projétil
		return # Para a execução aqui

	# Se acertar qualquer outra coisa (como uma parede, que é um StaticBody2D)
	# O projétil será destruído.
	queue_free()
