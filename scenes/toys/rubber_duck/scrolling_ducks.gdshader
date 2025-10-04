shader_type canvas_item;

uniform vec2 texture_scale = vec2(16.0, 16.0);

varying vec2 uv;

void vertex() {
	uv = UV * texture_scale;
}

void fragment() {

}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
