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

# !! ESTA É A FUNÇÃO MAIS IMPORTANTE !!
# É ela que torna sua tela reutilizável.
# A EstacaoUpgrade vai chamar esta função e passar os textos de cada puzzle.
func mostrar_puzzle_codigo(instrucao, codigo_antes, opcoes, correta, codigo_depois, habilidade):
	# 1. Guarda os dados do puzzle atual.
	_resposta_correta = correta
	_habilidade_a_desbloquear = habilidade
	
	# 2. Limpa o texto do puzzle anterior.
	rich_text_label_codigo.clear()
	
	# 3. Monta o novo texto do código usando BBCode para formatar.
	rich_text_label_codigo.append_text(instrucao + "\n\n")
	rich_text_label_codigo.append_text(codigo_antes)
	
	# Adiciona um bloco destacado para o código faltante.
	rich_text_label_codigo.push_color(Color.YELLOW) # Muda a cor para amarelo.
	rich_text_label_codigo.append_text("\n    [ ... complete o código aqui ... ]\n")
	rich_text_label_codigo.pop() # Volta para a cor padrão.
	
	rich_text_label_codigo.append_text(codigo_depois)
	
	# 4. Configura os botões com as opções de código para este puzzle.
	for i in range(botoes_resposta.size()):
		if i < opcoes.size():
			botoes_resposta[i].text = opcoes[i]
			botoes_resposta[i].show()
		else:
			botoes_resposta[i].hide() # Esconde botões que não são usados.

	# 5. Mostra a tela de puzzle e pausa o jogo.
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
