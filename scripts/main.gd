extends Node2D
## Nightfall Chronicles — playable original Godot 4 mobile action roguelite prototype.
## All runtime drawing is native Godot CanvasItem; no HTML, JavaScript or WebView.

const SW := 1280.0
const SH := 720.0
const ROOM := Rect2(56.0, 94.0, 1168.0, 523.0)
const SAVE_FILE := "user://nightfall_save.json"
const GUN_NAMES := ["PISTOLA NEXO", "ESPINGARDA SOLAR", "RAIO ESPECTRAL", "LANÇA ESTELAR", "CANHÃO DO VAZIO"]
const GUN_COLORS := [Color("69e9ff"), Color("ffb564"), Color("e092ff"), Color("ff6f96"), Color("a7ff9e")]
const UPGRADE_NAMES := ["SOBRECARGA", "PLASMA VITAL", "PROPULSÃO", "CAMPO DE FORÇA", "DISPARO DUPLO", "PRECISÃO", "NÚCLEO DE ENERGIA", "EFICIÊNCIA", "ARMADURA DE NEXO", "RESSONÂNCIA", "AMPLIFICADOR", "ESCUDO VITAL"]
const UPGRADE_DESCS := ["+20% de dano", "+25 de vida máxima", "+16% de velocidade", "+20 de escudo", "+1 projétil", "+12% de cadência", "+15 de energia", "Esquiva mais rápida", "+15 de escudo", "+8% de dano e tiro", "+10% de movimento", "+15 de vida"]

var rng := RandomNumberGenerator.new()
var textures: Dictionary = {}
var sound_players: Dictionary = {}
var selected_weapon := 0
var stage := 1
var state := "menu"
var player_pos := Vector2(640, 375)
var player_vel := Vector2.ZERO
var player_hp := 100.0
var max_hp := 100.0
var player_shield := 55.0
var max_shield := 55.0
var energy := 70.0
var max_energy := 70.0
var gems := 0
var best_stage := 1
var lifetime_gems := 0
var kills := 0
var damage_multiplier := 1.0
var speed_multiplier := 1.0
var fire_multiplier := 1.0
var multishot := 0
var dash_cooldown := 0.0
var dash_cooldown_factor := 1.0
var dash_time := 0.0
var dash_vector := Vector2.RIGHT
var gun_cooldown := 0.0
var hurt_flash := 0.0
var i_frames := 0.0
var shield_recharge_delay := 0.0
var time_elapsed := 0.0
var camera_shake := 0.0
var aim_vec := Vector2.RIGHT
var bullets: Array = []
var enemies: Array = []
var particles: Array = []
var pickups: Array = []
var obstacles: Array = []
var choice_ids: Array = []
var left_touch := -1
var right_touch := -1
var left_anchor := Vector2(145, 566)
var left_stick := Vector2.ZERO
var right_anchor := Vector2(1120, 548)
var right_stick := Vector2.ZERO
var shoot_hold := false
var mouse_down := false
var is_boss_room := false
var room_label := ""
var notification := ""
var notice_timer := 0.0
var is_mute := false
var music_player: AudioStreamPlayer
var active_music := -1
var current_room_texture: Texture2D
const TOTAL_STAGES := 24
const BIOMES := ["CATACUMBAS CARMESINS", "GELEIRAS ESQUECIDAS", "FENDA DO VAZIO", "FLORESTA ETÉREA", "DESERTO ABISSAL", "ESTAÇÃO ORBITAL"]

func _ready() -> void:
	rng.randomize()
	_load_texture("menu", "menu_hero_ia.jpg")
	_load_texture("avatar", "avatar_ia.png")
	_load_texture("hero", "hero.png")
	_load_texture("grunt", "enemy_grunt.png")
	_load_texture("cultist", "enemy_cultist.png")
	_load_texture("elite", "enemy_elite.png")
	_load_texture("frost", "boss_frost.png")
	_load_texture("void", "boss_void.png")
	for j in range(3):
		for variant in range(8):
			_load_texture("tile%d_%d" % [j,variant], "tile_%d_%d.png" % [j,variant])
		_load_texture("weapon%d" % j, "weapon_%d.png" % j)
	for j in range(6):
		_load_texture("biome%d" % j, "biome_%d.jpg" % (j + 1))
	for j in range(6):
		_load_texture("boss%d" % j, "boss_%d.png" % j)
	for j in range(3, 5):
		_load_texture("weapon%d" % j, "weapon_%d.png" % j)
	music_player = AudioStreamPlayer.new()
	music_player.volume_db = -15.0
	add_child(music_player)
	for key in ["shot", "dash", "hit", "heal", "boss"]:
		var node := AudioStreamPlayer.new()
		var path := "res://assets/sfx/%s.wav" % key
		if ResourceLoader.exists(path):
			node.stream = load(path)
			node.volume_db = -7.0
			add_child(node)
			sound_players[key] = node
	load_progress()
	queue_redraw()

func _load_texture(key: String, filename: String) -> void:
	var path := "res://assets/art/" + filename
	if ResourceLoader.exists(path):
		textures[key] = load(path)

