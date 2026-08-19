extends Node

var _failures := 0


func _ready() -> void:
	var player := Unit.new()
	player.team = 0
	player.position = Vector2(-600, 0)
	add_child(player)

	var near_enemy := Unit.new()
	near_enemy.team = 1
	near_enemy.position = Vector2(-380, 0)
	add_child(near_enemy)

	var far_enemy := Unit.new()
	far_enemy.team = 1
	far_enemy.position = Vector2(650, 0)
	add_child(far_enemy)

	var enemy_base := Building.new()
	enemy_base.setup("wubao", 1, true)
	enemy_base.position = Vector2(680, 80)
	add_child(enemy_base)

	var fog := FogOfWar.new()
	fog.setup(Rect2(-1000, -500, 2000, 1000))
	add_child(fog)
	await get_tree().process_frame
	fog.refresh_now()

	_expect(near_enemy.visible, "近处敌军应处于当前视野")
	_expect(not far_enemy.visible, "远处敌军应被迷雾隐藏")
	_expect(not enemy_base.visible, "远处敌方建筑应被迷雾隐藏")

	player.position = Vector2(650, 0)
	fog.refresh_now()
	_expect(far_enemy.visible, "侦察到远处后敌军应显形")
	_expect(enemy_base.visible, "侦察到远处后敌方建筑应显形")
	_expect(fog.is_explored(far_enemy.position), "侦察区域应记录为已探索")

	player.position = Vector2(-600, 0)
	fog.refresh_now()
	_expect(not far_enemy.visible, "撤离后敌军应再次隐藏")
	_expect(not fog.is_currently_visible(far_enemy.position), "撤离后区域不应保持当前视野")
	_expect(fog.is_explored(far_enemy.position), "撤离后探索记录应保留")

	var tower := Building.new()
	tower.setup("gulou", 0, true)
	tower.position = Vector2.ZERO
	add_child(tower)
	fog.refresh_now()
	_expect(fog.is_currently_visible(Vector2(480, 0)), "防御塔应提供较大视野")

	if _failures == 0:
		print("TEST_FOG PASS")
		get_tree().quit(0)
	else:
		push_error("TEST_FOG FAIL: %d 项失败" % _failures)
		get_tree().quit(1)


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("  PASS: " + message)
	else:
		_failures += 1
		push_error("  FAIL: " + message)
