Shader"Custom/HelloWorldShader"
{
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
	}

	SubShader // Subshaders run on different platforms usually, or for different render pipelines
	{ //a subshader could be exlcusive to the nintendo switch, to BIRP, to URP, it depends
		Tags {"RenderType" = "Opaque" "RenderPipeline" = "UniversalRenderPipeline"}


		Pass //passes run at different steps of the render pipeline process 
		{ //for example, we could have one object with an opaque pass and a shadow caster pass
			Tags {"LightMode"="UniversalForward"}

			//inside a pass is where our HLSL code will go (HLSL is Microsoft's high level Shader lang)
			//it's like GLSL but for DirectX
			HLSLPROGRAM //start of our shader langauge block
			#pragma vertex vert
			#pragma fragment frag
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

			CBUFFER_START(UnityPerMaterial)
			half4 _Color;
			CBUFFER_END

			//appdata is essentially the original and static mesh info from the 3D file (like a .obj or .fbx)
			struct appdata //this struct will hold all the raw 3d MESH data from unity
			{
				float4 posLocal : POSITION; //POSITION is going to be the address we store the mesh vertex pos data info
				float2 uv : TEXCOORD0; //let's also store our UV coordinates in case we decide to texture map our object
			};

			//this struct is going to be the inbetween placeholder for us to translate our mesh data into the final fragment shader
			struct vertex2fragment //this struct will hold our mesh data translated into clip space or screenspace
			{
				half4 posHClip : SV_Position; //SV is short for system-value, SV_Position is a required HLSL semantic
				float2 normal : TEXCOORD0;
			};

			//vertex shader definition, this will have the properties declared in our vertex2fragment struct
			vertex2fragment vert(appdata IN)
			{
				//delcare there is an output out
				vertex2fragment OUT;
				//use a function TransformObjectToHClip() to translate our mesh data from appdata into screenspace
				OUT.posHClip = TransformObjectToHClip(IN.posLocal.xyz);
				return OUT;
			}



			//the fragment shader definition
			//fragment shader [frag] (of data type half4) is going to be saved at the named address SV_Target
			half4 frag(vertex2fragment IN) : SV_Target
			{
				return _Color;
			}


			ENDHLSL
		
		}

		Pass //this second pass will eventually be for the shadow caster
		{

		}

	}



}
