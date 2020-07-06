Shader "Custom/Crystal"
{
    Properties
    {
        _CellDensity ("Cell Density", Range (2.0, 5.0)) = 1.5
        _Strength("Displacement Strength", Range (0.0, 2.0)) = 1.0
        _Jitter("Jitter", Range(0.0, 1.5)) = 1.0
        _Color("Lower colour", Color) = (1, 0, 0, 1)
        _Transparency("Transparency", Range(0.0, 0.03)) = 0.0
    }
    SubShader
    {
        Tags {"Queue" = "Transparent" "RenderType" = "Transparent"}

        
        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            //#include "Noise2D.cginc"
            #include "Noise3D.cginc"

            // Editor variables
            float _CellDensity;
            float _Strength;
            fixed4 _Color;
            fixed4 _Color2;
            float _Transparency;
            float _Jitter;
            float _minDist;

            // Stuff that vertex passes to fragment
            struct v2f {
                float4 vertex : SV_POSITION;
                float2 texcoord : TEXCOORD0;
                float4 object_vertex : TEXCOORD1;   // Saved object space position of vertex, used in frag
                fixed4 color : COLOR0;
            };



            v2f vert(appdata_full v)
            {                
                v2f o;
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                o.object_vertex.xyz = v.vertex.xyz * _CellDensity;  // Pass this before we start messing with the actual vertices
                o.texcoord.xy = v.texcoord.xy * _CellDensity;
                o.vertex.xyz = v.vertex.xyz * _CellDensity;

                // Displacement stuff
                float2 F = cellular(v.vertex.xyz * _CellDensity, _Jitter);
                float noise = (F.y - F.x);
                v.vertex.xyz += (v.normal.xyz * noise) * _Strength;
                
                o.vertex = UnityObjectToClipPos(v.vertex);
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                // 2D NOISE
                //float2 F = cellular(i.texcoord.xy);
                //float facets = 0.1+(F.y-F.x);
                //float dots = smoothstep(0.05, 0.1, F.x);
                //float n = facets * dots;
                //return fixed4(facets,facets,facets,1.0);

                // 3D NOISE
                float2 F = cellular(i.object_vertex.xyz, _Jitter);
                float n = saturate(F.y-F.x);

                fixed4 color = _Color * n;
                color.a = 1.0 - smoothstep(0.0,0.05,_Transparency * n);
                return color;
            }

            ENDCG
        }
    }
}
