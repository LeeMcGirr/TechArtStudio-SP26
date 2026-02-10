Shader "Custom/DepthReader"
{
    Properties
    {
        _Scale ("Scale", Int) = 10
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            //for sampling camera depth
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            //core HLSL code refs
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

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

            CBUFFER_START(UnityPerMaterial)
            int _Scale;
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {

                float2 UV = IN.positionHCS.xy / _ScaledScreenParams.xy;
                
                //check z direction based on target platform ---------------------------------------------------
                #if UNITY_REVERSED_Z
                real depth = SampleSceneDepth(UV);
                #else
                // Adjust z to match NDC for OpenGL
                real depth = lerp(UNITY_NEAR_CLIP_VALUE, 1, SampleSceneDepth(UV));
                #endif
                // ------------------------------------------------------------------------------------------------

                float3 worldPos = ComputeWorldSpacePosition(UV, depth, UNITY_MATRIX_I_VP);

                uint3 worldIntPos = uint3(abs(worldPos.xyz * _Scale)); //convert world pos to whole numbers
                bool white = (worldIntPos.x & 1) ^ (worldIntPos.y & 1) ^ (worldIntPos.z & 1); //if world pos is odd or even check

                half4 color = white ? half4(1,1,1,1) : half4(0,0,0,1);

                depth *= 10;
                //color = half4(worldPos*_Scale,1);
                //color = half4(depth,depth,depth,1);
                color *= depth;



                // Set the color to black in the proximity to the far clipping plane--------------------
                    #if UNITY_REVERSED_Z
                    // Case for platforms with REVERSED_Z, such as D3D 
                    if(depth < 0.0001)
                        return half4(0,1,0,1);
                    #else
                    // Case for platforms without REVERSED_Z, such as OpenGL
                    if (depth > 0.9999)
                    return half4(0, 1, 0, 1);
                    #endif
                //---------------------------------------------------------------------------------------

                return color;
            }
            ENDHLSL
        }
    }
}
