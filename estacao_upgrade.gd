# Script: EstacaoUpgrade.gd
extends Area2D

# --- DADOS DO PUZZLE (Corrigido com 'var') ---
@export_category("Configuração do Puzzle de Código")

# Variáveis de exportação agora têm 'var' para serem acessíveis em todo o script.
@export var habilidade_para_desbloquear: String = "Dash"

@export_multiline var instrucao: String = "Complete o código para ativar o Módulo Dash:"

@export_multiline var codigo_antes_do_bloco: String = "func ativar_dash():"

@export var opcoes_de_codigo: Array[String] = [
	"    velocidade.x = FORCA_DASH",
	"    velocidade.y = FORCA_PULO",
	"    ativar_escudo()"
]
@export var opcao_correta: String = "    velocidade.x = FORCA_DASH"

@export_multiline var codigo_depois_do_bloco: String = ""
# --------------------------------------------------------------------

# Variável para saber se o jogador está dentro da área de interação.
var jogador_na_area = false

# Referência ao Label que exibe o texto de interação.
@onready var prompt_interacao: Label = $PromptInteracao

# Referência ao CollisionShape para desativar a interação após o uso.
@onready var station_collision: CollisionShape2D = $CollisionShape2D

# --- FUNÇÕES DE DETECÇÃO E INTERAÇÃO ---

func _on_body_entered(body: Node2D) -> void:
	# Verificamos se quem entrou é o jogador.
	if body.name == "RobotoBase":
		jogador_na_area = true
		print("Jogador entrou na área da estação.")
		
		# Mostra o prompt SOMENTE se a estação ainda não foi resolvida/desativada.
		if not station_collision.disabled:
			prompt_interacao.show()


func _on_body_exited(body: Node2D) -> void:
	if body.name == "RobotoBase":
		jogador_na_area = false
		
		# Esconde o prompt.
		prompt_interacao.hide()


func _unhandled_input(event):
	# Se o jogador estiver na área E pressionar a tecla "interagir"...
	# E a colisão da estação não estiver desativada (puzzle não resolvido)...
	if jogador_na_area and Input.is_action_just_pressed("interagir") and not station_collision.disabled:
		print("Interação detectada! Abrindo puzzle de código...")
		
		var tela_puzzle = get_tree().root.get_node("Fase1/TelaPuzzle")
		
		# Chamamos a função 'mostrar_puzzle_codigo' e passamos todos os dados.
		tela_puzzle.mostrar_puzzle_codigo(
			instrucao,
			codigo_antes_do_bloco,
			opcoes_de_codigo,
			opcao_correta,
			codigo_depois_do_bloco,
			habilidade_para_desbloquear
		)

		# Desativa o prompt de interação enquanto o puzzle está aberto.
		prompt_interacao.hide()
		
func _ready():
	# Encontra a tela de puzzle
	var tela_puzzle = get_tree().root.get_node("Fase1/TelaPuzzle")
	if tela_puzzle:
		# Conecta o sinal de sucesso à nossa nova função
		tela_puzzle.puzzle_resolvido.connect(_on_puzzle_resolvido)
		
	# Garante que o prompt começa escondido.
	prompt_interacao.hide()
	
# --- FUNÇÃO DE RESOLUÇÃO ---

func _on_puzzle_resolvido(habilidade_desbloqueada):
	# Verifica se a habilidade desbloqueada é a MINHA habilidade
	if habilidade_desbloqueada == habilidade_para_desbloquear:
		print("Estação " + habilidade_para_desbloquear + " desativada com sucesso!")
		
		# AGORA SIM, desativamos a estação permanentemente
		station_collision.set_deferred("disabled", true)
		$Sprite2D.modulate = Color.GRAY # Deixa cinza para mostrar que já foi usada
		
		# O prompt deve estar escondido permanentemente após o uso.
		prompt_interacao.hide()
