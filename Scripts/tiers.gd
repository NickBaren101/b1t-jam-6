class_name Tiers
extends RefCounted

const CENTER_X := 160.0
const GROUND_SURFACE_Y := 160.0

const SURFACE_Y: Array[float] = [118.0, 76.0, 34.0]
const UNLOCK_COST: Array[int] = [5, 15, 30]

const PLAYER_HALF_H := 8.0
const WALKER_HALF_H := 6.0
const FLYER_HALF_H := 4.0
const MUZZLE_OFFSET_Y := -2.0

static func stand_center_y(surface_y: float, half_height: float) -> float:
	return surface_y - half_height

static func muzzle_y(surface_y: float) -> float:
	return surface_y - PLAYER_HALF_H + MUZZLE_OFFSET_Y

static func lane_y(tier_index: int) -> float:
	return muzzle_y(SURFACE_Y[tier_index])
