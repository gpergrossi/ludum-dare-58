@tool
class_name ClutterSystem extends Node3D

const MIN_UPDATE_DELAY := 0.25
const MAX_PARTICLES_PER_LOOP := 250
const FRAME_SHARE := 2

@export_tool_button("Force Update") var force_update_action: Callable = do_forced_update
func do_forced_update() -> void:
	for plane in clutter_planes:
		_dirty_set[plane] = true

@export var max_particles := 20000
@export var player: RoboVac

signal small_props_changed(collected: int, total: int)

var clutter_planes: Array[ClutterPlane] = []
var update_delay := 0.0
var current_particle_count := 0
var total_particle_count := 0
var _dirty_set: Dictionary[ClutterPlane, bool] = {}
var _working_sets: Dictionary[ClutterPlane, int] = {}
var _mesh_sets: Dictionary[ClutterPlane, MultiMeshInstance3D] = {}
var particle_density_scale := 1.0
var frame_i := 0

func _ready() -> void:
	for child in get_children(true):
		if child is MultiMeshInstance3D or child is MeshInstance3D:
			child.name = "Garbage"
			child.queue_free()
		if child is ClutterPlane:
			var plane := (child as ClutterPlane)
			clutter_planes.append(plane)
			_dirty_set[plane] = true
			if not plane.clutter_plane_changed.is_connected(on_clutter_plane_changed):
				plane.clutter_plane_changed.connect(on_clutter_plane_changed)
	if not child_entered_tree.is_connected(on_child_added):
		child_entered_tree.connect(on_child_added)
	if not child_exiting_tree.is_connected(on_child_removed):
		child_exiting_tree.connect(on_child_removed)
	update_delay = MIN_UPDATE_DELAY


func on_child_added(child: Node) -> void:
	if child is ClutterPlane:
		var plane := (child as ClutterPlane)
		clutter_planes.append(plane)
		_dirty_set[plane] = true
		if update_delay <= 0.0:
			update_delay = MIN_UPDATE_DELAY
		if not plane.clutter_plane_changed.is_connected(on_clutter_plane_changed):
			plane.clutter_plane_changed.connect(on_clutter_plane_changed)


func on_child_removed(child: Node) -> void:
	if child is ClutterPlane:
		var plane := (child as ClutterPlane)
		var index := clutter_planes.find(plane)
		if index != -1:
			if plane.clutter_plane_changed.is_connected(on_clutter_plane_changed):
				plane.clutter_plane_changed.disconnect(on_clutter_plane_changed)
			clutter_planes.remove_at(index)
			_dirty_set[plane] = true
			if update_delay <= 0.0:
				update_delay = MIN_UPDATE_DELAY


func on_clutter_plane_changed(clutter_plane: ClutterPlane) -> void:
	_dirty_set[clutter_plane] = true
	if update_delay <= 0.0:
		update_delay = MIN_UPDATE_DELAY
	
	# Recompute desired particle count
	total_particle_count = 0
	for plane in clutter_planes:
		total_particle_count += plane.item_count
	#print("Currently need " + str(total_particle_count) + " particles")
	
	## Compute and potentially update global particle density
	#var old_scale := particle_density_scale
	#particle_density_scale = minf(1.0, float(max_particles) / float(total_particle_count))
	#if particle_density_scale != old_scale:
		#for plane in clutter_planes:
			#_dirty_set[plane] = true


func _process(delta: float) -> void:
	if not _dirty_set.is_empty():
		if update_delay >= 0.0:
			update_delay -= delta
		
		if update_delay <= 0.0:
			var plane: ClutterPlane = _dirty_set.keys()[0]
			if not _working_sets.has(plane):
				refresh_plane(plane)
				_dirty_set.erase(plane)
			
				update_delay = MIN_UPDATE_DELAY
	
	if not _working_sets.is_empty():
		var plane: ClutterPlane = _working_sets.keys()[0]
		var target_count := _working_sets[plane]
		var mesh_set := _mesh_sets[plane]
		if mesh_set.multimesh.visible_instance_count < target_count:
			add_particles(mesh_set, plane, mini(roundi(float(MAX_PARTICLES_PER_LOOP) / _working_sets.size()), target_count - mesh_set.multimesh.visible_instance_count))
		else:
			_working_sets.erase(plane)
			current_particle_count = 0
			for cplane in clutter_planes:
				if _mesh_sets.has(cplane):
					mesh_set = _mesh_sets[cplane]
					current_particle_count += mesh_set.multimesh.visible_instance_count
			if not Engine.is_editor_hint():
				small_props_changed.emit(total_particle_count - current_particle_count, total_particle_count)
	
	do_dust_collection(delta)


func refresh_plane(plane: ClutterPlane) -> void:
	if clutter_planes.find(plane) == -1:
		cleanup_plane(plane)
	
	else:
		var mesh_set: MultiMeshInstance3D = null
		if _mesh_sets.has(plane):
			mesh_set = _mesh_sets[plane]
			if mesh_set.multimesh.mesh != plane.mesh:
				cleanup_plane(plane)
				mesh_set = null
		
		if mesh_set == null:
			mesh_set = create_mesh_set(plane)
			add_child(mesh_set)
			_mesh_sets[plane] = mesh_set
		
		refresh_plane_set(plane, mesh_set)


