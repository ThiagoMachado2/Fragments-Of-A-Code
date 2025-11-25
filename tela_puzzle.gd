# Script: TelaPuzzle.gd
extends CanvasLayer

# Sinal que avisa o resto do jogo (o Roboto) que o puzzle foi resolvido.
signal puzzle_resolvido(habilidade_desbloqueada)

# Referências para os nós da sua cena.
# O Godot vai preencher essas variáveis automaticamente.
@onready var rich_text_label_codigo = $ColorRect/Panel/VBoxContainer/RichTextLabel
@onready var botoes_container = $ColorRect/Panel/VBoxContainer/HBoxContainer
@onready var botoes_resposta = [$ColorRect/Panel/VBoxContainer/HBoxContainer/BotaoResposta1,
								$ColorRect/Panel/VBoxContainer/HBoxContainer/BotaoResposta2,
								$ColorRect/Panel/VBoxContainer/HBoxContainer/BotaoResposta3]

# Variáveis internas para guardar a informação do puzzle atual.
var _habilidade_a_desbloquear = ""
var _resposta_correta = ""

# Função que roda uma vez quando a cena é iniciada.
func _ready() -> void:
	# Conecta o sinal 'pressed' de cada botão a uma única função de resposta.
	# .bind(botao) é um truque para sabermos qual botão foi pressionado.
	for botao in botoes_resposta:
		botao.pressed.connect(_on_botao_resposta_pressed.bind(botao))
	
	# A tela de puzzle começa escondida.
	hide()

# Função para montar o puzzle com visual melhorado
func mostrar_puzzle_codigo(instrucao, codigo_antes, opcoes, correta, codigo_depois, habilidade):
	_resposta_correta = correta
	_habilidade_a_desbloquear = habilidade
	
	# Limpa o texto anterior
	rich_text_label_codigo.clear()
	
	# --- MONTAGEM DO TEXTO BONITO (BBCode) ---
	
	# 1. Título/Instrução (Amarelo e Centralizado)
	rich_text_label_codigo.append_text("[center][color=#ffd700][b]" + instrucao + "[/b][/color][/center]\n\n")
	
	# Linha divisória
	rich_text_label_codigo.append_text("[center]_________________________________[/center]\n\n")
	
	# 2. Início do Código (Ciano)
	rich_text_label_codigo.append_text("[color=#4ec9b0]") 
	rich_text_label_codigo.append_text(codigo_antes)
	
	# 3. O Bloco Faltante (Vermelho Piscante)
	rich_text_label_codigo.append_text("\n[pulse freq=1.0 color=#ffffff ease=-2.0][color=#ff4444]    [ ... INSIRA O CÓDIGO AQUI ... ][/color][/pulse]\n")
	
	# 4. Resto do código
	rich_text_label_codigo.append_text(codigo_depois)
	rich_text_label_codigo.append_text("[/color]") # Fecha a cor do código
	
	# --- CONFIGURAÇÃO DOS BOTÕES ---
	for i in range(botoes_resposta.size()):
		if i < opcoes.size():
			botoes_resposta[i].text = opcoes[i]
			botoes_resposta[i].show()
		else:
			botoes_resposta[i].hide()

	# Mostra a tela e pausa o jogo
	show()
	get_tree().paused = true

# Esta função é chamada QUANDO QUALQUER um dos botões é pressionado.
func _on_botao_resposta_pressed(botao_pressionado):
	print("Um botão foi pressionado! O texto é: '", botao_pressionado.text, "'")
	# Verifica se o texto do botão pressionado é o mesmo da resposta correta.
	if botao_pressionado.text == _resposta_correta:
		# Acertou! Emite o sinal para o Roboto receber a habilidade.
		puzzle_resolvido.emit(_habilidade_a_desbloquear)
		print("Código correto! Habilidade '" + _habilidade_a_desbloquear + "' desbloqueada!")
	else:
		# Errou! Apenas imprime uma mensagem por enquanto.
		print("Bloco de código incorreto! Tente novamente.")
	
	# Esconde a tela de puzzle e despausa o jogo, não importa se acertou ou errou.
	hide()
	get_tree().paused = false
