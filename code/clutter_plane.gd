@tool
class_name ClutterPlane extends CollisionShape3D

var _dirty := false

@onready var bounds := self.shape as BoxShape3D
@onready var sprite_3d: Sprite3D = %Sprite3D

@export_tool_button("Force Update") var force_update_action: Callable = do_forced_update
func do_forced_update() -> void:
	_dirty = true

@export var show_pattern_in_editor := true:
	set(s):
		show_pattern_in_editor = s
		_dirty = true

@export var mesh: Mesh:
	set(m):  mesh = m; _dirty = true

@export var colors: GradientTexture1D:
	set(c):
		if colors and colors.changed.is_connected(on_colors_changed):
			colors.changed.disconnect(on_colors_changed)
			if colors.gradient and colors.gradient.changed.is_connected(on_colors_changed):
				colors.gradient.changed.disconnect(on_colors_changed)
		colors = c;
		if colors:
			colors.changed.connect(on_colors_changed)
			if colors.gradient:
				colors.gradient.changed.connect(on_colors_changed)
		_dirty = true

@export var item_count := 2000:
	set(c):  item_count = c; _dirty = true

@export var item_radius := 0.05:
	set(r):  item_radius = r; _dirty = true

@export var item_seed := 0:
	set(s):  item_seed = s; _dirty = true

@export var pattern: Texture2D:
	set(p):  pattern = p; decompressed_image = null; _dirty = true

@export var min_size: float:
	set(s):  min_size = s; _dirty = true
	
@export var max_size: float:
	set(s):  max_size = s; _dirty = true

@export_enum("DUST", "SMALL", "MEDIUM", "LARGE") var size_class := 0
@export var points_per_item := 1

signal clutter_plane_changed(plane: ClutterPlane)

var decompressed_image: Image
@onready var last_position := position
@onready var last_basis := basis


func _ready() -> void:
	if not bounds.changed.is_connected(on_bounds_changed):
		bounds.changed.connect(on_bounds_changed)

func on_bounds_changed() -> void:
	_dirty = true

func on_colors_changed() -> void:
	_dirty = true

func _process(_delta: float) -> void:
	if not last_position.is_equal_approx(position) or not basis.is_equal_approx(last_basis):
		last_position = position
		last_basis = basis
		_dirty = true
	
	if _dirty:
		_dirty = false
		refresh()


func refresh() -> void:
	sprite_3d.visible = show_pattern_in_editor and Engine.is_editor_hint()
	sprite_3d.texture = pattern
	
	var pattern_size := pattern.get_size()
	var bounds_size := Vector2(bounds.size.x, bounds.size.z)
	
	var scale_by_w := bounds_size.x / pattern_size.x
	var scale_by_h := bounds_size.y / pattern_size.y
	
	sprite_3d.pixel_size = maxf(scale_by_w, scale_by_h)
	if scale_by_w > scale_by_h:
		var extra_h := (pattern_size.y * scale_by_w - bounds_size.y) / scale_by_w
		if extra_h > 1.0:
			sprite_3d.region_rect = Rect2(0, extra_h * 0.5, pattern_size.x, pattern_size.y - extra_h)
	else:
		var extra_w := (pattern_size.x * scale_by_h - bounds_size.x) / scale_by_h
		if extra_w > 1.0:
			sprite_3d.region_rect = Rect2(extra_w * 0.5, 0, pattern_size.x - extra_w, pattern_size.y)
	
	print("Refreshing self: " + str(name))
	clutter_plane_changed.emit(self)



var bag: PackedVector4Array = []


func get_sample(rand: RandomNumberGenerator, item_scale: float) -> Vector3:
	# Generate 8 possibilities
	var total_weight := 0.0
	var sample: Vector4
	bag.resize(64)
	for i in range(64):
		sample = _get_sample_pt_internal(rand, item_scale)
		bag[i] = sample
		total_weight += sample.w
	
	# Roll by normalized weight
	var r := rand.randf()
	sample = bag[63]
	for i in range(63):
		sample = bag[i]
		var weight := (sample.w / total_weight)
		if r >= weight:
			r -= weight
		else:
			break
	
	return Vector3(sample.x, sample.y, sample.z)


func get_random_color(rand: RandomNumberGenerator) -> Color:
	return colors.gradient.sample(rand.randf())


func get_random_size(rand: RandomNumberGenerator) -> float:
	return rand.randf_range(min_size, max_size)


func _get_sample_pt_internal(rand: RandomNumberGenerator, item_scale: float) -> Vector4:
	# Roll a random point2d in parameter space (from 0,0 to 1,1).
	var params := Vector2(rand.randf(), rand.randf())
	var margin := item_radius * item_scale
	
	# Convert to world space.
	var size_model := Vector2(bounds.size.x, bounds.size.z)
	var min_model := -0.5 * size_model
	var max_model := +0.5 * size_model
	var pos_model := min_model + size_model * params
	
	# Enforce margin in model space.
	pos_model.x = maxf(pos_model.x, min_model.x + margin)
	pos_model.x = minf(pos_model.x, max_model.x - margin)
	pos_model.y = maxf(pos_model.y, min_model.y + margin)
	pos_model.y = minf(pos_model.y, max_model.y - margin)
	
	# Convert back to parameter space
	params.x = (pos_model.x - min_model.x) / size_model.x
	params.y = (pos_model.y - min_model.y) / size_model.y
	
	# Convert to pixel space
	var pixel := Vector2i(sprite_3d.region_rect.position + params * sprite_3d.region_rect.size)
	
	if decompressed_image == null:
		decompressed_image = pattern.get_image()
		if decompressed_image.is_compressed():
			decompressed_image.decompress()
	
	var pixel_color := decompressed_image.get_pixelv(pixel)
	var pos3 := position + basis.x * pos_model.x + basis.z * pos_model.y
	return Vector4(
		pos3.x, pos3.y, pos3.z,
		minf(1.0, pixel_color.a + 0.001)
	)
