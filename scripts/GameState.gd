extends Node

signal coins_changed(value: int)
signal pool_changed(remaining: int)
signal item_revealed(item_id: String)

@export var starting_coins: int = 1000
@export var spin_cost: int = 100
@export var copies_per_item: int = 10  # ← 10 kopier av hver figur

# Baseliste med de 6 figurene dine
const BASE_ITEMS: Array[String] = [
	"frog_monkey_common",
	"raccon_monkey_common",
	"fox_monkey_common",
	"hedgehog_monkey_common",
	"chiken_monkey_common",
	"bunny_monkey_common",
]

var coins: int
var inventory: Array[String] = []
var pool: Array[String] = []
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	coins = starting_coins
	_reset_pool()
	emit_signal("coins_changed", coins)
	emit_signal("pool_changed", pool_remaining())

func _reset_pool() -> void:
	pool.clear()
	for id in BASE_ITEMS:
		for i in copies_per_item:
			pool.append(id)
	pool.shuffle()  # tilfeldig rekkefølge på ballene

func can_spin() -> bool:
	return coins >= spin_cost and pool.size() > 0

func spin() -> String:
	if not can_spin():
		return ""
	coins -= spin_cost
	emit_signal("coins_changed", coins)

	var idx := _rng.randi_range(0, pool.size() - 1)
	var item_id := pool[idx]
	pool.remove_at(idx)
	inventory.append(item_id)

	emit_signal("pool_changed", pool_remaining())
	emit_signal("item_revealed", item_id)
	return item_id

func pool_remaining() -> int:
	return pool.size()