func cleanup_plane(plane: ClutterPlane) -> void:
	if _mesh_sets.has(plane):
		var mesh_set := _mesh_sets[plane]
		mesh_set.queue_free()
		_mesh_sets.erase(plane)


func create_mesh_set(plane: ClutterPlane) -> MultiMeshInstance3D:
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "MultiMesh_" + plane.name
	mmi.multimesh = MultiMesh.new()
	mmi.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	mmi.multimesh.use_colors = true
	
	plane.compute_bounds()
	mmi.custom_aabb = plane.create_global_aabb()
	#mmi.add_child(plane.create_debug_mesh())
	
	mmi.multimesh.instance_count = plane.item_count
	mmi.multimesh.visible_instance_count = 0
	mmi.multimesh.mesh = plane.mesh
	return mmi


func refresh_plane_set(plane: ClutterPlane, mesh_set: MultiMeshInstance3D) -> void:
	if not _working_sets.has(plane):
		var target_items := roundi(plane.item_count * particle_density_scale)
		mesh_set.multimesh.visible_instance_count = 0
		_working_sets[plane] = target_items


func add_particles(mesh_set: MultiMeshInstance3D, plane: ClutterPlane, amount: int) -> void:
	var rand := RandomNumberGenerator.new()
	rand.seed = plane.item_seed
	rand.state = mesh_set.multimesh.visible_instance_count * 271
	
	var max_add := mesh_set.multimesh.instance_count - mesh_set.multimesh.visible_instance_count
	amount = maxi(0, mini(amount, max_add))
	
	if amount > 0:
		var index := mesh_set.multimesh.visible_instance_count
		for i in range(amount):
			var color := plane.get_random_color(rand)
			var size := plane.get_random_size(rand)
			var part_pos := plane.get_sample(rand, size)
			if not part_pos.is_finite():
				part_pos = mesh_set.multimesh.get_instance_transform(0).origin
			var part_basis := plane.basis.rotated(plane.basis.y, rand.randf() * TAU).scaled(size * Vector3.ONE)
			var xform := Transform3D(part_basis, part_pos)
			mesh_set.multimesh.set_instance_color(index + i, color)
			mesh_set.multimesh.set_instance_transform(index + i, xform)
		mesh_set.multimesh.visible_instance_count += amount


func do_dust_collection(delta: float):
	if Engine.is_editor_hint(): return
	if not player: return
	
	frame_i += 1
	delta *= FRAME_SHARE
	
	var batch_size := ceili(float(max_particles) / float(FRAME_SHARE))
	var begin := batch_size * (frame_i % FRAME_SHARE)
	var player_pos := player.global_position + player.global_basis.y * 0.05
	
	for plane in clutter_planes:
		if not player.can_vacuum(plane): continue
		if not _mesh_sets.has(plane): continue
		
		var local_pos := plane.to_local(player_pos)
		if not plane.expanded_aabb.has_point(local_pos):
			continue
		
		var particles := _mesh_sets[plane]
		
		for i in range(begin, minf(particles.multimesh.visible_instance_count, begin + batch_size)):
			var xform := particles.multimesh.get_instance_transform(i)
			
			var ppos := xform.origin
			var pscale := xform.basis.get_scale()
			if pscale.is_zero_approx():
				continue
			
			var diff: Vector3 = player.position - ppos
			var dist2 := diff.length_squared()
			
			if dist2 < (player.vacuum_radius ** 2):
				var dist := sqrt(dist2)
				var pbasis := xform.basis
			
				if dist2 < 0.15:
					# Overwrite with last particle
					if particles.multimesh.visible_instance_count > 0:
						var last_index := particles.multimesh.visible_instance_count-1
						var last_color := particles.multimesh.get_instance_color(last_index)
						var last_xform := particles.multimesh.get_instance_transform(last_index)
						particles.multimesh.set_instance_color(i, last_color)
						particles.multimesh.set_instance_transform(i, last_xform)
						particles.multimesh.visible_instance_count -= 1
					if player:
						player.on_dust_collected(plane, plane.points_per_item)
						current_particle_count -= 1
						if not Engine.is_editor_hint():
							small_props_changed.emit(total_particle_count - current_particle_count, total_particle_count)
					continue
				
				if dist2 < 0.3:
					pscale.lerp(Vector3.ONE * plane.min_size, (0.6 - sqrt(dist2)) / 0.6)
					
					var descalar := pbasis.get_scale().inverse()
					pbasis.x *= descalar.x
					pbasis.y *= descalar.y
					pbasis.z *= descalar.z
					pbasis = pbasis.scaled(pscale)
				
				var dir := Vector3(diff.x, 0, diff.z).normalized()
				var vac_radius: float = player.vacuum_radius
				var vac_power: float = player.get_current_vacuum_power()
				var pull := sqrt(maxf(0.0, 1.0 - dist / vac_radius)) * vac_power
				ppos += dir * pull * delta
				
				# Project back onto plane
				ppos = ppos.move_toward(ppos - (ppos - plane.position).dot(plane.basis.y) * plane.basis.y, delta)
				particles.multimesh.set_instance_transform(i, Transform3D(pbasis, ppos))