func _sfx(name: String) -> void:
	if not is_mute and sound_players.has(name):
		var p: AudioStreamPlayer = sound_players[name]
		p.play()

func load_progress() -> void:
	if not FileAccess.file_exists(SAVE_FILE):
		return
	var file := FileAccess.open(SAVE_FILE, FileAccess.READ)
	if file == null:
		return
	var data = JSON.parse_string(file.get_as_text())
	if typeof(data) == TYPE_DICTIONARY:
		best_stage = int(data.get("best_stage", 1))
		lifetime_gems = int(data.get("total_gems", 0))
		is_mute = bool(data.get("mute", false))

func save_progress() -> void:
	var file := FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"best_stage":best_stage,"total_gems":lifetime_gems,"mute":is_mute}))

func new_game() -> void:
	stage = 1
	selected_weapon = 0
	max_hp = 100.0
	player_hp = 100.0
	max_shield = 55.0
	player_shield = 55.0
	max_energy = 70.0
	energy = 70.0
	damage_multiplier = 1.0
	fire_multiplier = 1.0
	speed_multiplier = 1.0
	multishot = 0
	dash_cooldown_factor = 1.0
	dash_cooldown = 0.0
	dash_time = 0.0
	i_frames = 0.0
	gun_cooldown = 0.0
	time_elapsed = 0.0
	left_touch = -1
	right_touch = -1
	left_stick = Vector2.ZERO
	right_stick = Vector2.ZERO
	shoot_hold = false
	mouse_down = false
	aim_vec = Vector2.RIGHT
	gems = 0
	kills = 0
	player_pos = ROOM.get_center()
	spawn_stage()
	state = "playing"
	_sfx("heal")

func spawn_stage() -> void:
	player_pos = ROOM.get_center()
	bullets.clear()
	enemies.clear()
	pickups.clear()
	particles.clear()
	obstacles.clear()
	is_boss_room = stage % 4 == 0
	room_label = BIOMES[clampi(int((stage - 1) / 4), 0, 5)]
	var room_path := "res://assets/rooms/room_%02d_%d.jpg" % [stage, rng.randi_range(0, 1)]
	current_room_texture = load(room_path) if ResourceLoader.exists(room_path) else null
	_play_music_for_stage()
	for i in range(3 + int(stage / 2)):
		var pos := Vector2(rng.randf_range(145, 1120), rng.randf_range(170, 528))
		if pos.distance_to(player_pos) < 145:
			pos.x += 235 if pos.x < 640 else -235
		var size := Vector2(rng.randi_range(42, 72), rng.randi_range(42, 66))
		obstacles.append(Rect2(pos - size / 2.0, size))
	var mobs := 4 + stage * 2
	if is_boss_room:
		mobs = 4 + stage
	for i in range(mobs):
		var species := rng.randi_range(0, 2)
		if stage <= 2 and species == 2:
			species = 0
		var pos := _random_enemy_position()
		spawn_enemy(pos, species)
	if is_boss_room:
		spawn_enemy(Vector2(640, 192), 3)
		_sfx("boss")
	notification = "CÂMARA %02d — %s" % [stage, room_label]
	notice_timer = 2.3

func _play_music_for_stage() -> void:
	if music_player == null:
		return
	var idx := clampi(int((stage - 1) / 2), 0, 11)
	if idx == active_music:
		return
	active_music = idx
	music_player.stop()
	music_player.stream = null
	var path := "res://assets/music/track_%02d.wav" % idx
	if ResourceLoader.exists(path):
		music_player.stream = load(path)
		if not is_mute:
			music_player.play()

func _random_enemy_position() -> Vector2:
	var v := Vector2.ZERO
	for attempt in range(36):
		v = Vector2(rng.randf_range(110, 1175), rng.randf_range(157, 546))
		if v.distance_to(player_pos) > 205 and not _collides(v, 25):
			return v
	return Vector2(150, 200)

func spawn_enemy(pos: Vector2, species: int) -> void:
	var hp := (25.0 + stage * 6.0) * (6.0 if species == 3 else 1.6 if species == 2 else 1.0)
	enemies.append({"pos":pos,"type":species,"hp":hp,"max_hp":hp,"shoot":rng.randf_range(0.5,2.0),"flash":0.0,"walk":rng.randf_range(0, 6.28),"speed":rng.randf_range(67, 85),"radius":50.0 if species == 3 else 23.0})

func _collides(pos: Vector2, radius: float) -> bool:
	if pos.x < ROOM.position.x + radius + 12 or pos.x > ROOM.end.x - radius - 12:
		return true
	if pos.y < ROOM.position.y + radius + 12 or pos.y > ROOM.end.y - radius - 12:
		return true
	for wall in obstacles:
		var closest: Vector2 = pos.clamp(wall.position, wall.end)
		if pos.distance_squared_to(closest) < radius * radius:
			return true
	return false

func _try_move(pos: Vector2, movement: Vector2, radius: float) -> Vector2:
	var p := pos
	if not _collides(p + Vector2(movement.x, 0), radius):
		p.x += movement.x
	if not _collides(p + Vector2(0, movement.y), radius):
		p.y += movement.y
	return p

