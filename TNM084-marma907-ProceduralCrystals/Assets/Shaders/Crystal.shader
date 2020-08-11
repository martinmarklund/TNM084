Shader "Custom/Crystal"
{
	Properties
	{
		[Header(Noise Params)] _CellDensity("Cell Density", Range(0.01, 0.5)) = 0.25
		_Strength("Displacement Strength", Range(0.0, 2.0)) = 1.0

		[Header(Color Params)]_Color("Main Color", Color) = (1, 1, 1, 1)
		_BaseColor("Base Color", Color) = (0, 0, 0, 1)
		_BorderSize("Colour Blend", Range(0.0, 1)) = .1
		[Header(Lighting Params)]_SpecularColor("Specular Color", Color) = (1, 1, 1, 1)
		_SpecularPower("Specular Power", Range(0.0001, 10)) = 0.5
		_Translucency("Translucency", Range(0.0, 1)) = .7
		_Transparency("Transparency", Range(0.0, 1)) = .5

		[Header(Misc)]_WorldSpaceCameraPos("Camera Position", Vector) = (0, 0, 0, 0)
	}

	SubShader 
	{
		
		Pass {
			Tags { "RenderType" = "Transparent" "Queue" = "Transparent" "LightMode" = "ForwardBase"}
			Blend SrcAlpha OneMinusSrcAlpha
			ZWrite off
			CGPROGRAM
			
			#define M_PI 3.1415926535897932384626433832795

			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "Utils.cginc"
				
			#pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap
			#include "AutoLight.cginc"
			
			float _CellDensity;
			float _Strength;
			float _BorderSize;

			float4 _Color;
			float3 _BaseColor;

			float4 _SpecularColor;
			float _SpecularPower;
			float _SpecularGloss;

			float _Translucency;
			float _Transparency;

			struct v2f {
				float4 vertex : SV_POSITION;
				float3 worldPos : TEXCOORD0;
				float3 localPos : TEXCOORD1;
				SHADOW_COORDS(2)
			};

			float PhaseFunction(float costh, float g) {
				g = min(g, 0.9381);

				float k = 1.55 * g - 0.55 * g * g * g;

				float kcosth = k * costh;

				return (1 - k * k) / ((4 * M_PI) * (1 - kcosth) * (1 - kcosth));
			}

			v2f vert(appdata_full v) {
				v2f o;
				UNITY_INITIALIZE_OUTPUT(v2f, o);

				o.localPos = v.vertex.xyz;

				// Displacement stuff
				float3 noise = voronoiNoise(o.localPos / _CellDensity);
				v.vertex.xyz += (v.normal.xyz * noise.z) * _Strength;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex);
				return o;
			}

			float4 frag(v2f i) : SV_Target{

				// Lighting parameters ( Light0 = First main direction light in scene)
				float3 cameraPos = _WorldSpaceCameraPos;
				float3 lightDir = _WorldSpaceLightPos0;	
				float3 lightColor = _LightColor0;

				// Noise patterns
				float3 noise = voronoiNoise(i.localPos / _CellDensity);

				float3 cellColor = rand1dTo3d(noise.y);
				float valueChange = length(fwidth(noise.z)) * 0.5;
				float isBorder = 1 - smoothstep(0.05 - valueChange, 0.05 + valueChange, noise.z);
				
				// Comment one out:
				float3 col = lerp(_BaseColor, _Color.rgb, _BorderSize);		// Use user specified colours
				//float3 col = lerp(_BaseColor, cellColor, _BorderSize);	// Use Voronoi noise colours
				
				float3 albedo = col;
				
				// Lighting
				float3 normal = -normalize(cross(ddx(i.worldPos), ddy(i.worldPos)));

				// Lambertian diffuse lighting
				float NdotL = max(0.0, dot(normal, lightDir));
				float3 lambertDiffuse = albedo * (NdotL * lightColor + unity_AmbientSky);

				// Phong specular
				float3 viewDir = normalize(i.worldPos - cameraPos);
				float3 reflDir = reflect(lightDir, normal);

				float RdotV = max(0.0, dot(reflDir, viewDir));
				float3 halfwayDir = normalize(lightDir + viewDir);
				float w = pow(1.0 - max(0.0, dot(halfwayDir, viewDir)), 5.0);

				//float3 specular = pow(RdotV, _SpecularPower) * _SpecularColor.rgb *lightColor;
				//float3 specular = lightColor * lerp(col, float3(1.0, 1.0, 1.0), w) * pow(RdotV, _SpecularPower);
				float3 specular = lightColor * lerp(_SpecularColor.rgb, float3(1.0, 1.0, 1.0), w) * pow(RdotV, _SpecularPower);
				
				// Subsurface scattering
				float g = _Translucency;
				float translucency = noise.z;

				float costh = dot(viewDir, lightDir);
				float sss = PhaseFunction(costh, g) * translucency;

				float4 color = float4(lambertDiffuse + specular + (sss * albedo), 1 - (noise.z * _Transparency));
				return color;
				
				
				// For DEBUG purposes
				//return float4(noise.zzz, 1.0);	// Show distance values
				//return float4(normal.yyy, 1.0);		// Show normals (use .xxx, .yyy or .zzz to show specific normal direction)

			}

			ENDCG
		}
	}
	FallBack "Standard"
}