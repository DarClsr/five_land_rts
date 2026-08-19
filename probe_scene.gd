extends Node2D
var frames := 0
var po: Unit
var guard: Unit
func _ready():
	var trav := PackedVector2Array([Vector2(-500,-300), Vector2(500,-300), Vector2(500,300), Vector2(-500,300)])
	var r := NavRegistry.new()
	r.setup(self, trav, [])
	add_child(r)
	po = Defs.spawn("xuantiebingpo", 0)
	po.position = Vector2(0, 200)
	add_child(po)
	guard = Defs.spawn("yanjiawei", 0)
	guard.position = Vector2(40, 200)
	add_child(guard)
func _physics_process(_d):
	frames += 1
	if frames % 45 == 0:
		print("frame %d: po.sharp=%s guard.buff=%.2f dist=%.0f po_alive=%s po_team=%d" % [frames, po.has_sharp_aura, guard.dmg_buff_mult, po.global_position.distance_to(guard.global_position), po.alive, po.team])
	if frames >= 200:
		print("done")
		get_tree().quit(0)
