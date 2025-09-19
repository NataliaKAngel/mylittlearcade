extends Control

const GACHA_SCENE := preload("res://scenes/GachaMachine.tscn")

@onready var center_area: Control = $CenterArea
@onready var spin_btn: Button    = $BottomBar/BottomRow/SpinAgain
@onready var ok_btn: Button      = $BottomBar/BottomRow/OKButton
@onready var coin_label: Label   = $TopHUD/TopRow/CurrencyGroup/CoinLabel
@onready var gem_label: Label    = $TopHUD/TopRow/CurrencyGroup/GemLabel

var gacha: Node = null

func _ready() -> void:
	# Instance GachaMachine inn i CenterArea
	gacha = GACHA_SCENE.instantiate()
	center_area.add_child(gacha)
	if gacha is Control:
		(gacha as Control).set_anchors_preset(Control.PRESET_FULL_RECT)

	# Koble knapper
	spin_btn.pressed.connect(_on_spin_pressed)
	ok_btn.pressed.connect(_on_ok_pressed)
	ok_btn.visible = false

	# HUD-oppdateringer
	if GameState.has_signal("coins_changed"):
		GameState.coins_changed.connect(_on_coins_changed)
	_on_coins_changed(GameState.coins)

	# Lytt til maskinens signaler
	gacha.spin_started.connect(_on_spin_started)
	gacha.ball_dropped.connect(_on_ball_dropped)
	gacha.empty_machine.connect(_on_empty_machine)

func _on_spin_pressed() -> void:
	spin_btn.disabled = true
	gacha.play_spin()

func _on_spin_started() -> void:
	# Kan vise liten “shaking…”-tekst etc. om du vil
	pass

func _on_ball_dropped(item_id: String) -> void:
	# Vis reveal i maskinens HintLabel
	var hint: Label = gacha.get_node("%HintLabel")
	if hint:
		hint.text = "You got: %s" % item_id

	spin_btn.visible = false
	ok_btn.visible = true
	spin_btn.disabled = false

func _on_ok_pressed() -> void:
	ok_btn.visible = false
	spin_btn.visible = true

func _on_coins_changed(value: int) -> void:
	if coin_label:
		coin_label.text = str(value)

func _on_empty_machine() -> void:
	var hint: Label = gacha.get_node("%HintLabel")
	if hint:
		hint.text = "Oh no! The machine is empty!"
