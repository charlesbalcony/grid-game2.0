extends Node
class_name ItemFactory

# ItemFactory - Applies item effects mechanically based on JSON definitions
# This replaces hardcoded item effect logic with data-driven approach

# Preload required classes
const DataLoader = preload("res://scripts/systems/DataLoader.gd")

var data_loader: DataLoader
var active_effects: Dictionary = {}  # Track active temporary effects
var piece_modifiers: Dictionary = {}  # Track permanent modifiers per piece

signal effect_applied(piece_id: String, item_id: String, effect_type: String)
signal effect_expired(piece_id: String, item_id: String, effect_type: String)

func _init():
	data_loader = DataLoader.new()

func apply_item_effect(piece_instance: Node, item_id: String, activation_context: String = "equip"):
	"""Apply an item's mechanical effect to a piece"""
	var item_data = data_loader.get_item_by_id(item_id)
	if not item_data or not item_data.has("mechanics"):
		print("No mechanical effects found for item: ", item_id)
		return false
	
	var mechanics = item_data.mechanics
	var piece_id = piece_instance.piece_id if piece_instance.has_method("get") else ""
	
	print("Applying item effect: ", item_id, " to piece: ", piece_id, " context: ", activation_context)
	
	# Handle different types of mechanical effects
	for effect_type in mechanics.keys():
		var effect_data = mechanics[effect_type]
		
		match effect_type:
			"damage_reduction":
				apply_damage_reduction(piece_instance, item_id, effect_data)
			"conditional_stat_bonus":
				setup_conditional_bonus(piece_instance, item_id, effect_data)
			"level_start_effect":
				if activation_context == "level_start":
					apply_level_start_effect(piece_instance, item_id, effect_data)
			"active_ability":
				setup_active_ability(piece_instance, item_id, effect_data)
			"level_start_aura":
				if activation_context == "level_start":
					apply_aura_effect(piece_instance, item_id, effect_data)
			"battle_end_bonus":
				setup_battle_end_bonus(piece_instance, item_id, effect_data)
			"battle_start_effect":
				if activation_context == "battle_start":
					apply_battle_start_effect(piece_instance, item_id, effect_data)
			"damage_shield":
				apply_damage_shield(piece_instance, item_id, effect_data)
			"special_effect":
				apply_special_effect(piece_instance, item_id, effect_data)
			_:
				print("Unknown effect type: ", effect_type)
	
	effect_applied.emit(piece_id, item_id, "applied")
	return true

func apply_damage_reduction(piece_instance: Node, item_id: String, effect_data: Dictionary):
	"""Apply permanent damage reduction"""
	var piece_id = piece_instance.piece_id
	
	if not piece_modifiers.has(piece_id):
		piece_modifiers[piece_id] = {"damage_reduction": {}}
	
	if not piece_modifiers[piece_id].has("damage_reduction"):
		piece_modifiers[piece_id]["damage_reduction"] = {}
	
	# Store the damage reduction values
	for damage_type in effect_data.keys():
		var reduction_amount = effect_data[damage_type]
		if not piece_modifiers[piece_id]["damage_reduction"].has(damage_type):
			piece_modifiers[piece_id]["damage_reduction"][damage_type] = 0
		
		piece_modifiers[piece_id]["damage_reduction"][damage_type] += reduction_amount
	
	print("Applied damage reduction to ", piece_id, ": ", effect_data)

func setup_conditional_bonus(piece_instance: Node, item_id: String, effect_data: Dictionary):
	"""Setup a conditional stat bonus that triggers based on conditions"""
	var piece_id = piece_instance.piece_id
	
	if not active_effects.has(piece_id):
		active_effects[piece_id] = {}
	
	active_effects[piece_id][item_id] = {
		"type": "conditional_bonus",
		"trigger": effect_data.get("trigger", ""),
		"trigger_value": effect_data.get("trigger_value", 0),
		"stat_bonus": effect_data.get("stat_bonus", {}),
		"duration": effect_data.get("duration", "permanent"),
		"active": false
	}
	
	print("Setup conditional bonus for ", piece_id, ": ", effect_data)

