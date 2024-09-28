extends CharacterBody2D

enum {
	IDLE,
	CHASE,
	ATTACK,
	TAKE_HIT,
	DEATH
}

@onready var animPlayer = $AnimationPlayer
@onready var sprite = $AnimatedSprite2D
@onready var healthBar = $MobHealth
var damage = 2
var speed = 100
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
	state = IDLE
	healthBar.start_parameters(health)
	
func _process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	if state == CHASE:
		chase_state()
	 
	player = Global.player_pos
	
	move_and_slide()


func _on_attack_range_body_entered(body: Node2D) -> void:
	state = ATTACK
	
func idle_state():
	animPlayer.play("Idle")
	velocity.x = 0
	await get_tree().create_timer(1).timeout
	$AttackDirection/AttackRange/AttackCollision.disabled = false
	$AgreZone/CollisionShape2D.disabled = false

func attack_state():
	velocity.x = 0
	animPlayer.play("Attack")
	await animPlayer.animation_finished
	$AttackDirection/AttackRange/AttackCollision.disabled = true
	$AgreZone/CollisionShape2D.disabled = true
	state = IDLE

func chase_state():
	direction = (Global.player_pos - self.position).normalized()
	velocity.x = direction.x * speed
	if velocity.x != 0:
		animPlayer.play("Run")
	else:
		animPlayer.play("Idle")
	if direction.x < 0:
		sprite.flip_h = false
		$AttackDirection.rotation_degrees = 360
	elif direction.x > 0:
		sprite.flip_h = true
		$AttackDirection.rotation_degrees = 0

func take_hit_state():
	if health > 0 and state != DEATH:
		animPlayer.play("Take_Hit")
		await animPlayer.animation_finished
		state = IDLE
	else:
		state = DEATH

func death_state():
	animPlayer.play("Death")
	await animPlayer.animation_finished
	queue_free()


func _on_hit_box_area_entered(area: Area2D) -> void:
	Signals.emit_signal("enemy_attack",damage)
	


func _on_hurt_box_area_entered(area: Area2D) -> void:
	if state != DEATH:
		health -= Global.player_damage
		healthBar.update_heath(health,Global.player_damage)
		state = TAKE_HIT

func _on_agre_zone_body_entered(body: Node2D) -> void:
	if state != DEATH:
		state = CHASE


func _on_agre_zone_body_exited(body: Node2D) -> void:
	if state != DEATH:
		state = IDLE
