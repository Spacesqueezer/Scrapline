shader_type canvas_item;

uniform float speed = 1.0;

void fragment() {
    vec2 uv = UV;
    // Смещаем текстуру по оси X со временем (т.к. база теперь RIGHT)
    uv.x += TIME * speed;

    // Используем fract для зацикливания, чтобы текстура не искажалась
    uv.x = fract(uv.x);

    COLOR = texture(TEXTURE, uv);
}
