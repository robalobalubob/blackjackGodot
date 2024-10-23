extends Node

var deck = []
var player_hand = []
var dealer_hand = []

# Called when the node enters the scene tree for the first time.
func _ready():
	shuffle_deck()
	start_game()
	connect_buttons()

func shuffle_deck():
	var suits = ["hearts", "diamonds", "clubs", "spades"]
	var ranks = ["ace", "2", "3", "4", "5", "6", "7", "8", "9", "10", "jack", "queen", "king"]
	deck.clear()
	for suit in suits:
		for rank in ranks:
			deck.append({"rank": rank, "suit": suit})
	deck.shuffle()

func start_game():
	clear_card_containers()
	player_hand = [draw_card(), draw_card()]
	dealer_hand = [draw_card(), draw_card()]
	
	update_ui()
	update_cards()

func connect_buttons():
	var hit_button = get_node("../MainPanel/MainVBox/ButtonsContainer/HitButton")
	var stand_button = get_node("../MainPanel/MainVBox/ButtonsContainer/StandButton")
	hit_button.pressed.connect(on_hit_pressed)
	stand_button.pressed.connect(on_stand_pressed)

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
	var player_score_label = get_node("../MainPanel/MainVBox/PlayerScoreLabel")
	var dealer_score_label = get_node("../MainPanel/MainVBox/DealerScoreLabel")
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
	
	var hit_button = get_node("../MainPanel/MainVBox/ButtonsContainer/HitButton")
	var stand_button = get_node("../MainPanel/MainVBox/ButtonsContainer/StandButton")
	hit_button.disabled = true
	stand_button.disabled = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_reset_button_pressed():
	player_hand.clear()
	dealer_hand.clear()
	
	shuffle_deck()
	
	clear_card_containers()
	
	var result_label = get_node("../MainPanel/MainVBox/ResultLabel")
	result_label.text = ""
	
	var hit_button = get_node("../MainPanel/MainVBox/ButtonsContainer/HitButton")
	var stand_button = get_node("../MainPanel/MainVBox/ButtonsContainer/StandButton")
	hit_button.disabled = false
	stand_button.disabled = false
	
	start_game()
