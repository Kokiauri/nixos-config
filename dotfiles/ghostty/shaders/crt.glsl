// Subtle retro-monitor look: scanlines + vignette + a hint of phosphor bloom.
// Off by default; enable with a second custom-shader line in ../config.

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    vec3 col = texture(iChannel0, uv).rgb;

    // cheap 4-tap bloom so bright text bleeds a little
    vec2 px = 1.5 / iResolution.xy;
    vec3 bloom = texture(iChannel0, uv + vec2(px.x, 0)).rgb + texture(iChannel0, uv - vec2(px.x, 0)).rgb
               + texture(iChannel0, uv + vec2(0, px.y)).rgb + texture(iChannel0, uv - vec2(0, px.y)).rgb;
    col += max(bloom * 0.25 - col, 0.0) * 0.35;

    col *= 0.94 + 0.06 * sin(fragCoord.y * 3.14159);           // scanlines
    vec2 v = uv * (1.0 - uv);
    col *= mix(0.82, 1.0, clamp(pow(v.x * v.y * 16.0, 0.25), 0.0, 1.0)); // vignette

    fragColor = vec4(col, 1.0);
}
