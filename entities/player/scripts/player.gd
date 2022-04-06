class_name Player
extends KinematicBody2D

signal attacked(target) # Does damage
signal damaged(previous_life, new_life) # Receives damage
signal initialize(max_life, life) # at player spawn

export var player_max_life : int = 10
export var player_life : int = player_max_life setget set_player_life
export var player_damage : int = 1
export var player_speed : int = 60
export var player_attack_delay : float = 0.2
export var player_dash_time : float = 0.16
export var player_dash_force : float = 12
export var player_stun_time : float = 0.3
export var player_stun_force : float = 16

# Animation related
export var disable_input = false
export var walk = false
export var idle = false
export var left = false

var direction : Vector2
var anim_dir := "right"

const knockback_force = 1

var can_attack := true

# Stun > Knockback > Dash
var states = {
	"is_stunned" : false,
	"is_knockback" : false,
	"is_dashing" : false,
}

onready var tween_node = get_node("Tween")
onready var player_animator = get_node("Player_Animator")


func _ready():
	connect("initialize", get_tree().current_scene.get_node("HUDLayer"), "_on_initialize")
	connect("damaged", get_tree().current_scene.get_node("HUDLayer"), "_on_hit")
	emit_signal("initialize", player_max_life, player_life)

func _process(_delta) -> void:
	if disable_input == false:
		if not true in states.values():
			# Player Input Stuff
			controls_loop()
			movement_loop()
		animation_play(false)


func controls_loop() -> void:
	var left = Input.is_action_pressed("ui_left")
	var right = Input.is_action_pressed("ui_right")
	var up = Input.is_action_pressed("ui_up")
	var down = Input.is_action_pressed("ui_down")
	
	direction.x = -int(left) + int(right)
	direction.y = -int(up) + int(down)
	
	# Attack Behaviour
	if Input.is_action_just_pressed("ui_attack") and can_attack:
		animation_play(true)
		can_attack = false
		$Weapon/Weapon_Timer.start(player_attack_delay)
		force_move(0)


func movement_loop() -> void:
	move_and_slide(direction.normalized() * player_speed, Vector2(0,0))


func animation_play(is_attack : bool) -> void:
	
	if states["is_stunned"]: return
	
	if direction != Vector2.ZERO and !states["is_knockback"]:
		if abs(direction.x) >= abs(direction.y):
			if direction.x < 0:
				anim_dir = "left"
			else:
				anim_dir = "right"
		else:
			if direction.y < 0:
				anim_dir = "back"
			else:
				anim_dir = "front"
			
	# Attack animation
	if is_attack:
		$Weapon/Weapon_Animator.stop(true)
		$Weapon/Nunchaku.frame = 0
		$Weapon/Weapon_Animator.play("slash_" + anim_dir + ("_reverse" if randi()%2 == 1 else ""))
		return
		
	var action = "idle_" if direction == Vector2.ZERO else "run_"
	player_animator.current_animation = action + anim_dir


# Dash = 0, Knock = 1, Stun = 2
func force_move(type : int, target := Vector2.ZERO):
	match type:
		0:
			if states["is_knockback"] or states["is_stunned"]: return
			states["is_dashing"] = true
			$Player_Timer.start(player_dash_time)
			if direction == Vector2(0,0):
				match anim_dir:
					"left":
						direction = Vector2(-1,0)
					"right":
						direction = Vector2(1,0)
					"front":
						direction = Vector2(0,1)
					"back":
						direction = Vector2(0,-1)
			var target_dash = global_position + direction * player_dash_force
			tween_node.interpolate_property(self, "position", global_position, target_dash, player_dash_time, Tween.TRANS_QUINT,Tween.EASE_OUT)
			tween_node.start()
		1:
			pass
		2:
			states["is_stunned"] = true
			$Player_Timer.start(player_stun_time)
			var target_dir = (global_position - target).normalized()
			var target_stun = global_position + target_dir * player_stun_force
			tween_node.interpolate_property(self, "position", global_position, target_stun, player_stun_time, Tween.TRANS_QUINT,Tween.EASE_OUT)
			tween_node.start()
			player_animator.play("hit")


func set_player_life(value):
	player_life = value
	pass


func _on_Weapon_Timer_timeout():
	can_attack = true


func _on_Player_Timer_timeout():
	for i in states:
		if states[i] == true:
			states[i] = false


func _on_AttackArea_area_entered(area):
	if area.is_in_group("enemies"):
		emit_signal("attacked", area.get_parent())
		if area.get_parent().enemy_life <= 0:
			return
		get_node("Camera2D").add_trauma(.4)
		if area.get_parent().enemy_life <= 1:
			get_node("Camera2D").add_freq()
			
		# Use signals instead, like in player
		area.get_parent().enemy_life -= player_damage
		
		# This is knockbak
		#force_move(1)

func _on_receive_damage(damage, enemy_pos):
	if states["is_stunned"]: return
	print(player_life)
	print(damage)
	emit_signal("damaged", player_life, player_life - damage)
	self.player_life -= damage
	force_move(2, enemy_pos)
	get_node("Camera2D").add_trauma(.8)
