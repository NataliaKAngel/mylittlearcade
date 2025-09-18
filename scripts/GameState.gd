extends Node

signal coins_changed(new_value:int)
signal pool_changed(remaining:int)
signal item_revealed(item_id:String)

var coins:int = 2000
var spin_cost:int = 100

# 60 baller = 60 “loot entries”
# Bruk id’er som du senere kobler til figur/ikon.
var pool:Array[String] = []

var inventory := {} # {item_id: count}

func _ready() -> void:
	_reset_pool()

func _reset_pool() -> void:
	pool.clear()
	# Fyll 60 baller – eksempel med vekting (flest common, færre epic/legendary)
	var ids := [
		"frog_monkey_common",
		"cat_common",
		"duck_common",
		"bunny_rare",
		"hedgehog_rare",
		"raccoon_rare",
		"frog_monkey_epic",
		"bunny_epic",
		"legendary_dragon"
	]
	var weights := [18, 14, 12, 6, 4, 4, 2, 2, 1] # summer ~63, vi klipper til 60
	for i in ids.size():
		for j in weights[i]:
			if pool.size() < 60:
				pool.append(ids[i])
	pool.shuffle()
	emit_signal("pool_changed", pool.size())

func can_spin() -> bool:
	return coins >= spin_cost and pool.size() > 0

func spin() -> String:
	if pool.is_empty():
		return ""
	coins -= spin_cost
	emit_signal("coins_changed", coins)
	var item_id: String = pool.pop_back() as String # “trekker” en ball
	emit_signal("pool_changed", pool.size())
	# oppdater inventory
	inventory[item_id] = (inventory.get(item_id, 0) as int) + 1
	emit_signal("item_revealed", item_id)
	return item_id

func pool_remaining() -> int:
	return pool.size()
