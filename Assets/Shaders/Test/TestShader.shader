Shader "Custom/TestShader"
{
	Properties
	{
		[Header(Noise Params)] _CellDensity("Cell Density", Range(0.01, 0.5)) = 0.25
		_Strength("Displacement Strength", Range(0.0, 2.0)) = 1.0

		[Header(Color Params)]_Color("Main Color", Color) = (1, 1, 1, 1)
		_BorderColor("Border Color", Color) = (0, 0, 0, 1)

		[Header(Lighting Params)]_SpecularColor("Specular Color", Color) = (1, 1, 1, 1)
		_SpecularPower("Specular Power", Range(0.0, 2.0)) = 0.5
		_SpecularGloss("Specular Gloss", Range(0.0, 2.0)) = 0.5

		[Header(Misc)]_WorldSpaceCameraPos("Camera Position", Vector) = (0, 0, 0, 0)
	}

	SubShader 
	{
		
		Pass {
			Tags { "RenderType" = "Opaque" "Queue" = "Geometry" "LightMode" = "ForwardBase"}
			CGPROGRAM
			
			#define M_PI 3.1415926535897932384626433832795

			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			//#include "UnityLightingCommon.cginc"
			#include "Utils.cginc"
				
			#pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap
			#include "AutoLight.cginc"

			// Base noise on world position (noise will change if object moves)
			//#define USE_WORLDPOS;

			float _CellDensity;
			float _Strength;
			
			float4 _Color;
			float3 _BorderColor;

			float4 _SpecularColor;
			float _SpecularPower;
			float _SpecularGloss;

			struct v2f {
				float4 pos : SV_POSITION;
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
				#ifdef USE_WORLDPOS
					float3 noise = voronoiNoise(o.worldPos / _CellDensity);
				#else
					float3 noise = voronoiNoise(o.localPos / _CellDensity);
				#endif
				
				v.vertex.xyz += (v.normal.xyz * noise.z) * _Strength;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex);
				return o;
			}

			float4 frag(v2f i) : SV_Target{

								
				#ifdef USE_WORLDPOS
					float3 noise = voronoiNoise(i.pos / _CellDensity);
				#else
					float3 noise = voronoiNoise(i.localPos / _CellDensity);
				#endif

				//float3 cellColor = rand1dTo3d(noise.y);
				//float valueChange = fwidth(noise.z) * 0.5;
				//float isBorder = 1 - smoothstep(0.05 - valueChange, 0.05 + valueChange, noise.z);
				//float3 col = lerp(_Color, _BorderColor, 0.5);

				float3 col = _Color.rgb;

				// Lighting
				float3 normal = normalize(cross(ddx(i.worldPos), ddy(i.worldPos)));
				normal.y *= -1;
				float NdotL = max(0.0, dot(normal, _WorldSpaceLightPos0));
				// Lambertian diffuse lighting
				float3 LambertDiffuse = NdotL * col;
				// Half lambertian diffuse lighting
				float3 HalfLambertDiffuse = pow(NdotL * 0.5 + 0.5, 2.0) * col;

				// Phong lighting
				float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
				float3 lightReflectionDirection = reflect(_WorldSpaceLightPos0, normal);
				float RdotV = max(0.0, dot(lightReflectionDirection, viewDir));

				float3 specularity = pow(RdotV, _SpecularGloss / 4) * _SpecularPower * _SpecularColor.rgb;
				float3 lightingModel = NdotL * HalfLambertDiffuse * specularity;

				float attenuation = LIGHT_ATTENUATION(i);
				float3 attenColor = attenuation * _LightColor0.rgb;
				float3 finalColor = lightingModel * attenColor;

				//col.rgb *= lighting * noise.z * (normal * 0.5 + 0.5) * 5;
				//return float4(normal, 1.0);
				return float4(finalColor, 1.0);
				//return float4(color, 1.0);

				//return float4(noise.zzz	, 1.0);
				//return float4(cellColor, 1.0);
				//col.rgb = cellColor;
			}

			ENDCG
		}
	}
	FallBack "Standard"
}