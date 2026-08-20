class_name RewardMenu
extends Control

@onready var card1 = $VBoxContainer/Card1
@onready var card2 = $VBoxContainer/Card2
@onready var card3 = $VBoxContainer/Card3
@onready var skip_btn = $VBoxContainer/SkipButton

signal on_reward_selected(reward_id: String)

var current_options: Array[String] = []

# Полный список возможных наград-зданий (то, что не дается на старте)
var possible_rewards: Array[String] = [
	"Modifier",
	"Splitter",
	"Shotgun"
]

func _ready():
	hide()
	card1.pressed.connect(func(): _select_reward(0))
	card2.pressed.connect(func(): _select_reward(1))
	card3.pressed.connect(func(): _select_reward(2))
	skip_btn.pressed.connect(func(): on_reward_selected.emit("None"))

func generate_and_show_draft():
	current_options.clear()

	# Создаем копию пула и перемешиваем (в Godot 4 shuffle работает in-place)
	var pool_copy = possible_rewards.duplicate()
	pool_copy.shuffle()

	# Берем до 3 уникальных карточек
	for i in range(min(3, pool_copy.size())):
		current_options.append(pool_copy[i])

	# Настраиваем UI кнопок
	if current_options.size() > 0:
		card1.text = "Unlock: " + current_options[0]
		card1.show()
	else:
		card1.hide()

	if current_options.size() > 1:
		card2.text = "Unlock: " + current_options[1]
		card2.show()
	else:
		card2.hide()

	if current_options.size() > 2:
		card3.text = "Unlock: " + current_options[2]
		card3.show()
	else:
		card3.hide()

	show()

func _select_reward(index: int):
	if index < current_options.size():
		on_reward_selected.emit(current_options[index])