func _physics_process(delta: float) -> void:
	if state != "playing":
		return
	var dt := minf(delta, 0.05)
	time_elapsed += dt
	gun_cooldown = maxf(0.0, gun_cooldown - dt)
	dash_cooldown = maxf(0.0, dash_cooldown - dt)
	dash_time = maxf(0.0, dash_time - dt)
	i_frames = maxf(0.0, i_frames - dt)
	hurt_flash = maxf(0.0, hurt_flash - dt)
	shield_recharge_delay = maxf(0.0, shield_recharge_delay - dt)
	if shield_recharge_delay == 0:
		player_shield = minf(max_shield, player_shield + 7.5 * dt)
	energy = minf(max_energy, energy + 4.0 * dt)
	var move_axis := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): move_axis.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): move_axis.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): move_axis.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): move_axis.y += 1.0
	move_axis += left_stick
	if move_axis.length() > 1.0: move_axis = move_axis.normalized()
	var movement := move_axis * 235.0 * speed_multiplier * dt
	if dash_time > 0:
		movement = dash_vector * 780.0 * dt
	player_pos = _try_move(player_pos, movement, 19)
	player_vel = movement / maxf(dt,0.0001)
	if right_stick.length() > .2:
		aim_vec = right_stick.normalized()
	elif shoot_hold:
		# Pressing the mobile fire stick without dragging targets the nearest foe.
		var target_dir := _nearest_enemy_direction()
		if target_dir.length_squared() > 0.01:
			aim_vec = target_dir
	elif mouse_down:
		var dir: Vector2 = get_global_mouse_position() - player_pos
		if dir.length() > 0.01:
			aim_vec = dir.normalized()
	elif Input.is_key_pressed(KEY_UP) and Input.is_key_pressed(KEY_SPACE):
		aim_vec = Vector2.UP
	if Input.is_key_pressed(KEY_SPACE) or mouse_down or shoot_hold:
		fire_weapon()
	if Input.is_key_pressed(KEY_SPACE) and not mouse_down and right_touch == -1:
		var target_dir := _nearest_enemy_direction()
		if target_dir.length_squared() > 0.01:
			aim_vec = target_dir
	if Input.is_key_pressed(KEY_SHIFT) and dash_cooldown == 0:
		perform_dash()
	_update_bullets(dt)
	_update_enemies(dt)
	_update_pickups(dt)
	_update_particles(dt)
	if enemies.is_empty() and state == "playing":
		finish_stage()

func _process(delta: float) -> void:
	notice_timer = maxf(0.0, notice_timer - delta)
	camera_shake = maxf(0.0, camera_shake - 25.0 * delta)
	queue_redraw()

func _nearest_enemy_direction() -> Vector2:
	var nearest_distance := 850.0 * 850.0
	var nearest := Vector2.ZERO
	for enemy in enemies:
		var enemy_position: Vector2 = enemy["pos"]
		var d := player_pos.distance_squared_to(enemy_position)
		if d < nearest_distance:
			nearest_distance = d
			nearest = enemy_position - player_pos
	return nearest.normalized() if nearest.length_squared() > 0.01 else Vector2.ZERO

func fire_weapon() -> void:
	if gun_cooldown > 0 or state != "playing":
		return
	var delays := [0.17, 0.58, 0.12, 0.36, 0.9]
	gun_cooldown = delays[selected_weapon] / fire_multiplier
	var count := 1 + multishot + (4 if selected_weapon == 1 else 0) + (2 if selected_weapon == 4 else 0)
	var width := .22 if selected_weapon == 1 else .30 if selected_weapon == 4 else .055 if multishot > 0 else 0.0
	var shot_color: Color = GUN_COLORS[selected_weapon]
	for i in range(count):
		var offset := (float(i) - float(count - 1) / 2.0) * width
		var direction := aim_vec.rotated(offset)
		var damage := (7.0 if selected_weapon == 1 else 8.0 if selected_weapon == 2 else 30.0 if selected_weapon == 3 else 22.0 if selected_weapon == 4 else 13.0) * damage_multiplier
		bullets.append({"pos":player_pos + direction * 29.0,"vel":direction*(1100.0 if selected_weapon == 3 else 900.0 if selected_weapon == 2 else 500.0 if selected_weapon == 4 else 620.0),"enemy":false,"damage":damage,"life":.6 if selected_weapon == 1 else 1.25,"color":shot_color,"rad":5.5 if selected_weapon == 2 else 4.0})
	add_particles(player_pos + aim_vec * 24, shot_color, 3)
	_sfx("shot")

func perform_dash() -> void:
	if energy < 18 or dash_cooldown > 0 or state != "playing":
		return
	dash_vector = player_vel.normalized() if player_vel.length() > 35 else aim_vec
	dash_cooldown = 1.3 * dash_cooldown_factor
	dash_time = .17
	i_frames = .3
	energy -= 18
	add_particles(player_pos, Color("69dfff"), 22)
	_sfx("dash")

