extends CharacterBody2D

enum {
	IDLE,
	CHASE,
	ATTACK,
	TAKE_HIT,
	DEATH,
}

@onready var animPlayer = $AnimationPlayer
@onready var sprite = $AnimatedSprite2D
@onready var healthBar = $MobHealth
@export var change_position = [27,-27]
var damage = 1
var speed = 200
var direction
var player
var health = 6
var state: int = 0:
	set(value):
		state = value
		match state:
			IDLE:
				idle_state()
			CHASE:
				chase_state()
			ATTACK:
				attack_state()
			TAKE_HIT:
				take_hit_state()
			DEATH:
				death_state()

func _ready() -> void:
	healthBar.start_parameters(health)
	
	state = IDLE
	
func _process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	 
	player = Global.player_pos
	
	move_and_slide()


func _on_attack_range_body_entered(_body: Node2D) -> void:
	state = ATTACK
	
func idle_state():
	animPlayer.play("Idle")
	velocity.x = 0
	await get_tree().create_timer(1).timeout
	$AttackDirection/AttackRange/AttackCollision.disabled = false

func attack_state():
	state = DEATH

func chase_state():
	direction = (Global.player_pos - self.position).normalized()
	velocity.x = direction.x * speed
	if velocity.x != 0:
		animPlayer.play("Walk")
	else:
		animPlayer.play("Idle")
	if direction.x < 0:
		sprite.flip_h = true
		sprite.position.x = change_position[1]
		$AttackDirection.rotation_degrees = 180
	elif direction.x > 0:
		sprite.flip_h = false
		sprite.position.x = change_position[0]
		$AttackDirection.rotation_degrees = 0

func take_hit_state():
	if health > 0 and state != DEATH:
		animPlayer.play("Take_Hit")
		await animPlayer.animation_finished
		state = IDLE
	else:
		state = DEATH

func death_state():
	velocity.x = 0
	animPlayer.play("Death")
	await animPlayer.animation_finished
	queue_free()


func _on_hit_box_area_entered(_area: Area2D) -> void:
	Signals.emit_signal("enemy_attack",damage)
	


func _on_hurt_box_area_entered(_area: Area2D) -> void:
	if state != DEATH:
		health -= Global.player_damage
		healthBar.update_heath(health,Global.player_damage)
		state = TAKE_HIT


func _on_area_2d_body_entered(_body: Node2D) -> void:
	if state != DEATH:
		state = CHASE


func _on_area_2d_body_exited(_body: Node2D) -> void:
	if state != DEATH:
		state = IDLE
