class_name EnemyBase
extends KinematicBody2D

signal attacked(damage, enemy_pos) # Does damage
signal damaged(damage) # Receives damage

export var enemy_life : int = 10 setget set_enemy_life
export var enemy_damage : int = 1
export var enemy_attack_delay : float = 3
export var enemy_attack_speed : float = 4.5
export var enemy_speed : int = 30
export var enemy_stop_distance : float = 20
export var is_combat := false
export var knockback_time : float = 0.5
export var knockback_force : float = 25

var direction : Vector2
var can_attack := true
var is_stunned := false
var is_attacking := false setget set_attacking_state

onready var target := get_parent().get_node("Player")
onready var tween_node = get_node("Tween")
onready var timer_node = get_node("Enemy_Timer")
onready var hit_particle_node = get_node("Hit_Particle")

var hit_fx_node = load("res://entities/FX/hit.tscn")

func _ready():
	#Engine.time_scale = 1
	# Func to reset the target needed, this is temp
	connect("attacked", target, "_on_receive_damage")


func _process(_delta) -> void:
	if is_combat and !is_stunned and !is_attacking:
		follow_target()
		#Use stunned
		if not tween_node.is_active():
			$Enemy_Animator.current_animation = anim_update()


func follow_target() -> void:
	direction = (target.global_position - global_position).normalized()
	
	if global_position.distance_to(target.global_position) > enemy_stop_distance:
		move_and_slide(direction * enemy_speed)
	elif can_attack:
		attack()


func anim_update() -> String:
	if abs(direction.x) >= abs(direction.y):
		if direction.x < 0:
			return "run_left"
		else:
			return "run_right"
	else:
		if direction.y < 0:
			return "run_back"
		else:
			return "run_front"


func knockback(knock_target : Vector2):
	# Temporal, as the enem may be not hit by the current target
	var target_knockback = global_position - direction * knockback_force
	is_stunned = true
	$Enemy_Animator.stop()
	$Enemy_Animator.play("hit");
	tween_node.interpolate_property(self, "position", global_position, target_knockback, knockback_time, Tween.TRANS_QUINT,Tween.EASE_OUT)
	tween_node.start()
	
	yield(tween_node, "tween_completed")
	
	is_stunned = false


func attack() -> void:
	pass


func set_enemy_life(value):
	enemy_life = value
	
	# Temporal, must get a valid target
	# Cleanup, separe particles
	knockback(target.global_position)
	
	var hit_effect = hit_fx_node.instance()
	get_parent().add_child(hit_effect)
	hit_effect.set_position(global_position - direction*10 - Vector2(0,5))
	hit_effect.set_rotation(randi() % 360)
	
	hit_particle_node.restart()
	hit_particle_node.emitting = true
	
	emit_signal("damaged", value)
	
func set_attacking_state(value):
	pass
