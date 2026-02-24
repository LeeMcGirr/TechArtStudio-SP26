Shader "Custom/simpleQuantize"
{
    Properties
    {
        [MainColor] _BaseColor("Base Color", Color) = (1, 1, 1, 1)
        [MainTexture] _BaseMap("Base Map", 2D) = "white" {}
        [Pixelize] _Pixelize("Pixelize", Range(1,50)) = 1
        [Toggle] _ScreenSpace("ScreenSpace", Range(0,1)) = 0
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        CBUFFER_START(UnityPerMaterial)
            half4 _BaseColor;
            float4 _BaseMap_ST;
            float4 _BaseMap_TexelSize;
            float _Pixelize;
        CBUFFER_END
        ENDHLSL

        Pass
        {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                float aspect = _BaseMap_TexelSize.z / _BaseMap_TexelSize.w;
                float dx = floor(_Pixelize)*(_BaseMap_TexelSize.x)*aspect;
                float dy = floor(_Pixelize)*(_BaseMap_TexelSize.y);
                float2 pixelUV = float2(dx*floor(IN.uv.x/dx),dy*floor(IN.uv.y/dy));
                
                half4 color = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, pixelUV) * _BaseColor;                
                
                
                return color;
            }
            ENDHLSL
        }
    }
}
