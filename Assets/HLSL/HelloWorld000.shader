Shader"Custom/HelloWorldShader000"
{
    Properties {
        _Color ("Color", Color ) = (1, 1, 1, 1)
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

            CBUFFER_START(UnityPerMaterial)
            half4 _Color;
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
                return OUT;
            }

            // The fragment shader definition.            
            half4 frag(vertex2fragment IN) : SV_Target
            {
               return  _Color;
            }
            ENDHLSL
        }
    }
}



