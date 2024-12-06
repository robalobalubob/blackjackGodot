extends Node

var deck = []
var player_hand = []
var dealer_hand = []

var player_money = 100
var bet = 0

var bet_input_regex = RegEx.new()
var old_text = ""

# Called when the node enters the scene tree for the first time.
func _ready():
	bet_input_regex.compile("^[0-9.]*$")
	shuffle_deck()
	init_game()
	connect_buttons()

func shuffle_deck():
	var suits = ["hearts", "diamonds", "clubs", "spades"]
	var ranks = ["ace", "2", "3", "4", "5", "6", "7", "8", "9", "10", "jack", "queen", "king"]
	deck.clear()
	for suit in suits:
		for rank in ranks:
			deck.append({"rank": rank, "suit": suit})
	deck.shuffle()

func init_game():
	var reset_button_container = get_node("../MainPanel/MainVBox/ResetButtonContainer")
	reset_button_container.visible = false
	update_ui()
	hide_buttons()
	if (player_money == 0):
		var player_money_label = get_node("../MainPanel/MainVBox/PlayerContainer/PlayerMoneyLabel")
		player_money_label.text = "Out of Money! \n Please press the reset button." 
		reset_button_container.visible = true
	else:
		show_bet()

func hide_bet():
	var bet_container = get_node("../MainPanel/MainVBox/BetContainer")
	bet_container.visible = false

func show_bet():
	var bet_container = get_node("../MainPanel/MainVBox/BetContainer")
	bet_container.visible = true
	
func hide_buttons():
	var button_container = get_node("../MainPanel/MainVBox/ButtonsContainer")
	button_container.visible = false

func show_buttons():
	var button_container = get_node("../MainPanel/MainVBox/ButtonsContainer")
	button_container.visible = true
	
func start_game():
	hide_bet()
	show_buttons()
	clear_card_containers()
	player_hand = [draw_card(), draw_card()]
	dealer_hand = [draw_card(), draw_card()]
	
	update_ui()
	update_cards()

func connect_buttons():
	var hit_button = get_node("../MainPanel/MainVBox/ButtonsContainer/HitButton")
	var stand_button = get_node("../MainPanel/MainVBox/ButtonsContainer/StandButton")
	var bet_button = get_node("../MainPanel/MainVBox/BetContainer/BetButton")
	var reset_button = get_node("../MainPanel/MainVBox/ResetButtonContainer/TrueResetButton")
	hit_button.pressed.connect(on_hit_pressed)
	stand_button.pressed.connect(on_stand_pressed)
	bet_button.pressed.connect(on_bet_pressed)
	reset_button.pressed.connect(on_true_reset_pressed)

func draw_card():
	return deck.pop_back()

func calculate_score(hand):
	var score = 0
	var aces = 0
	for card in hand:
		var rank = card["rank"]
		if rank in ["jack", "queen", "king"]:
			score += 10
		elif rank == "ace":
			aces += 1
			score += 11
		else:
			score += int(rank)
	while score > 21 and aces > 0:
		score -= 10
		aces -= 1
	return score

func update_ui():
	var player_score_label = get_node("../MainPanel/MainVBox/PlayerContainer/PlayerScoreLabel")
	var player_money_label = get_node("../MainPanel/MainVBox/PlayerContainer/PlayerMoneyLabel")
	var dealer_score_label = get_node("../MainPanel/MainVBox/DealerScoreLabel")
	player_money_label.text = "Player Money: " + str(player_money)
	if (calculate_score(player_hand) == 0):
		player_score_label.text = ""
	if (calculate_score(dealer_hand) == 0):
		dealer_score_label.text = ""
	else:
		player_score_label.text = "Player Score: " + str(calculate_score(player_hand))
		dealer_score_label.text = "Dealer Score: " + str(calculate_score(dealer_hand))

func update_cards():
	var player_container = get_node("../MainPanel/MainVBox/PlayerCardsContainer")
	for child in player_container.get_children():
		player_container.remove_child(child)
		child.queue_free()
	for card in player_hand:
		var card_texture = create_card_texture(card)
		player_container.add_child(card_texture)
	
	var dealer_container = get_node("../MainPanel/MainVBox/DealerCardsContainer")
	for child in dealer_container.get_children():
		dealer_container.remove_child(child)
		child.queue_free()
	for card in dealer_hand:
		var card_texture = create_card_texture(card)
		dealer_container.add_child(card_texture)

func create_card_texture(card):
	var card_texture = TextureRect.new()
	var card_image_path = "res://assets/cards/" + card["rank"] + "_of_" + card["suit"] + ".png"
	card_texture.texture = load(card_image_path)
	
	card_texture.custom_minimum_size = Vector2(100, 146)
	card_texture.stretch_mode = TextureRect.StretchMode.STRETCH_SCALE
	
	return card_texture

func clear_card_containers():
	var player_container = get_node("../MainPanel/MainVBox/PlayerCardsContainer")
	for child in player_container.get_children():
		player_container.remove_child(child)
		child.queue_free()
	var dealer_container = get_node("../MainPanel/MainVBox/DealerCardsContainer")
	for child in dealer_container.get_children():
		dealer_container.remove_child(child)
		child.queue_free()

func on_hit_pressed():
	player_hand.append(draw_card())
	update_ui()
	update_cards()
	if calculate_score(player_hand) > 21:
		game_over("Player Busts!")
	
func on_stand_pressed():
	dealer_turn()

func dealer_turn():
	while calculate_score(dealer_hand) < 17:
		dealer_hand.append(draw_card())
	update_ui()
	update_cards()
	check_winner()

func check_winner():
	var player_score = calculate_score(player_hand)
	var dealer_score = calculate_score(dealer_hand)
	if dealer_score > 21 or player_score > dealer_score:
		game_over("Player Wins!")
	elif player_score == dealer_score:
		game_over("It's a Tie!")
	else:
		game_over("Dealer Wins!")

func game_over(result):
	var result_label = get_node("../MainPanel/MainVBox/ResultLabel")
	result_label.text = result
	if (result == "Player Wins!"):
		player_money += 2*bet
	elif (result == "It's a Tie!"):
		player_money += bet
	await get_tree().create_timer(3).timeout
	_on_reset_button_pressed()

func _on_reset_button_pressed():
	player_hand.clear()
	dealer_hand.clear()
	
	shuffle_deck()
	
	clear_card_containers()
	
	var result_label = get_node("../MainPanel/MainVBox/ResultLabel")
	result_label.text = ""
	bet = 0
	init_game()

func on_true_reset_pressed():
	player_money = 100
	_on_reset_button_pressed()

func on_bet_pressed():
	var bet_input = get_node("../MainPanel/MainVBox/BetContainer/BetInput")
	handle_bet(bet_input.text)

func _on_line_edit_text_changed(new_text: String) -> void:
	var bet_input = get_node("../MainPanel/MainVBox/BetContainer/BetInput")
	if bet_input_regex.search(new_text):
		old_text = str(new_text)
	else:
		bet_input.text = old_text
		bet_input.set_caret_column(bet_input.text.length())

func _on_line_edit_text_submitted(new_text: String) -> void:
	handle_bet(new_text)

func handle_bet(bet_text: String):
	var bet_error = get_node("../MainPanel/MainVBox/BetContainer/BetError")
	if (bet_text.to_int() > player_money):
		bet_error.visible = true
		bet_error.text = "Bet exceeds player money"
		await get_tree().create_timer(3).timeout
		bet_error.visible = false
		bet_error.text = ""
	else:
		bet = bet_text.to_int()
		player_money -= bet
		start_game()
