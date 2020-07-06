Shader "Custom/3DVoronoi"
{
    Properties
    {
        _CellSize("Cell Size", Range(0,2)) = 2
        _BorderColor("Border Color", Color) = (0, 0, 0, 1)
    }

    SubShader
    {
        Tags{ "RenderType" = "Opaque" "Queue" = "Geometry"}

        Pass
        {


        CGPROGRAM

        #pragma vertex vert 
        #pragma fragment frag
        #pragma target 3.0

        #include "UnityCG.cginc"
        #include "3DVoronoi.cginc"

        float _CellSize;
        float3 _BorderColor;

        struct v2f {
            float4 vertex : SV_POSITION;
            float2 texcoord : TEXCOORD0;
            float4 object_vertex : TEXCOORD1;
            fixed4 color : COLOR0;
        };

        v2f vert(appdata_full v) {
            v2f o;
            UNITY_INITIALIZE_OUTPUT(v2f, o);
            o.object_vertex.xyz = v.vertex.xyz * _CellSize;
            o.texcoord.xy = v.texcoord.xy * _CellSize;
            o.vertex.xyz = v.vertex.xyz * _CellSize;


            return o;
        }

        fixed4 frag(v2f i) : SV_Target
        {
            float3 value = i.vertex.xyz / _CellSize;
            float3 noise = voronoiNoise(value);

            float3 cellColor =  rand1dTo3d(noise.y);
            float valueChange = fwidth(value.z) * 0.5;
            float isBorder = 1 - smoothstep(0.05 - valueChange, 0.05 + valueChange, noise.z);
            float3 color = lerp(cellColor, _BorderColor, isBorder);

            fixed4 o = _BorderColor;

            return o;
        }
        ENDCG

        } 
    }
    
        FallBack "Standard"
}