func _update_bullets(dt: float) -> void:
	for i in range(bullets.size() - 1, -1, -1):
		var b: Dictionary = bullets[i]
		b["pos"] += b["vel"] * dt
		b["life"] -= dt
		var hit: bool = float(b["life"]) <= 0.0 or _collides(b["pos"], 4.0)
		if not hit:
			if b["enemy"]:
				if b["pos"].distance_to(player_pos) < 20 and i_frames == 0:
					take_damage(b["damage"])
					hit = true
			else:
				for j in range(enemies.size() - 1, -1, -1):
					var e: Dictionary = enemies[j]
					if b["pos"].distance_to(e["pos"]) < e["radius"]:
						e["hp"] -= b["damage"]
						e["flash"] = .11
						add_particles(b["pos"], b["color"], 4)
						if e["hp"] <= 0:
							kill_enemy(j)
						else:
							enemies[j] = e
						hit = true
						break
		if hit:
			bullets.remove_at(i)
		else:
			bullets[i] = b

func _update_enemies(dt: float) -> void:
	for i in range(enemies.size() - 1, -1, -1):
		var e: Dictionary = enemies[i]
		var to_player: Vector2 = player_pos - e["pos"]
		var distance := to_player.length()
		var direction := to_player.normalized() if distance > 0.1 else Vector2.RIGHT
		var species: int = e["type"]
		var preferred := 240.0 if species == 1 else 310.0 if species == 3 else 35.0
		var move_dir := direction if distance > preferred else -direction * 0.45 if species == 1 or species == 3 else Vector2.ZERO
		if species == 2: move_dir = direction.rotated(sin(time_elapsed * 1.8 + i) * .5)
		e["pos"] = _try_move(e["pos"],move_dir * e["speed"] * (0.64 if species == 3 else 1.0) * dt, e["radius"] * .63)
		e["shoot"] -= dt
		e["flash"] = maxf(0.0,e["flash"]-dt)
		if e["shoot"] <= 0 and distance < 920:
			e["shoot"] = (1.15 if species == 1 else 2.2 if species == 3 else 1.8 if species == 2 else 999.0) * rng.randf_range(.8,1.2)
			var volley := 9 if species == 3 else 3 if species == 2 else 1
			if species != 0:
				for n in range(volley):
					var off := (float(n)-float(volley - 1)/2.0) * (.36 if species != 3 else .25)
					var shot_dir := direction.rotated(off + (time_elapsed if species == 3 else 0.0))
					bullets.append({"pos":e["pos"] + shot_dir * 34.0, "vel":shot_dir*(285.0 if species == 3 else 365.0),"enemy":true,"damage": 10.0 if species == 3 else 7.0,"life":3.2,"color":Color("ff6b83") if species != 3 else Color("c47aff"),"rad":6.5 if species == 3 else 4.5})
		if distance <= e["radius"] + 18.0 and i_frames <= 0:
			take_damage(16.0 if species == 3 else 9.0)
		enemies[i] = e

func take_damage(amount: float) -> void:
	if i_frames > 0:
		return
	i_frames = .58
	hurt_flash = .33
	shield_recharge_delay = 3.6
	camera_shake = 9.0
	var absorbed := minf(player_shield, amount)
	player_shield -= absorbed
	player_hp -= (amount - absorbed)
	add_particles(player_pos, Color("ff5268"), 16)
	_sfx("hit")
	if player_hp <= 0:
		player_hp = 0
		state = "dead"
		best_stage = maxi(best_stage,stage)
		save_progress()

func kill_enemy(index: int) -> void:
	var e: Dictionary = enemies[index]
	var amount := 9 if e["type"] == 3 else 3 if e["type"] == 2 else 1
	add_particles(e["pos"], Color("ffc976"), 15 if e["type"] == 3 else 8)
	pickups.append({"pos":e["pos"],"type":0,"value":amount})
	if rng.randf() < .065 or e["type"] == 3:
		pickups.append({"pos":e["pos"]+Vector2(32,2),"type":1,"value":22})
	kills += 1
	enemies.remove_at(index)

func _update_pickups(dt: float) -> void:
	for i in range(pickups.size() - 1,-1,-1):
		var p: Dictionary = pickups[i]
		var diff: Vector2 = player_pos - p["pos"]
		if diff.length() < 120 and diff.length() > 0.1:
			p["pos"] += diff.normalized() * 280 * dt
		if p["pos"].distance_to(player_pos) < 25:
			if p["type"] == 0:
				gems += p["value"]
				lifetime_gems += p["value"]
			else:
				player_hp = minf(max_hp,player_hp + p["value"])
				_sfx("heal")
			pickups.remove_at(i)
		else:
			pickups[i] = p

func add_particles(pos: Vector2, color: Color, count: int) -> void:
	for i in range(count):
		var velocity := Vector2.RIGHT.rotated(rng.randf_range(0,TAU)) * rng.randf_range(40,230)
		particles.append({"pos":pos,"velocity":velocity,"ttl":rng.randf_range(.17,.6),"life":.6,"color":color})

func _update_particles(dt: float) -> void:
	for i in range(particles.size() - 1,-1,-1):
		var p: Dictionary = particles[i]
		p["pos"] += p["velocity"] * dt
		p["velocity"] *= 0.91
		p["ttl"] -= dt
		if p["ttl"] <= 0:
			particles.remove_at(i)
		else:
			particles[i] = p