func apply_level_start_effect(piece_instance: Node, item_id: String, effect_data: Dictionary):
	"""Apply effects that trigger at level start"""
	var piece_id = piece_instance.piece_id
	
	# Apply health cost if specified
	if effect_data.has("health_cost"):
		var health_cost = effect_data.health_cost
		piece_instance.current_health = max(1, piece_instance.current_health - health_cost)
		print("Applied health cost of ", health_cost, " to ", piece_id)
	
	# Apply stat bonuses
	if effect_data.has("stat_bonus"):
		apply_temporary_stat_bonus(piece_instance, item_id, effect_data.stat_bonus, effect_data.get("duration", "level"))

func apply_temporary_stat_bonus(piece_instance: Node, item_id: String, stat_bonus: Dictionary, duration: String):
	"""Apply temporary stat bonuses"""
	var piece_id = piece_instance.piece_id
	
	for stat in stat_bonus.keys():
		var bonus_value = stat_bonus[stat]
		
		match stat:
			"attack_power":
				piece_instance.attack_power += bonus_value
			"defense":
				piece_instance.defense += bonus_value
			"max_health":
				piece_instance.max_health += bonus_value
			_:
				print("Unknown stat type: ", stat)
	
	# Track the bonus for removal later
	if not active_effects.has(piece_id):
		active_effects[piece_id] = {}
	
	active_effects[piece_id][item_id + "_stat_bonus"] = {
		"type": "stat_bonus",
		"stat_bonus": stat_bonus,
		"duration": duration
	}
	
	print("Applied temporary stat bonus to ", piece_id, ": ", stat_bonus, " duration: ", duration)

func setup_active_ability(piece_instance: Node, item_id: String, effect_data: Dictionary):
	"""Setup an active ability that can be triggered"""
	var piece_id = piece_instance.piece_id
	
	if not active_effects.has(piece_id):
		active_effects[piece_id] = {}
	
	active_effects[piece_id][item_id] = {
		"type": "active_ability",
		"target_type": effect_data.get("target_type", "single_ally"),
		"effects": effect_data.get("effects", []),
		"stat_bonus": effect_data.get("stat_bonus", {}),
		"duration_turns": effect_data.get("duration_turns", 0),
		"cooldown": effect_data.get("cooldown", 0),
		"current_cooldown": 0
	}
	
	print("Setup active ability for ", piece_id, ": ", item_id)

func apply_aura_effect(piece_instance: Node, item_id: String, effect_data: Dictionary):
	"""Apply aura effects to nearby allies"""
	# This would need access to the board state to find nearby allies
	# For now, just track that the aura is active
	var piece_id = piece_instance.piece_id
	
	if not active_effects.has(piece_id):
		active_effects[piece_id] = {}
	
	active_effects[piece_id][item_id] = {
		"type": "aura",
		"target_type": effect_data.get("target_type", "adjacent_allies"),
		"stat_bonus": effect_data.get("stat_bonus", {}),
		"duration": effect_data.get("duration", "level")
	}
	
	print("Applied aura effect for ", piece_id, ": ", effect_data)

func setup_battle_end_bonus(piece_instance: Node, item_id: String, effect_data: Dictionary):
	"""Setup bonus that applies at battle end"""
	var piece_id = piece_instance.piece_id
	
	if not active_effects.has(piece_id):
		active_effects[piece_id] = {}
	
	active_effects[piece_id][item_id] = {
		"type": "battle_end_bonus",
		"condition": effect_data.get("condition", ""),
		"glyph_multiplier": effect_data.get("glyph_multiplier", 1.0)
	}
	
	print("Setup battle end bonus for ", piece_id, ": ", effect_data)

func apply_battle_start_effect(piece_instance: Node, item_id: String, effect_data: Dictionary):
	"""Apply effects at battle start"""
	if effect_data.has("heal_amount"):
		var heal_amount = effect_data.heal_amount
		piece_instance.current_health = min(piece_instance.max_health, piece_instance.current_health + heal_amount)
		print("Battle start heal: ", heal_amount, " HP to ", piece_instance.piece_id)

