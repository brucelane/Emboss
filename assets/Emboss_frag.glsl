#version 110

uniform vec3		iResolution;           // viewport resolution (in pixels)
uniform float		iGlobalTime;           // shader playback time (in seconds)
uniform int			iEmboss;           
uniform vec3		iMouse;                // mouse pixel coords. xy: current (if MLB down), zw: click
uniform sampler2D	iChannel0;
uniform sampler2D	iChannel1;
uniform vec3		iChannelResolution;

// Using a sobel filter to create a normal map and then applying simple lighting.

// This makes the darker areas less bumpy but I like it
#define USE_LINEAR_FOR_BUMPMAP

//#define SHOW_NORMAL_MAP
//#define SHOW_ALBEDO

struct C_Sample
{
	vec3 vAlbedo;
	vec3 vNormal;
};
	
C_Sample SampleMaterial(const in vec2 vUV, sampler2D sampler,  const in vec2 vTextureSize, const in float fNormalScale)
{
	C_Sample result;
	
	vec2 vInvTextureSize = vec2(1.0) / vTextureSize;
	
	vec3 cSampleNegXNegY = texture2D(sampler, vUV + (vec2(-1.0, -1.0)) * vInvTextureSize.xy).rgb;
	vec3 cSampleZerXNegY = texture2D(sampler, vUV + (vec2( 0.0, -1.0)) * vInvTextureSize.xy).rgb;
	vec3 cSamplePosXNegY = texture2D(sampler, vUV + (vec2( 1.0, -1.0)) * vInvTextureSize.xy).rgb;
	
	vec3 cSampleNegXZerY = texture2D(sampler, vUV + (vec2(-1.0, 0.0)) * vInvTextureSize.xy).rgb;
	vec3 cSampleZerXZerY = texture2D(sampler, vUV + (vec2( 0.0, 0.0)) * vInvTextureSize.xy).rgb;
	vec3 cSamplePosXZerY = texture2D(sampler, vUV + (vec2( 1.0, 0.0)) * vInvTextureSize.xy).rgb;
	
	vec3 cSampleNegXPosY = texture2D(sampler, vUV + (vec2(-1.0,  1.0)) * vInvTextureSize.xy).rgb;
	vec3 cSampleZerXPosY = texture2D(sampler, vUV + (vec2( 0.0,  1.0)) * vInvTextureSize.xy).rgb;
	vec3 cSamplePosXPosY = texture2D(sampler, vUV + (vec2( 1.0,  1.0)) * vInvTextureSize.xy).rgb;

	// convert to linear	
	vec3 cLSampleNegXNegY = cSampleNegXNegY * cSampleNegXNegY;
	vec3 cLSampleZerXNegY = cSampleZerXNegY * cSampleZerXNegY;
	vec3 cLSamplePosXNegY = cSamplePosXNegY * cSamplePosXNegY;

	vec3 cLSampleNegXZerY = cSampleNegXZerY * cSampleNegXZerY;
	vec3 cLSampleZerXZerY = cSampleZerXZerY * cSampleZerXZerY;
	vec3 cLSamplePosXZerY = cSamplePosXZerY * cSamplePosXZerY;

	vec3 cLSampleNegXPosY = cSampleNegXPosY * cSampleNegXPosY;
	vec3 cLSampleZerXPosY = cSampleZerXPosY * cSampleZerXPosY;
	vec3 cLSamplePosXPosY = cSamplePosXPosY * cSamplePosXPosY;

	// Average samples to get albdeo colour
	result.vAlbedo = ( cLSampleNegXNegY + cLSampleZerXNegY + cLSamplePosXNegY 
		    	     + cLSampleNegXZerY + cLSampleZerXZerY + cLSamplePosXZerY
		    	     + cLSampleNegXPosY + cLSampleZerXPosY + cLSamplePosXPosY ) / 9.0;	
	
	vec3 vScale = vec3(0.3333);
	
	#ifdef USE_LINEAR_FOR_BUMPMAP
		
		float fSampleNegXNegY = dot(cLSampleNegXNegY, vScale);
		float fSampleZerXNegY = dot(cLSampleZerXNegY, vScale);
		float fSamplePosXNegY = dot(cLSamplePosXNegY, vScale);
		
		float fSampleNegXZerY = dot(cLSampleNegXZerY, vScale);
		float fSampleZerXZerY = dot(cLSampleZerXZerY, vScale);
		float fSamplePosXZerY = dot(cLSamplePosXZerY, vScale);
		
		float fSampleNegXPosY = dot(cLSampleNegXPosY, vScale);
		float fSampleZerXPosY = dot(cLSampleZerXPosY, vScale);
		float fSamplePosXPosY = dot(cLSamplePosXPosY, vScale);
	
	#else
	
		float fSampleNegXNegY = dot(cSampleNegXNegY, vScale);
		float fSampleZerXNegY = dot(cSampleZerXNegY, vScale);
		float fSamplePosXNegY = dot(cSamplePosXNegY, vScale);
		
		float fSampleNegXZerY = dot(cSampleNegXZerY, vScale);
		float fSampleZerXZerY = dot(cSampleZerXZerY, vScale);
		float fSamplePosXZerY = dot(cSamplePosXZerY, vScale);
		
		float fSampleNegXPosY = dot(cSampleNegXPosY, vScale);
		float fSampleZerXPosY = dot(cSampleZerXPosY, vScale);
		float fSamplePosXPosY = dot(cSamplePosXPosY, vScale);	
	
	#endif
	
	// Sobel operator - http://en.wikipedia.org/wiki/Sobel_operator
	
	vec2 vEdge;
	vEdge.x = (fSampleNegXNegY - fSamplePosXNegY) * 0.25 
			+ (fSampleNegXZerY - fSamplePosXZerY) * 0.5
			+ (fSampleNegXPosY - fSamplePosXPosY) * 0.25;

	vEdge.y = (fSampleNegXNegY - fSampleNegXPosY) * 0.25 
			+ (fSampleZerXNegY - fSampleZerXPosY) * 0.5
			+ (fSamplePosXNegY - fSamplePosXPosY) * 0.25;

	result.vNormal = normalize(vec3(vEdge * fNormalScale, 1.0));	
	
	return result;
}