func finish_stage() -> void:
	for pickup in pickups:
		if pickup["type"] == 0:
			gems += int(pickup["value"])
			lifetime_gems += int(pickup["value"])
	pickups.clear()
	best_stage = maxi(stage,best_stage)
	save_progress()
	if stage >= TOTAL_STAGES:
		state = "win"
		return
	state = "upgrade"
	choice_ids.clear()
	while choice_ids.size() < 3:
		var id := rng.randi_range(0,UPGRADE_NAMES.size()-1)
		if not choice_ids.has(id): choice_ids.append(id)
	player_hp = minf(max_hp,player_hp + 12)

func apply_upgrade(slot: int) -> void:
	if slot < 0 or slot >= choice_ids.size() or state != "upgrade":
		return
	match choice_ids[slot]:
		0: damage_multiplier *= 1.2
		1:
			max_hp += 25.0
			player_hp += 25.0
		2: speed_multiplier *= 1.16
		3:
			max_shield += 20
			player_shield += 20
		4: multishot += 1
		5: fire_multiplier *= 1.12
		6:
			max_energy += 15
			energy += 15
		7:
			dash_cooldown_factor *= 0.8
			dash_cooldown = 0.0
		8:
			max_shield += 15
			player_shield += 15
		9:
			damage_multiplier *= 1.08
			fire_multiplier *= 1.08
		10: speed_multiplier *= 1.1
		11:
			max_hp += 15
			player_hp += 15
	stage += 1
	if stage == 5: selected_weapon = 1
	if stage == 10: selected_weapon = 2
	if stage == 15: selected_weapon = 3
	if stage == 20: selected_weapon = 4
	spawn_stage()
	state = "playing"

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if state == "playing": state = "pause"
			elif state == "pause": state = "playing"
		if state == "playing":
			if event.keycode == KEY_Q: selected_weapon = (selected_weapon+1)%5
			if event.keycode == KEY_E: perform_dash()
		elif state == "upgrade":
			if event.keycode in [KEY_1,KEY_2,KEY_3]: apply_upgrade(int(event.keycode - KEY_1))
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_click_at(event.position)
			if state == "playing" and event.position.y < 620 and event.position.y > 90:
				mouse_down = true
		else:
			mouse_down = false
	if event is InputEventScreenTouch:
		var xy: Vector2 = event.position
		if event.pressed:
			if state != "playing":
				_click_at(xy)
			elif xy.x < 430 and xy.y > 310 and left_touch == -1:
				left_touch = event.index
				left_anchor = xy
				left_stick = Vector2.ZERO
			elif xy.x > 760 and right_touch == -1:
				if Rect2(930,631,77,71).has_point(xy):
					perform_dash()
				elif Rect2(1126,631,117,71).has_point(xy):
					selected_weapon = (selected_weapon+1)%5
				else:
					right_touch = event.index
					right_anchor = xy
					shoot_hold = true
		else:
			if event.index == left_touch:
				left_touch = -1
				left_stick = Vector2.ZERO
			if event.index == right_touch:
				right_touch = -1
				right_stick = Vector2.ZERO
				shoot_hold = false
	if event is InputEventScreenDrag:
		if event.index == left_touch:
			left_stick = (event.position - left_anchor).limit_length(68) / 68.0
		if event.index == right_touch:
			right_stick = (event.position - right_anchor).limit_length(65) / 65.0

func _click_at(point: Vector2) -> void:
	if state == "menu":
		if Rect2(724,428,385,83).has_point(point): new_game()
		if Rect2(724,536,385,60).has_point(point):
			is_mute = not is_mute
			if music_player != null:
				if is_mute: music_player.stop()
				elif music_player.stream != null: music_player.play()
			save_progress()
	elif state == "upgrade":
		for j in range(3):
			if Rect2(166 + j*322,250,293,283).has_point(point):
				apply_upgrade(j)
				break
	elif state == "dead" or state == "win":
		if Rect2(455,485,370,67).has_point(point): new_game()
		if Rect2(478,578,322,45).has_point(point): state = "menu"
	elif state == "pause":
		if Rect2(455,367,370,65).has_point(point): state = "playing"
		if Rect2(455,450,370,65).has_point(point): state = "menu"
	elif state == "playing":
		if Rect2(1194,20,65,60).has_point(point):
			state = "pause"
		elif Rect2(945,626,67,60).has_point(point):
			perform_dash()
		elif Rect2(1117,636,120,75).has_point(point):
			selected_weapon = (selected_weapon+1)%5

func _draw() -> void:
	draw_rect(Rect2(0,0,SW,SH),Color("080d1c"))
	if state == "menu":
		_draw_menu()
		return
	_draw_room()
	_draw_entities()
	_draw_hud()
	if state == "upgrade": _draw_upgrade()
	if state == "dead" or state == "win": _draw_result()
	if state == "pause": _draw_pause()

func _img(key: String, rect: Rect2, modulate: Color = Color.WHITE) -> void:
	if textures.has(key):
		draw_texture_rect(textures[key], rect, false, modulate)

func _txt(text: String, pos: Vector2, size: int, color: Color = Color.WHITE, align: int = HORIZONTAL_ALIGNMENT_LEFT, width: float = -1) -> void:
	draw_string(ThemeDB.fallback_font,pos,text,align,width,size,color)

