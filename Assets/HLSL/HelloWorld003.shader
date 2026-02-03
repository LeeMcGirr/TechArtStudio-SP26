Shader"Custom/HelloWorldShader003"
{
    Properties {
        _Color ("Color", Color ) = (1, 1, 1, 1)
        [MainTexture] _BaseMap ("BaseMap", 2D) = "white" {}
    }

    SubShader // Subshaders run on different platforms or in different situations based on tags
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalRenderPipeline" }

        Pass //passes run at different stages in the render pipeline, also depending on tags
        {
            Tags {"LightMode"="UniversalForward"}

            HLSLPROGRAM //open our HLSL block and reference our #pragmas
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            CBUFFER_START(UnityPerMaterial)
            half4 _Color;
            sampler2D _BaseMap;
            float4 _BaseMap_ST;
            CBUFFER_END

            struct appdata //delcare a struct to hold our raw mesh data
            {
                float4 posLocal : POSITION; //POSITION is a semantic that identifies an address
                float2 uv : TEXCOORD0; //semantics work kind of like Unity tags
            };

            struct vertex2fragment
            {
                // The position in this struct must have the SV_POSITION semantic.
                //it's clip space so there's no depth
                half4 posHClip : SV_Position; //SV is short for System value - defined semantics
                float2 uv : TEXCOORD1;
                half3 lightAmount : TEXCOORD2; //for storing how much light hits each pixel
                half3 normal : TEXCOORD0;
            };

            // The vertex shader definition with properties defined in the vertex2fragment struct
            vertex2fragment vert(appdata IN)
            {
                // Declaring the output object (OUT) with the vertex2fragment struct.
                vertex2fragment OUT;
                // The TransformObjectToHClip function transforms vertex positions
                // from object space to homogenous space
                //you can view all these helper functions at ShaderLibrary/SpaceTransforms.hlsl
                OUT.posHClip = TransformObjectToHClip(IN.posLocal.xyz);

                // Get the VertexNormalInputs of the vertex, which contains the normal in world space
                VertexNormalInputs positions = GetVertexNormalInputs(IN.posLocal);
                //get the main scene light
                Light light = GetMainLight();
                //calcuate the amount of light each frag pos should receive
                OUT.lightAmount = LightingLambert(light.color, light.direction, positions.normalWS.xyz);

                //map our base tex to the UVs
                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
                return OUT;
            }

            // The fragment shader definition.            
            half4 frag(vertex2fragment IN) : SV_Target
            {
                float2 uv = IN.uv;
                half4 color = tex2D(_BaseMap, IN.uv)*_Color;
                float4 lit = float4(IN.lightAmount,1);
                return  color*lit;

            }
            ENDHLSL
        }


        // shadow caster rendering pass, implemented manually
        // using macros from UnityCG.cginc
        Pass {
            // The shadow caster pass, which draws to shadow maps
            Name"ShadowCaster"
            Tags {"LightMode" = "ShadowCaster"}
            ColorMask 0 // No color output, only depth

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct appData
            {
                float4 vertex : POSITION;
                float4 normal : NORMAL;
            };

            struct v2f
            {
                float4 posHClip : SV_POSITION;
 
            };

            float3 _LightDirection; //Unity sets this based off the light rendering this shadow pass

            float4 GetShadowCasterPositionHClip(float3 positionWS, float3 normalWS)
            {
                float3 lightDirectionWS = _LightDirection;
                float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, lightDirectionWS));
    
                #if UNITY_REVERSED_Z
	            positionCS.z = min(positionCS.z, UNITY_NEAR_CLIP_VALUE);
                #else
                positionCS.z = max(positionCS.z, UNITY_NEAR_CLIP_VALUE);
                #endif
                return positionCS;
            }

            v2f vert(appData IN)
            {
                v2f OUT;
    
                VertexPositionInputs posnInputs = GetVertexPositionInputs(IN.vertex); // Found in URP/ShaderLib/ShaderVariablesFunctions.hlsl
                VertexNormalInputs normInputs = GetVertexNormalInputs(IN.normal); // Found in URP/ShaderLib/ShaderVariablesFunctions.hlsl

                OUT.posHClip = GetShadowCasterPositionHClip(posnInputs.positionWS, normInputs.normalWS);
                return OUT;
            }

            float4 frag(v2f IN) : SV_Target
            {
                return 0;
            }
            ENDHLSL
        }
    }
}