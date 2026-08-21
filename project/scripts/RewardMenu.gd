class_name RewardMenu
extends Control

@onready var card1 = $VBoxContainer/Card1
@onready var card2 = $VBoxContainer/Card2
@onready var card3 = $VBoxContainer/Card3
@onready var skip_btn = $VBoxContainer/SkipButton

signal on_reward_selected(reward_id: String)

var current_options: Array[String] = []

# Список локальных баффов (Roguelite-элементы на 1 забег)
var possible_rewards: Array[Dictionary] = [
	{"id": "dmg_up", "text": "+20% Damage"},
	{"id": "fire_rate_up", "text": "+15% Fire Rate"},
	{"id": "core_hp", "text": "+50 Core HP"},
	{"id": "pierce_chance", "text": "10% Pierce Chance"}
]

func _ready():
	hide()
	card1.pressed.connect(func(): _select_reward(0))
	card2.pressed.connect(func(): _select_reward(1))
	card3.pressed.connect(func(): _select_reward(2))
	skip_btn.pressed.connect(func(): on_reward_selected.emit("None"))

func generate_and_show_draft(unlocked_buildings: Array[String] = []):
	current_options.clear()

	# Перемешиваем баффы
	var shuffled_rewards = possible_rewards.duplicate()
	shuffled_rewards.shuffle()

	# Берем до 3 уникальных карточек баффов
	for i in range(min(3, shuffled_rewards.size())):
		current_options.append(shuffled_rewards[i]["id"])

	# Настраиваем UI кнопок
	if current_options.size() > 0:
		card1.text = _get_reward_text(current_options[0])
		card1.show()
	else:
		card1.hide()

	if current_options.size() > 1:
		card2.text = _get_reward_text(current_options[1])
		card2.show()
	else:
		card2.hide()

	if current_options.size() > 2:
		card3.text = _get_reward_text(current_options[2])
		card3.show()
	else:
		card3.hide()

	show()

func _get_reward_text(id: String) -> String:
	for r in possible_rewards:
		if r["id"] == id:
			return r["text"]
	return "Unknown Buff"

func _select_reward(index: int):
	if index < current_options.size():
		on_reward_selected.emit(current_options[index])
