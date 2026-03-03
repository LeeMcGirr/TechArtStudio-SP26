Shader "Custom/simpleRaymarch"
{
    Properties
    {
        [Color] _Color("Base Color", Color) = (1, 1, 1, 1)
        _Radius("Radius", Range(0,10)) = .5
        _Steps("Steps", Range(1,128)) = 64
		_StepSize("Step Size", Range(0.01,0.5)) = 0.05
    }

    SubShader
    {
        Tags 
        { 
            "RenderType" = "Opaque" 
            "RenderPipeline" = "UniversalPipeline" 
            "UniversalMaterialType" = "Lit"
        }
        Cull Back

        HLSLINCLUDE //moving the CBUFFER here with the core library enables batching 
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float3 _Center;
                half4 _Color;
                float _Radius;
                float _Steps;
                float _StepSize;
            CBUFFER_END

        ENDHLSL

        Pass
        {
            Name "ForwardLit"
            HLSLPROGRAM
            #pragma target 2.0
            #pragma vertex vert
            #pragma fragment frag

            struct Attributes
            {
                float4 positionOS : POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID //instance_ID is needed for batching as well
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 positionWS   : TEXCOORD1;
                float3 cPos : TEXCOORD2;	// Object center in world space
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            static float RemapFloat(float value, float from1, float to1, float from2, float to2)
            {   return (value - from1) / (to1 - from1) * (to2 - from2) + from2; };

            bool sphereHit (float3 p)
            {
                return distance(p,_Center) < _Radius;
            }

            bool raymarchHit (float3 position, float3 direction)
            {
                for (int i = 0; i<_Steps; i++)
                {
                    if ( sphereHit(position) )
                        return true;

                    position += direction * _StepSize;
                }
                return false;
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
                OUT.cPos = mul(unity_ObjectToWorld, half4(0, 0, 0, 1));	// Object center in world space

                return OUT;
            }

            half4 frag(Varyings IN, bool facing : SV_IsFrontFace) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(IN);

                //center of object
                _Center = IN.cPos;
                //worldspace position
                float3 worldPos = IN.positionWS;
                // view direction
                float3 viewDir = normalize(IN.positionWS - _WorldSpaceCameraPos);

                //sample the color and check against raymarchHit
                half4 color = _Color;
                //IF raymarchHits then render color, otherwise render white
                color = (raymarchHit(worldPos,viewDir)) ? color : half4(1,1,1,0);
                clip(color.w - 0.01);

                return color;
            }
            ENDHLSL
        }
    }
}
