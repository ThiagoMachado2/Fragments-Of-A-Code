# Enemy2Bullet.gd
extends Area2D

var velocidade = 300.0
var direcao = Vector2.LEFT

func _physics_process(delta):
	position += direcao * velocidade * delta

# Conecte este sinal ao nó raiz no editor (Nó -> Sinais -> body_entered)
func _on_body_entered(body: Node2D) -> void:
	# Ignora outros inimigos
	if body.is_in_group("Enemies"):
		return 

	# Causa dano no jogador
	if body.name == "RobotoBase":
		print("Inimigo 2 acertou o jogador!")
		body.take_damage(1) # Descomente quando o Roboto tiver essa função

	# Destrói o projétil ao acertar o jogador ou uma parede
	queue_free()