func _box(rect: Rect2, color: Color = Color("101b33"), border: Color = Color("506783"), thick: float = 2.0) -> void:
	draw_rect(rect,color)
	draw_rect(rect,border,false,thick)

func _panel_title(text: String, y: float, size: int = 40, color: Color = Color("dceeff")) -> void:
	_txt(text,Vector2(0,y),size,color,HORIZONTAL_ALIGNMENT_CENTER,SW)

func _draw_menu() -> void:
	_img("menu",Rect2(-4,-110,663,995),Color(0.98,1,1,.93))
	draw_rect(Rect2(0,0,SW,SH),Color(5.0/255,10.0/255,25.0/255,.34))
	draw_rect(Rect2(620,0,660,720),Color("090e23"))
	for j in range(18):
		var yy := float(j*40)
		draw_line(Vector2(640,yy),Vector2(1280,yy+180),Color(.15,.35,.5,.09),1)
	draw_rect(Rect2(627,0,7,720),Color("20cbe8"))
	_txt("NIGHTFALL",Vector2(716,211),69,Color("e4faff"))
	_txt("C H R O N I C L E S",Vector2(725,261),29,Color("7de5f7"))
	_txt("RUÍNAS DO NEXO",Vector2(729,317),21,Color("facf90"))
	_txt("ROGUELITE DE AÇÃO • 24 CÂMARAS • 6 GUARDIÕES",Vector2(725,369),17,Color("c1cbdf"))
	_box(Rect2(724,428,385,83),Color("147e8b"),Color("8fefff"),3)
	_txt("INICIAR AVENTURA",Vector2(748,480),28,Color.WHITE,HORIZONTAL_ALIGNMENT_CENTER,338)
	_box(Rect2(724,536,385,60),Color("171f33"),Color("53677d"),2)
	_txt("ÁUDIO: " + ("DESLIGADO" if is_mute else "LIGADO"),Vector2(749,573),19,Color("d7ebfa"),HORIZONTAL_ALIGNMENT_CENTER,337)
	_txt("RECORDE: CÂMARA %02d    •    CRISTAIS: %d" % [best_stage,lifetime_gems],Vector2(719,650),17,Color("eac791"))
	_txt("VERSÃO ALFA · SEM MULTIPLAYER ATIVO",Vector2(713,690),13,Color("8191a9"))

func _draw_room() -> void:
	var bi := clampi(int((stage-1)/4),0,5)
	var c: Color = [Color("22152c"),Color("132c3d"),Color("24163c"),Color("133d34"),Color("4a2d1a"),Color("152e42")][bi]
	draw_rect(Rect2(0,0,1280,720),Color("060a16"))
	draw_rect(ROOM.grow(10), Color("070b18"))
	draw_rect(ROOM,c)
	if current_room_texture != null:
		draw_texture_rect(current_room_texture, ROOM, false, Color(1, 1, 1, .90))
	for y in range(6):
		for x in range(13):
			var xy := ROOM.position + Vector2(x*96,y*96)
			var textures_key := "tile%d_%d" % [bi, (x*13 + y*7 + x*y*3 + stage) % 8]
			_img(textures_key,Rect2(xy,Vector2(96,96)),Color(1,1,1,.24 if current_room_texture != null else .94))
			if (x*13+y*7+stage)%13 == 0:
				draw_rect(Rect2(xy+Vector2(13,21),Vector2(64,3)),Color(1,1,1,.022))
	var wall_col: Color = [Color("7f5268"),Color("3894b8"),Color("7940a5"),Color("5eaf8d"),Color("e1a264"),Color("65b2dc")][bi]
	for b in [Rect2(55,90,1170,16),Rect2(55,608,1170,17),Rect2(51,90,17,530),Rect2(1213,90,17,530)]:
		draw_rect(b,Color("0b1021"))
		draw_rect(b,wall_col.darkened(.35),false,3)
	for i in range(8):
		var p := ROOM.position + Vector2(i*155 + 43,20)
		_glow_circle(p,14,Color("ffb763") if bi==0 else Color("53d8ff") if bi==1 else Color("b57aff"))
		var p2 := p + Vector2(0,ROOM.size.y-38)
		_glow_circle(p2,9,Color("ffb763") if bi==0 else Color("53d8ff") if bi==1 else Color("b57aff"))
	for r in obstacles:
		draw_rect(r.grow(5),Color("030611"))
		draw_rect(r,Color("303344") if bi==0 else Color("2f586b") if bi==1 else Color("48346f"))
		draw_rect(Rect2(r.position+Vector2(5,4), r.size-Vector2(12,12)),wall_col.darkened(.3),false,2)
		for corner in [r.position+Vector2(4,4),r.end-Vector2(4,4)]:
			draw_circle(corner,3,wall_col)
	if is_boss_room:
		for n in range(8):
			var a := time_elapsed * .4 + TAU*n/8
			var p := Vector2(640,338) + Vector2(cos(a),sin(a))*112
			_glow_circle(p,5,Color("f55b89") if bi==0 else Color("74ccff") if bi==1 else Color("d39dff"))

