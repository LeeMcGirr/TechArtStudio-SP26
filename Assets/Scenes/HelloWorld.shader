Shader"Custom/HelloWorldShader"
{
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		[MainTexture] _BaseMap ("BaseMap", 2D) = "white" {} 
	}

	SubShader // Subshaders run on different platforms usually, or for different render pipelines
	{ //a subshader could be exlcusive to the nintendo switch, to BIRP, to URP, it depends
		Tags {"RenderType" = "Opaque" "RenderPipeline" = "UniversalRenderPipeline"}


		//------------------------- THIS IS THE OPAQUE LIT PASS -----------------------------------------------------------------------------------------------------------
		Pass //passes run at different steps of the render pipeline process 
		{ //for example, we could have one object with an opaque pass and a shadow caster pass
			Tags {"LightMode"="UniversalForward"}

			//inside a pass is where our HLSL code will go (HLSL is Microsoft's high level Shader lang)
			//it's like GLSL but for DirectX
			HLSLPROGRAM //start of our shader langauge block
			#pragma vertex vert
			#pragma fragment frag
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

			CBUFFER_START(UnityPerMaterial)
			half4 _Color;
			sampler2D _BaseMap;
			float4 _BaseMap_ST;
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
				half3 normal : TEXCOORD0;
				float2 uv : TEXCOORD1;
				half3 lightAmount : TEXCOORD2;
			};

			//vertex shader definition, this will have the properties declared in our vertex2fragment struct
			vertex2fragment vert(appdata IN)
			{
				//delcare there is an output out
				vertex2fragment OUT;

				//use a function TransformObjectToHClip() to translate our mesh data from appdata into screenspace
				OUT.posHClip = TransformObjectToHClip(IN.posLocal.xyz);

				//to start with we need our mesh data not our clipspace
				VertexNormalInputs positions = GetVertexNormalInputs(IN.posLocal);

				//find the main scene light (directional light)
				Light light = GetMainLight();
				//output the amount of light based on the worldspace normals of the mesh at a given pixel position
				OUT.lightAmount = LightingLambert(light.color, light.direction, positions.normalWS.xyz);

				OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
				return OUT;
			}



			//the fragment shader definition
			//fragment shader [frag] (of data type half4) is going to be saved at the named address SV_Target
			half4 frag(vertex2fragment IN) : SV_Target
			{
				float uv = IN.uv;
				half4 color = tex2D(_BaseMap, IN.uv)*_Color;
				float4 lit = float4(IN.lightAmount,1);
				return color*lit;
			}


			ENDHLSL
		
		}
		// --------------------------------------------------------- END OF OPAQUE LIT PASS -----------------------------------------------------------
		
		//----------------SHADOW CASTER PASS --------------------------------------------------------------------------------------
		Pass //this second pass will eventually be for the shadow caster
		{
			//this is the shadowcaster PASS
			//you can define pass settings up here
			Name"ShadowCaster"
			Tags {"LightMode" = "ShadowCaster"}
			ColorMask 0 //no color only depth

			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

			//mainly just need the vertex pos of the mesh so we can cast shadows FROM it based on the MAIN LIGHT
			struct appdata
			{
				float4 vertex: POSITION;
				float4 normal: NORMAL;
			};

			//again, only need the clipSpace pos - not doing anything with texture channels in the shadow caster pass
			struct v2f
			{
				float4 posHClip : SV_Position;
			};

			float3 _LightDirection; //this is set by Unity based off the main light that the shadowcaster pass specifies

			//custom function for calculating a CAST shadow in SCREENSPACE 
			float4 GetShadowCasterPositionHClip(float3 positionWS, float3 normalWS)
			{
				//start with the WORLD DIR of the light
				float3 lightDirectionWS = _LightDirection;

				//translate into clip space with the ApplyShadowBias() function
				float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, lightDirectionWS));

				return positionCS;
			}

			v2f vert(appdata IN)
			{
				v2f OUT;

				//grabbing the normal and worlspace pos info of a given pixel (that is IN SHADE)
				VertexPositionInputs posnInputs = GetVertexPositionInputs(IN.vertex);
				VertexNormalInputs normInputs = GetVertexNormalInputs(IN.normal);

				//return the cast shadow in clip space
				OUT.posHClip = GetShadowCasterPositionHClip(posnInputs.positionWS, normInputs.normalWS);
				return OUT;
			}

			//because this is a colorless mask, we can simply return the mask where it is true
			float4 frag(v2f IN) : SV_Target
			{
				return 0;
			}
			ENDHLSL
			//-----------------------------------------------END OF SHADOW CASTER PASS ------------------------------------------------------------


			// ---------------------- screen space AO pass 
			Pass{
				}
		}

	}



}