void main(void)
{	
	if ( iEmboss==0 )
	{
		vec3 c[9];
		for (int i=0; i < 3; ++i)
		{
			for (int j=0; j < 3; ++j)
			{
				c[3*i+j] = texture2D(iChannel1, (gl_FragCoord.xy+vec2(i-1,j-1)) / iResolution.xy).rgb;
			}
		}
	
		vec3 Lx = 2.0*(c[7]-c[1]) + c[6] + c[8] - c[2] - c[0];
		vec3 Ly = 2.0*(c[3]-c[5]) + c[6] + c[0] - c[2] - c[8];
		vec3 G = sqrt(Lx*Lx+Ly*Ly);
	
		gl_FragColor = vec4(G, 1.0);
	}
	else
	{
		if ( iEmboss==1 )
		{
			vec2 vUV = gl_FragCoord.xy / iResolution.xy;
	
			C_Sample materialSample;
		
			float fNormalScale = 10.0;
			materialSample = SampleMaterial( vUV, iChannel0, iChannelResolution.xy, fNormalScale );
	
			// Random Lighting...
	
			float fLightHeight = 0.2;
			float fViewHeight = 2.0;
	
			vec3 vSurfacePos = vec3(vUV, 0.0);
	
			vec3 vViewPos = vec3(0.5, 0.5, fViewHeight);
			
			vec3 vLightPos = vec3( vec2(sin(iGlobalTime),cos(iGlobalTime)) * 0.25 + 0.5 , fLightHeight);
		
			if( iMouse.z > 0.0 )
			{
				vLightPos = vec3(iMouse.xy / iResolution.xy, fLightHeight);
			}
	
			vec3 vDirToView = normalize( vViewPos - vSurfacePos );
			vec3 vDirToLight = normalize( vLightPos - vSurfacePos );
		
			float fNDotL = clamp( dot(materialSample.vNormal, vDirToLight), 0.0, 1.0);
			float fDiffuse = fNDotL;
	
			vec3 vHalf = normalize( vDirToView + vDirToLight );
			float fNDotH = clamp( dot(materialSample.vNormal, vHalf), 0.0, 1.0);
			float fSpec = pow(fNDotH, 10.0) * fNDotL * 0.5;
	
			vec3 vResult = materialSample.vAlbedo * fDiffuse + fSpec;
	
			vResult = sqrt(vResult);
	
			#ifdef SHOW_NORMAL_MAP
			vResult = materialSample.vNormal * 0.5 + 0.5;
			#endif
	
			#ifdef SHOW_ALBEDO
			vResult = sqrt(materialSample.vAlbedo);
			#endif
	
			gl_FragColor = vec4(vResult,1.0);
		}
		else
		{
			vec2 p = (gl_FragCoord.xy / iResolution.xy)  ;
	
			vec3 color =vec3(1.0+p.y*1.2,0.8+p.y*9.,2.8+p.y*8.);
			vec3 a ;
		//	float Mx = 22.;
			for ( float i	=22. ; i > 8.0; i-- ){
				color	*=	0.8;
		//		color	=	pow(color,1.1);
		
				vec2 nNoise = vec2(iGlobalTime*(0.5+i*0.1),p.x*(sin(-p.x*20.-iGlobalTime*5.)*2.+0.5+i*0.3));
				const vec2 d = vec2(0.0, 1.0);
				vec2 b = floor(nNoise), f = smoothstep(vec2(0.0), vec2(1.0), fract(nNoise));
		
				float rand1 = fract(sin(dot(b, vec2(12.9898, 4.1414))) * 43758.5453);
				float rand2 = fract(sin(dot((b + d.yx), vec2(12.9898, 4.1414))) * 43758.5453);
				float rand3 = fract(sin(dot((b + d.xy), vec2(12.9898, 4.1414))) * 43758.5453);
				float rand4 = fract(sin(dot((b + d.yy), vec2(12.9898, 4.1414))) * 43758.5453);
		
				float noise = mix(mix(rand1, rand2, f.x), mix(rand3, rand4, f.x), f.y);
				p.xy	=p *(1.0+sin(p.yx*20.-noise*5.)*0.02);
				vec3 Br = vec3(1.0,1.0+sin(p.x)*0.2,1.0+sin(p.x)*0.4);
				a = vec3(p.y) + sin(p.x*(i*0.5)+iGlobalTime*2.+sin(iGlobalTime*(0.001 + i*0.0001*Br))*5.0+noise*Br)*0.005*i-0.05*sin(iGlobalTime+i*0.2);
		
				color += sin(max(vec3(0.0),pow(1.0-abs(a),vec3(300.)*Br)*0.2+pow(1.0-abs(a),vec3(30.)*Br)*0.25));
		
		
				if(a.x < 0.0){
					color += vec3(0.6-i*0.1,-1.5+i*0.2,0.5+i*0.05)*(0.4-pow(a.x,5.)*5.)*0.12*Br;
		
				}
			}

			gl_FragColor = vec4( color, 1.0 );
		}
	}
}