func _glow_circle(pos: Vector2, radius: float, col: Color) -> void:
	draw_circle(pos,radius*2.5,Color(col.r,col.g,col.b,.06))
	draw_circle(pos,radius*1.6,Color(col.r,col.g,col.b,.14))
	draw_circle(pos,radius,col)

func _draw_entities() -> void:
	for p in pickups:
		var pos: Vector2 = p["pos"]
		if p["type"] == 0:
			_glow_circle(pos,7,Color("ffd476"))
		else:
			_glow_circle(pos,10,Color("67ffa4"))
	for e in enemies:
		var pos: Vector2 = e["pos"]
		var rad: float = e["radius"]
		draw_ellipse_fake(pos+Vector2(0,rad*.75), Vector2(rad*.7,rad*.27),Color(.02,.02,.08,.54))
		var t: int = e["type"]
		var key: String = ["grunt", "cultist", "elite", "boss%d" % clampi(int((stage-1)/4),0,5)][t]
		var size := Vector2(66,80) if t==0 else Vector2(65,80) if t==1 else Vector2(86,94) if t==2 else Vector2(156,168)
		_img(key, Rect2(pos-size/2.0,size), Color(1.4,1.0,1.0) if e["flash"]>0 else Color.WHITE)
		if t == 3 or e["hp"] < e["max_hp"]:
			var rect := Rect2(pos+Vector2(-rad,-rad-30),Vector2(rad*2,7))
			draw_rect(rect,Color("1d1029"))
			draw_rect(Rect2(rect.position,Vector2(rect.size.x*e["hp"]/e["max_hp"],rect.size.y)),Color("f76585"))
	for b in bullets:
		var pos: Vector2 = b["pos"]
		var v: Vector2 = b["vel"].normalized()
		var col: Color = b["color"]
		draw_line(pos-v*16,pos,col,3 if b["enemy"] else 5,true)
		_glow_circle(pos,b["rad"],col)
	for p in particles:
		var cc: Color = p["color"]
		draw_circle(p["pos"],2.4,Color(cc.r,cc.g,cc.b,clampf(p["ttl"]*2.0,0,1)))
	if dash_time > 0:
		_img("hero",Rect2(player_pos-Vector2(42,49)-dash_vector*38,Vector2(84,98)),Color(.2,.9,1,.23))
	if i_frames <= 0 or int(time_elapsed*22)%2 == 0:
		draw_ellipse_fake(player_pos+Vector2(0,27),Vector2(31,10),Color(.02,.02,.06,.6))
		_img("hero",Rect2(player_pos-Vector2(48,55),Vector2(96,110)))
		if hurt_flash > 0:
			draw_circle(player_pos,27,Color(1,.1,.2,.20))
	# Aim reticle showing weapon direction
	draw_arc(player_pos,37,aim_vec.angle()-.16,aim_vec.angle()+.16,7,Color("6af3ff"),3,true)
	if notice_timer > 0 and state == "playing":
		_box(Rect2(358,124,564,53),Color(.04,.08,.15,.85),Color(.29,.73,.85,.7))
		_txt(notification,Vector2(364,159),21,Color("e0f6fc"),HORIZONTAL_ALIGNMENT_CENTER,553)

func draw_ellipse_fake(pos: Vector2, size: Vector2, col: Color) -> void:
	var points := PackedVector2Array()
	for i in range(25):
		var a: float = TAU*float(i)/24.0
		points.append(pos+Vector2(cos(a)*size.x,sin(a)*size.y))
	draw_colored_polygon(points,col)

func _draw_hud() -> void:
	draw_rect(Rect2(0,0,1280,87),Color("070c1b"))
	draw_rect(Rect2(0,86,1280,3),Color("2d697d"))
	_img("avatar",Rect2(22,9,66,65))
	_draw_stat_bar(104,18,265,21,player_hp/max_hp,Color("f04f68"),"VIDA  %d/%d" % [int(player_hp),int(max_hp)])
	_draw_stat_bar(104,46,265,15,player_shield/max_shield,Color("5ddaf4"),"ESCUDO")
	_txt("CÂMARA %02d / %02d" % [stage, TOTAL_STAGES],Vector2(495,37),24,Color("e5f7fc"))
	_txt(room_label,Vector2(497,62),13,Color("8db3c1"))
	_txt("✦  %d" % gems,Vector2(782,47),25,Color("f4cf8c"))
	_txt("ABATES  %d" % kills,Vector2(901,48),18,Color("dceaf1"))
	_box(Rect2(1195,16,60,53),Color("273549"),Color("5a7883"))
	_txt("II",Vector2(1215,51),29)
	draw_rect(Rect2(0,625,1280,95),Color(.04,.07,.15,.78))
	# visual mobile joysticks; fully playable with keyboard/mouse too
	var lpos := left_anchor if left_touch != -1 else Vector2(135,653)
	draw_arc(lpos,61,0,TAU,42,Color(.32,.66,.78,.5),3,true)
	draw_circle(lpos+left_stick*52,31,Color(.23,.65,.81,.25))
	draw_arc(lpos+left_stick*52,30,0,TAU,32,Color(.55,.88,.97,.8),2,true)
	var rpos := right_anchor if right_touch != -1 else Vector2(1040,653)
	draw_arc(rpos,57,0,TAU,42,Color(.81,.39,.49,.5),3,true)
	draw_circle(rpos+right_stick*53,29,Color(.94,.25,.36,.25))
	draw_arc(rpos+right_stick*53,29,0,TAU,32,Color(.99,.62,.69,.8),2,true)
	_txt("ATIRAR",Vector2(999,697),13,Color("ffaabb"))
	_box(Rect2(930,631,77,71),Color(.09,.2,.3,.85),Color("6fd9fc"))
	_txt("E",Vector2(957,680),31)
	_box(Rect2(1126,631,117,71),Color(.21,.13,.25,.92),Color("c390fb"))
	_img("weapon%d"%selected_weapon,Rect2(1140,635,58,58))
	_txt("Q",Vector2(1209,676),20,Color("e9c1fa"))
	_txt(GUN_NAMES[selected_weapon],Vector2(478,674),18,Color("d8f2fc"),HORIZONTAL_ALIGNMENT_CENTER,360)
	_txt("ENERGIA",Vector2(477,691),11,Color("9facc2"))
	draw_rect(Rect2(561,685,195,9),Color("1d3048"))
	draw_rect(Rect2(561,685,195*energy/max_energy,9),Color("79e1bd"))

