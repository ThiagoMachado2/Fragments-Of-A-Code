# EstacaoUpgrade.gd
extends Area2D

# --- DADOS DO PUZZLE (Você vai preencher no editor do Godot!) ---
# A categoria organiza os campos no Inspetor.
@export_category("Configuração do Puzzle de Código")

# A habilidade que este puzzle vai desbloquear.
@export var habilidade_para_desbloquear: String = "Dash"

# A instrução que aparece no topo da tela de puzzle.
@export_multiline var instrucao: String = "Complete o código para ativar o Módulo Dash:"

# O bloco de código que aparece ANTES do espaço a ser preenchido.
@export_multiline var codigo_antes_do_bloco: String = "func ativar_dash():"

# As opções de código que aparecerão nos botões.
@export var opcoes_de_codigo: Array[String] = [
	"    velocidade.x = FORCA_DASH", 
	"    velocidade.y = FORCA_PULO", 
    "    ativar_escudo()"
]

# O texto exato da opção correta.
@export var opcao_correta: String = "    velocidade.x = FORCA_DASH"

# O bloco de código que aparece DEPOIS do espaço.
@export_multiline var codigo_depois_do_bloco: String = ""
# --------------------------------------------------------------------

# Variável para saber se o jogador está dentro da área de interação.
var jogador_na_area = false

# Esta função é chamada automaticamente quando um corpo entra na área.
func _on_body_entered(body: Node2D) -> void:
	# Verificamos se quem entrou é o jogador (pelo nome do nó dele).
	if body.name == "RobotoBase":
		jogador_na_area = true
		print("Jogador entrou na área da estação. Pressione 'E' para interagir.")


# Esta função é chamada quando o corpo sai da área.
func _on_body_exited(body: Node2D) -> void:
	if body.name == "RobotoBase":
		jogador_na_area = false


# Esta função verifica o input do jogador a cada frame.
func _unhandled_input(event):
	# Se o jogador estiver na área E pressionar a tecla "interagir"...
	if jogador_na_area and Input.is_action_just_pressed("interagir"):
		print("Interação detectada! Abrindo puzzle de código...")
		
		# AQUI ESTÁ A MÁGICA:
		# 1. Encontramos a nossa TelaPuzzle na cena principal do jogo.
		#    !! ATENÇÃO: Altere "NomeDaSuaCenaPrincipal" para o nome real da sua fase !!
		var tela_puzzle = get_tree().root.get_node("PersonagensTestes/TelaPuzzle")
		
		# 2. Chamamos a função 'mostrar_puzzle_codigo' e passamos todos os dados.
		tela_puzzle.mostrar_puzzle_codigo(
			instrucao,
			codigo_antes_do_bloco,
			opcoes_de_codigo,
			opcao_correta,
			codigo_depois_do_bloco,
			habilidade_para_desbloquear
		)

		# Desativa a estação para que não possa ser usada novamente.
		$CollisionShape2D.set_deferred("disabled", true)
		# Opcional: mude a cor do sprite para mostrar que já foi usado.
		$Sprite2D.modulate = Color.GRAY
