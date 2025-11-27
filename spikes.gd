# Spike.gd (Anexado ao StaticBody2D)
extends StaticBody2D

# Certifique-se de que o StaticBody2D está no grupo "deadly" no Editor.

# O StaticBody2D não tem o sinal body_entered(), então vamos usar o Area2D filho.

func _on_hit_area_body_entered(body):
	# Verifica se o corpo que entrou é o personagem principal (RobotoBase)
	if body.name == "RobotoBase":
		# Chama a função de morte no jogador
		body.take_damage(999) 
		
# Você deve conectar o sinal 'body_entered(body)' do nó HitArea (Area2D filho)
# à esta função 'on_hit_area_body_entered' no editor.
