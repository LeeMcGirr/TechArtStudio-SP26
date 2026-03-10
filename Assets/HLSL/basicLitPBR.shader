Shader "Custom/basicLitPBR"
{
    Properties
    {
        [Color] _Color("Base Color", Color) = (1, 1, 1, 1)
        [MainTexture] _BaseMap("Base Map", 2D) = "white" {}
        [Smoothness] _Glossiness ("Smoothness", Range(0,1)) = 0.5
        [Metallic] _Metallic ("Metallic", Range(0,1)) = 0.0
        [Emission] _Emission ("Emission", Range(0,1)) = 0.0
        [Occlusion] _Occlusion ("Occlusion", Range(0,1)) = 0.0
        [BaseAlpha] _Alpha("Base Alpha", Range(0,1)) = 1


    }

    SubShader
    {
        Tags 
        { 
            "RenderType" = "Opaque" 
            "RenderPipeline" = "UniversalPipeline" 
            "UniversalMaterialType" = "Lit"
        }
        Cull Off

        HLSLINCLUDE //moving the CBUFFER here with the core library enables batching 
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
                half4 _Color;
                float4 _BaseMap_ST;
                float4 _DitherMap_ST;
                float4 _AlphaMap_ST;
                float _Metallic;
                float _Glossiness;
                float _Emission;
                float _Occlusion;
                float _Alpha;
                SamplerState my_point_clamp_sampler;
                half4 _BaseMap_TexelSize;
            CBUFFER_END

        ENDHLSL


        Pass
        {
            Name "ForwardLit"
            HLSLPROGRAM
            #pragma target 2.0
            #pragma vertex vert
            #pragma fragment frag

            // -------------------------------------
            // Universal Render Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile_fragment _ _SHADOWS_SOFT _SHADOWS_SOFT_LOW _SHADOWS_SOFT_MEDIUM _SHADOWS_SOFT_HIGH
            #pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
            #pragma multi_compile_fog

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma instancing_options renderinglayer
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
            // -------------------------------------

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID //instance_ID is needed for batching as well
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 positionWS   : TEXCOORD1;
                float4 screenPos : TEXCOORD2; 
                half3 normal : TEXCOORD3;
                half3 normalWS : TEXCOORD4;
                half3 normalTS : TEXCOORD5;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            static float RemapFloat(float value, float from1, float to1, float from2, float to2)
            {   return (value - from1) / (to1 - from1) * (to2 - from2) + from2; };

            void ApplyFog(inout float4 color, float3 positionWS)
            {
                float4 inColor = color;
  
                #if defined(FOG_LINEAR) || defined(FOG_EXP) || defined(FOG_EXP2)
                float viewZ = -TransformWorldToView(positionWS).z;
                float nearZ0ToFarZ = max(viewZ - _ProjectionParams.y, 0);
                float density = 1.0f - ComputeFogIntensity(ComputeFogFactorZ0ToFar(nearZ0ToFarZ));

                color = lerp(color, unity_FogColor,  density);

                #else
                color = color;
                #endif
            }

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            Varyings vert(Attributes IN)
            {
                Varyings OUT;

                UNITY_SETUP_INSTANCE_ID(IN); //be sure to transfer instanceID across each step
                UNITY_TRANSFER_INSTANCE_ID(IN, OUT);

                VertexPositionInputs positionInputs = GetVertexPositionInputs(IN.positionOS.xyz);
                OUT.positionHCS = positionInputs.positionCS;
                OUT.positionWS = positionInputs.positionWS;
                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
                VertexNormalInputs positions = GetVertexNormalInputs(IN.positionOS);
                OUT.normalWS = positions.normalWS;
                OUT.normalTS = positions.tangentWS;

                return OUT;
            }

            half4 frag(Varyings IN, bool facing : SV_IsFrontFace) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(IN);

                InputData lightingInput = (InputData)0;
                lightingInput.positionWS = IN.positionWS;
                lightingInput.normalWS = IN.normalWS;
                lightingInput.viewDirectionWS = GetWorldSpaceNormalizeViewDir(IN.positionWS);
                lightingInput.shadowCoord =  TransformWorldToShadowCoord(IN.positionWS);

                //sample the color and baseTex
                half4 color = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv) * _Color;

                SurfaceData surfaceInput = (SurfaceData)0;
                surfaceInput.albedo = color.rgb;
                surfaceInput.specular = 1;
                surfaceInput.metallic = _Metallic;
                surfaceInput.smoothness = _Glossiness;
                surfaceInput.normalTS = IN.normalTS;
                surfaceInput.emission = _Emission;
                surfaceInput.occlusion = _Occlusion;
                surfaceInput.alpha = color.a;
                //surfaceInput.clearCoatMask = _CCmask; //UNUSED
                //surfaceInput.clearCoatSmoothness = _ClearCoat; //UNUSED

                color = UniversalFragmentPBR(lightingInput, surfaceInput);
                ApplyFog(color, IN.positionWS);            
                return color;
            }
            ENDHLSL
        }

        // --------------------------------------- SHADOW CASTER PASS PULLED FROM ShadowCasterPass.hlsl IN LIBRARY ---------------
        // -------------------------------- MUST BE REDEFINED HERE TO USE basicLitPBR CBUFFER and stay batchable --------------------
        Pass
        {
            Name "ShadowCaster"
            Tags
            {
                "LightMode" = "ShadowCaster"
            }
            // -------------------------------------
            // Render State Commands
            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull[_Cull]

            HLSLPROGRAM
            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

            // Shadow Casting Light geometric parameters. These variables are used when applying the shadow Normal Bias and are set by UnityEngine.Rendering.Universal.ShadowUtils.SetupShadowCasterConstantBuffer in com.unity.render-pipelines.universal/Runtime/ShadowUtils.cs
            // For Directional lights, _LightDirection is used when applying shadow Normal Bias.
            // For Spot lights and Point lights, _LightPosition is used to compute the actual light direction because it is different at each shadow caster geometry vertex.
            float3 _LightDirection;
            float3 _LightPosition;

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
                float2 texcoord     : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                #if defined(_ALPHATEST_ON)
                    float2 uv       : TEXCOORD0;
                #endif
                float4 positionCS   : SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            float4 GetShadowPositionHClip(Attributes input)
            {
                float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
                float3 normalWS = TransformObjectToWorldNormal(input.normalOS);

                #if _CASTING_PUNCTUAL_LIGHT_SHADOW
                    float3 lightDirectionWS = normalize(_LightPosition - positionWS);
                #else
                    float3 lightDirectionWS = _LightDirection;
                #endif

                float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, lightDirectionWS));
                positionCS = ApplyShadowClamping(positionCS);
                return positionCS;
            }

            Varyings ShadowPassVertex(Attributes input)
            {
                Varyings output;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);

                #if defined(_ALPHATEST_ON)
                output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);
                #endif

                output.positionCS = GetShadowPositionHClip(input);
                return output;
            }

            half4 ShadowPassFragment(Varyings input) : SV_TARGET
            {
                UNITY_SETUP_INSTANCE_ID(input);

                #if defined(_ALPHATEST_ON)
                    Alpha(SampleAlbedoAlpha(input.uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap)).a, _BaseColor, _Cutoff);
                #endif

                #if defined(LOD_FADE_CROSSFADE)
                    LODFadeCrossFade(input.positionCS);
                #endif

                return 0;
            }
            ENDHLSL
        }
        // ----------------------------------------------------------- END SHADOWCASTERPASS ---------------------------------------
        // ------------------------------------------------------------------------------------------------------------------
    }
}
