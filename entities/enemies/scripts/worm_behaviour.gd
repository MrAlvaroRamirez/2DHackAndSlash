extends "res://entities/enemies/scripts/enemy_base.gd"

var fangs_fx_node = load("res://entities/FX/fangs.tscn")
var has_attacked := false
var last_collider_pos : Vector2

onready var enemy_collider = $Char_Collision

func _process(_delta):
	if is_attacking:
		check_attack_collision()
		enemy_collider.set_global_position(last_collider_pos)


func attack() -> void:
	# Need to replace target (or no??)
	can_attack = false
	self.is_attacking = true
	has_attacked = false
	
	#Make collider stay in place while attacking
	last_collider_pos = enemy_collider.global_position
	
	var first_pos = global_position
	var final_pos = target.global_position
	
	tween_node.interpolate_property(self, "position", first_pos, final_pos, 2/enemy_attack_speed, Tween.TRANS_BACK,Tween.EASE_OUT)
	tween_node.start()
	
	yield(tween_node, "tween_completed")
	
	# If attack is not blocked
	if is_attacking:
		tween_node.interpolate_property(self, "position", final_pos, first_pos, 2/enemy_attack_speed, Tween.TRANS_QUAD,Tween.EASE_OUT)
		tween_node.start()
		
		yield(tween_node, "tween_completed")
	
	self.is_attacking = false
	timer_node.start(enemy_attack_delay)
	
	yield(timer_node, "timeout")
	
	can_attack = true


func check_attack_collision():
	var collisions = $Enemy_hitbox.get_overlapping_areas()
	for i in collisions:
		if i.is_in_group("player") and !has_attacked:
			has_attacked = true
			var fangs_effect = fangs_fx_node.instance()
			get_parent().add_child(fangs_effect)
			fangs_effect.set_position(global_position + direction*6 - Vector2(0,6))
			emit_signal("attacked", enemy_damage, last_collider_pos)


func set_enemy_life(value):
	# Block an attack
	self.is_attacking = false
	tween_node.remove_all()
	
	# Reset the collider position
	enemy_collider.set_position(Vector2(0,-7))
	
	.set_enemy_life(value)
	
	if enemy_life <= 0:
		queue_free()

func set_attacking_state(value):
	is_attacking = value
	$Enemy_hitbox.monitoring = is_attacking