func _draw_stat_bar(x:float,y:float,w:float,h:float,percent:float,col:Color,label:String) -> void:
	draw_rect(Rect2(x,y,w,h),Color("263047"))
	draw_rect(Rect2(x,y,w*clampf(percent,0,1),h),col)
	draw_rect(Rect2(x,y,w,h),Color("7693a0"),false,1)
	_txt(label,Vector2(x+7,y+h-5),12,Color.WHITE)

func _draw_upgrade() -> void:
	draw_rect(Rect2(0,0,1280,720),Color(.015,.025,.068,.84))
	_panel_title("ESCOLHA SUA EVOLUÇÃO",157,40,Color("defaff"))
	_panel_title("Cada escolha muda o restante da expedição",204,20,Color("9cb4d1"))
	for j in range(choice_ids.size()):
		var id: int = choice_ids[j]
		var rect := Rect2(166+j*322,250,293,283)
		_box(rect,Color("141e35"),Color("7ccee0") if j==1 else Color("6f7fba"),3)
		draw_rect(Rect2(rect.position,Vector2(rect.size.x,9)),Color("54d3ec") if j==1 else Color("b681ff"))
		var symbol: String = ["⚡","+","↗","◇","✦","⊕","▣","↯","✧","✵","↑","♥"][id]
		_txt(symbol,Vector2(rect.position.x+24,rect.position.y+87),65,Color("82e5f8"))
		_txt(UPGRADE_NAMES[id],Vector2(rect.position.x+20,rect.position.y+145),22,Color("ffffff"))
		_txt(UPGRADE_DESCS[id],Vector2(rect.position.x+20,rect.position.y+184),18,Color("b0c4dd"))
		_box(Rect2(rect.position+Vector2(24,216),Vector2(245,48)),Color("1f8291"),Color("8cefff"))
		_txt("ESCOLHER  %d"%(j+1),rect.position+Vector2(42,248),20,Color.WHITE,HORIZONTAL_ALIGNMENT_CENTER,205)

func _draw_result() -> void:
	draw_rect(Rect2(0,0,1280,720),Color(.01,.02,.06,.88))
	_panel_title("O NEXO FOI RESTAURADO" if state=="win" else "EXPEDIÇÃO ENCERRADA",222,49,Color("a4fff0") if state=="win" else Color("ff8ba7"))
	_panel_title("CÂMARA ALCANÇADA: %d / %d" % [stage, TOTAL_STAGES],292,28)
	_panel_title("INIMIGOS DERROTADOS: %d" % kills,348,22,Color("becfe3"))
	_panel_title("CRISTAIS COLETADOS: %d" % gems,391,22,Color("ffe29a"))
	_box(Rect2(455,485,370,67),Color("177e8f"),Color("8af3ff"),3)
	_txt("JOGAR NOVAMENTE",Vector2(475,530),26,Color.WHITE,HORIZONTAL_ALIGNMENT_CENTER,326)
	_txt("VOLTAR AO MENU",Vector2(475,610),18,Color("9fbad3"),HORIZONTAL_ALIGNMENT_CENTER,326)

func _draw_pause() -> void:
	draw_rect(Rect2(0,0,1280,720),Color(.01,.02,.06,.83))
	_panel_title("PAUSADO",294,52,Color("def7ff"))
	_box(Rect2(455,367,370,65),Color("147d8b"),Color("8aefff"),3)
	_txt("CONTINUAR",Vector2(480,408),25,Color.WHITE,HORIZONTAL_ALIGNMENT_CENTER,320)
	_box(Rect2(455,450,370,65),Color("1d293b"),Color("667e93"),2)
	_txt("SAIR PARA MENU",Vector2(480,491),24,Color.WHITE,HORIZONTAL_ALIGNMENT_CENTER,320)
