#version 110
#extension GL_ARB_texture_rectangle : enable
uniform vec3			iResolution;           // viewport resolution (in pixels)
uniform sampler2DRect	iChannel0;
uniform vec3			iMouse;                // mouse pixel coords. xy: current (if MLB down), zw: click
uniform int				width;
uniform int				height;
uniform float			iGlobalTime;           // shader playback time (in seconds)

vec2 cs(float t) {
	return vec2((pow(1.0+sin(t*3.11), 1.3)-.5) * (0.2 + 0.2*cos(t*2.31)), 
	(pow(1.0+sin(t*4.0), 1.5)-.5) * (0.2 + 0.2*sin(t*1.4)));
}

void main()
{
	// OK pass through
	//vec2 uv = gl_TexCoord[0].st* vec2(width,height);
    //gl_FragColor = texture2DRect(iChannel0, uv);
	//gl_FragColor.a = 1.0;

	// KO
	//vec2 uv = gl_FragCoord.xy / iResolution.xy;
	//vec2 divs = vec2(iResolution.x * 200.0 / iResolution.y, 200.0);
	//uv = floor(uv * divs)/ divs;
	//gl_FragColor = texture2DRect(iChannel0, uv);

	// OK moving gradient
	//vec2 uv = gl_FragCoord.xy / iResolution.xy;
	//gl_FragColor = vec4(uv,abs(cos(iGlobalTime *0.5)) + sin( iGlobalTime * uv.x / abs(sin(3.0 * uv.y / iGlobalTime * sin(3.5)))) *sin(iGlobalTime),1.0);
	//gl_FragColor.a = 1.0;

	vec2 uv = gl_TexCoord[0].st* vec2(width,height);

	vec2 lightPosition = iMouse.xy;
	float radius = 350.0;
    float distance  = length( lightPosition - gl_FragCoord.xy );
    float maxDistance = pow( radius, 0.21);
    float quadDistance = pow( distance, 0.23);
    float quadIntensity = 2.0 - min( quadDistance, maxDistance )/maxDistance;
	//vec4 texture = texture2DRect(iChannel0, gl_FragCoord.xy / iResolution.xy);
	vec4 texture = texture2DRect(iChannel0, uv);
	gl_FragColor = texture * vec4(quadIntensity);
	gl_FragColor.a = 1.0;
}