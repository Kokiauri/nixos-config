// Faint gruvbox-orange streak that trails the cursor on bigger jumps.
// Uses ghostty's iCurrentCursor / iPreviousCursor / iTimeCursorChange uniforms.

const vec3  TRAIL_COLOR = vec3(0.906, 0.541, 0.306); // #e78a4e
const float DURATION    = 0.12;                      // seconds the trail lingers
const float OPACITY     = 0.25;                      // peak strength of the streak
const float MIN_JUMP    = 3.0;                       // cells moved before a trail shows

// distance from p to the segment a-b
float sdSegment(vec2 p, vec2 a, vec2 b) {
    vec2 pa = p - a, ba = b - a;
    float h = clamp(dot(pa, ba) / max(dot(ba, ba), 1e-4), 0.0, 1.0);
    return length(pa - ba * h);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec4 term = texture(iChannel0, fragCoord / iResolution.xy);
    fragColor = term;
    if (iFocus == 0 || iCursorVisible.x == 0.0) return;

    // xy is the top-left corner (y up), zw is width/height
    vec2 curSize  = iCurrentCursor.zw;
    vec2 cur      = iCurrentCursor.xy  + vec2(curSize.x, -curSize.y) * 0.5;
    vec2 prev     = iPreviousCursor.xy + vec2(iPreviousCursor.z, -iPreviousCursor.w) * 0.5;

    // fading trail from the previous position, only for real jumps (not every keystroke)
    float t = clamp((iTime - iTimeCursorChange) / DURATION, 0.0, 1.0);
    float trail = 0.0;
    if (t < 1.0 && distance(cur, prev) > curSize.x * MIN_JUMP) {
        vec2 tail = mix(prev, cur, 1.0 - (1.0 - t) * (1.0 - t)); // ease-out catch-up
        float width = min(curSize.x, curSize.y) * 0.2 * (1.0 - t);
        float d = sdSegment(fragCoord, tail, cur) - width;
        trail = (1.0 - smoothstep(0.0, 1.5, d)) * (1.0 - t) * OPACITY;
    }

    fragColor.rgb = mix(fragColor.rgb, TRAIL_COLOR, clamp(trail, 0.0, 1.0));
}