func apply_damage_shield(piece_instance: Node, item_id: String, effect_data: Dictionary):
	"""Apply a damage shield"""
	var piece_id = piece_instance.piece_id
	
	if not active_effects.has(piece_id):
		active_effects[piece_id] = {}
	
	active_effects[piece_id][item_id] = {
		"type": "damage_shield",
		"shield_amount": effect_data.get("shield_amount", 0),
		"prevents_glyph_loss": effect_data.get("prevents_glyph_loss", false),
		"consumed_on_use": effect_data.get("consumed_on_use", false),
		"remaining_shield": effect_data.get("shield_amount", 0)
	}
	
	print("Applied damage shield to ", piece_id, ": ", effect_data.shield_amount, " damage")

func apply_special_effect(piece_instance: Node, item_id: String, effect_data: Dictionary):
	"""Apply special unique effects"""
	var effect_type = effect_data.get("type", "")
	var piece_id = piece_instance.piece_id
	
	match effect_type:
		"preserve_glyphs_on_defeat":
			if not active_effects.has(piece_id):
				active_effects[piece_id] = {}
			active_effects[piece_id][item_id] = {
				"type": "special_effect",
				"effect_type": "preserve_glyphs_on_defeat"
			}
			print("Applied glyph preservation effect to ", piece_id)
		_:
			print("Unknown special effect type: ", effect_type)

func get_damage_reduction(piece_id: String, damage_type: String) -> int:
	"""Get total damage reduction for a piece and damage type"""
	if not piece_modifiers.has(piece_id):
		return 0
	
	var reductions = piece_modifiers[piece_id].get("damage_reduction", {})
	return reductions.get(damage_type, 0)

func process_damage(piece_id: String, damage_amount: int, damage_type: String) -> int:
	"""Process incoming damage through all active effects"""
	var final_damage = damage_amount
	
	# Apply damage reduction
	var reduction = get_damage_reduction(piece_id, damage_type)
	final_damage = max(0, final_damage - reduction)
	
	# Check for damage shields
	if active_effects.has(piece_id):
		for item_id in active_effects[piece_id]:
			var effect = active_effects[piece_id][item_id]
			if effect.type == "damage_shield" and effect.remaining_shield > 0:
				var shield_absorbed = min(final_damage, effect.remaining_shield)
				final_damage -= shield_absorbed
				effect.remaining_shield -= shield_absorbed
				
				print("Damage shield absorbed ", shield_absorbed, " damage for ", piece_id)
				
				if effect.consumed_on_use and shield_absorbed > 0:
					# Mark for removal
					effect.remaining_shield = 0
	
	return final_damage

func check_conditional_triggers(piece_instance: Node):
	"""Check and trigger conditional effects"""
	var piece_id = piece_instance.piece_id
	
	if not active_effects.has(piece_id):
		return
	
	for item_id in active_effects[piece_id]:
		var effect = active_effects[piece_id][item_id]
		if effect.type == "conditional_bonus" and not effect.active:
			var should_trigger = false
			
			match effect.trigger:
				"health_below_percent":
					var health_percent = (float(piece_instance.current_health) / piece_instance.max_health) * 100
					should_trigger = health_percent < effect.trigger_value
			
			if should_trigger:
				apply_temporary_stat_bonus(piece_instance, item_id, effect.stat_bonus, effect.duration)
				effect.active = true
				print("Triggered conditional bonus for ", piece_id, ": ", item_id)

func clear_level_effects(piece_id: String):
	"""Clear all level-duration effects"""
	if not active_effects.has(piece_id):
		return
	
	var to_remove = []
	for item_id in active_effects[piece_id]:
		var effect = active_effects[piece_id][item_id]
		if effect.get("duration", "") == "level":
			to_remove.append(item_id)
	
	for item_id in to_remove:
		active_effects[piece_id].erase(item_id)
		effect_expired.emit(piece_id, item_id, "level_end")

func clear_run_effects(piece_id: String):
	"""Clear all run-duration effects"""
	if not active_effects.has(piece_id):
		return
	
	var to_remove = []
	for item_id in active_effects[piece_id]:
		var effect = active_effects[piece_id][item_id]
		var duration = effect.get("duration", "")
		if duration == "run" or duration == "level":
			to_remove.append(item_id)
	
	for item_id in to_remove:
		active_effects[piece_id].erase(item_id)
		effect_expired.emit(piece_id, item_id, "run_end")

func get_active_effects(piece_id: String) -> Dictionary:
	"""Get all active effects for a piece"""
	return active_effects.get(piece_id, {})