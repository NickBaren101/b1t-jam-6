extends Node

signal favour_changed(value: int)
signal tier_unlocked(index: int)

const SPEED_PER_FAVOUR := 0.01
const SPEED_CAP := 0.5
const FIRE_RATE_PER_FAVOUR := 0.015
const FIRE_RATE_CAP := 0.75

var favour := 0
var unlocked_tiers := 0

func reset() -> void:
	favour = 0
	unlocked_tiers = 0
	favour_changed.emit(favour)

func add(amount: int) -> void:
	favour += amount
	favour_changed.emit(favour)
	while unlocked_tiers < Tiers.UNLOCK_COST.size() and favour >= Tiers.UNLOCK_COST[unlocked_tiers]:
		unlocked_tiers += 1
		tier_unlocked.emit(unlocked_tiers - 1)

func speed_mult() -> float:
	return 1.0 + minf(favour * SPEED_PER_FAVOUR, SPEED_CAP)

func fire_rate_mult() -> float:
	return 1.0 + minf(favour * FIRE_RATE_PER_FAVOUR, FIRE_RATE_CAP)
