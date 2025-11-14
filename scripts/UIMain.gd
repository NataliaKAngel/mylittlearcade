extends Control

const GACHA_SCENE := preload("res://scenes/GachaMachine.tscn")

@onready var center_area: Control = $CenterArea
@onready var spin_btn: Button    = $BottomBar/BottomRow/SpinAgain
@onready var ok_btn: Button      = $BottomBar/BottomRow/OKButton
@onready var coin_label: Label   = $TopHUD/TopRow/CurrencyGroup/CoinLabel
@onready var gem_label: Label    = $TopHUD/TopRow/CurrencyGroup/GemLabel

var gacha: Node = null

const RARITIES := ["common", "rare", "epic", "legendary"]

func _id_to_base(id: String) -> String:
	var parts := id.split("_")
	if parts.size() > 0 and parts[-1] in RARITIES:
		parts.remove_at(parts.size() - 1)
	return "_".join(parts)  # e.g. "frog_monkey"

func _texture_for(id: String) -> Texture2D:
	var base := _id_to_base(id)
	var path := "res://assets/textures/items/series1/%s.png" % base
	var tex := load(path)
	return tex if tex is Texture2D else null

func _pretty_item_name(id: String) -> String:
	var parts := id.split("_")
	if parts and parts[-1] in RARITIES:
		parts.remove_at(parts.size() - 1)
	for i in parts.size():
		if parts[i].length() > 0:
			parts[i] = parts[i][0].to_upper() + parts[i].substr(1)
	return " ".join(parts)


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
	var img: TextureRect = gacha.get_node("CenterContainer/Overlay/RevealImage")
	if img:
		img.visible = false
	spin_btn.disabled = true
	gacha.play_spin()

func _on_spin_started() -> void:
	# Kan vise liten “shaking…”-tekst etc. om du vil
	pass

func _on_ball_dropped(item_id: String) -> void:
	# text
	var hint: Label = gacha.get_node("CenterContainer/VBoxContainer/HintLabel")
	if hint:
		hint.text = "You got: %s" % _pretty_item_name(item_id)

	# image
	var img: TextureRect = gacha.get_node("CenterContainer/Overlay/RevealImage")
	if img:
		img.texture = _texture_for(item_id)
		img.visible = img.texture != null
		if img.visible:
			img.modulate.a = 0.0
			img.scale = Vector2(0.8, 0.8)
			var t := get_tree().create_tween()
			t.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			t.tween_property(img, "modulate:a", 1.0, 0.25)
			t.parallel().tween_property(img, "scale", Vector2(1, 1), 0.25)

	# buttons
	spin_btn.visible = false
	ok_btn.visible = true
	spin_btn.disabled = false

func _on_ok_pressed() -> void:
	# hide reveal image
	var img: TextureRect = gacha.get_node("CenterContainer/Overlay/RevealImage")
	if img:
		img.visible = false
	ok_btn.visible = false
	spin_btn.visible = true

func _on_coins_changed(value: int) -> void:
	if coin_label:
		coin_label.text = str(value)

func _on_empty_machine() -> void:
	var hint: Label = gacha.get_node("%HintLabel")
	if hint:
		hint.text = "Oh no! The machine is empty!"
