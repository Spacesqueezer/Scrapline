shader_type canvas_item;

uniform float speed = 1.0;

void fragment() {
    vec2 uv = UV;
    // Смещаем текстуру по оси Y со временем
    uv.y += TIME * speed;

    // Используем fract для зацикливания, чтобы текстура не искажалась
    uv.y = fract(uv.y);

    COLOR = texture(TEXTURE, uv);
}
