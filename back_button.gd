extends Button

func _on_pressed() -> void:
	var target_scene = "res://MenuPause/pause_menu.tscn"
	
	# Verifica se a variável global tem um caminho salvo
	if Global.last_scene_path != "":
		target_scene = Global.last_scene_path
	
	# Retorna para a cena salva
	get_tree().change_scene_to_file(target_scene)

	# Opcional: Limpa o histórico após o uso
	# Global.last_scene_path = ""
